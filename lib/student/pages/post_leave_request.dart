import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../services/student_api_services.dart';

class PostLeaveRequest extends StatefulWidget {
  const PostLeaveRequest({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
  });

  final String username;
  final String schoolId;
  final String classId;

  @override
  State<PostLeaveRequest> createState() => _PostLeaveRequestState();
}

class _PostLeaveRequestState extends State<PostLeaveRequest> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String username = '';
  String name = '';
  String email = '';
  String mobile = '';
  String gender = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    _loadStaffData();

    // Rebuild button state when reason changes
    _reasonController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentApiServices.fetchStudentDataUsername(
        username: widget.username,
        schoolId: int.parse(widget.schoolId),
      );

      setState(() {
        username = widget.username;
        name = data?['name'] ?? '';
        email = data?['email'] ?? '';
        mobile = data?['mobile'] ?? '';
        gender = data?['gender'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load student data")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate constraints
    DateTime firstDateLimit = today;
    DateTime? initialDate = isFrom ? _fromDate : _toDate;

    if (!isFrom && _fromDate != null) {
      // To Date must be at or after From Date
      firstDateLimit = _fromDate!;
    }

    // Ensure initialDate is within bounds [firstDateLimit, 2100]
    if (initialDate == null || initialDate.isBefore(firstDateLimit)) {
      initialDate = firstDateLimit;
    }

    // Find first valid date that satisfies selectableDayPredicate
    while (initialDate?.weekday == DateTime.sunday) {
      initialDate = initialDate?.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDateLimit,
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime day) {
        // 1. Always disable Sundays
        if (day.weekday == DateTime.sunday) {
          return false;
        }

        // 2. Allow any valid date for to date picker (including same as from date)
        return true;
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          // Reset toDate if it's now invalid (before From Date, as same dates are now allowed)
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  // Helper method to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Button enabled only if all fields filled
  bool _isFormValid() {
    return !_isLoading &&
        _fromDate != null &&
        _toDate != null &&
        _reasonController.text.trim().isNotEmpty;
  }

  Future<void> _submitLeaveRequest() async {
    final today = DateTime.now();

    if (!_formKey.currentState!.validate() ||
        _fromDate == null ||
        _toDate == null ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select dates"),
        ),
      );
      return;
    }

    if (_fromDate!.isBefore(DateTime(today.year, today.month, today.day)) ||
        _toDate!.isBefore(DateTime(today.year, today.month, today.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dates cannot be in the past")),
      );
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("To Date cannot be before From Date")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await TeacherApiServices.createLeaveRequest(
        username: username,
        role: 'student',
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
        fromDate: _fromDate!,
        toDate: _toDate!,
        reason: _reasonController.text.trim(),
        email: email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Leave Request Created: ${response['message'] ?? 'Success'}",
          ),
        ),
      );

      setState(() {
        _fromDate = null;
        _toDate = null;
        _reasonController.clear();
        _formKey.currentState?.reset();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  schoolId: int.parse(widget.schoolId),
                  username: widget.username,
                  title: 'Apply Leave Request',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : StudentAppbarDesktop(
                  title: 'Apply Leave Request',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                ),
      ),
      body:
          _isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Staff Details Card
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFFF0F7FF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Student Details",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey.withValues(alpha: 0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow("Name", name, Icons.person),
                                  _buildDetailRow("Email", email, Icons.email),
                                  _buildDetailRow(
                                    "Mobile",
                                    mobile,
                                    Icons.phone,
                                  ),
                                  _buildDetailRow(
                                    "Gender",
                                    gender == 'M'
                                        ? 'Male'
                                        : gender == 'F'
                                        ? 'Female'
                                        : 'Others',
                                    Icons.people,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Leave Dates Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Leave Dates",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateCard(
                                    label: "From Date",
                                    date: _fromDate,
                                    dateFormat: dateFormat,
                                    onTap: () => _pickDate(context, true),
                                    icon: Icons.calendar_today_rounded,
                                    accentColor: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildDateCard(
                                    label: "To Date",
                                    date: _toDate,
                                    dateFormat: dateFormat,
                                    onTap: () => _pickDate(context, false),
                                    icon: Icons.event_available_rounded,
                                    accentColor: Colors.indigoAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reason Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            labelText: "Reason for Leave *",
                            hintText: "Briefly explain your reason",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            alignLabelWithHint: true,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: Colors.blue,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          maxLength: 250,
                          style: const TextStyle(fontSize: 16),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Reason is required";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: MouseRegion(
                          onEnter: (_) => setState(() => isHovering = true),
                          onExit: (_) => setState(() => isHovering = false),
                          // decoration: _isFormValid()
                          //   ? BoxDecoration(
                          //       borderRadius: BorderRadius.circular(18),
                          //       gradient: LinearGradient(
                          //         colors: [Colors.blue.shade600, Colors.blue.shade800],
                          //       ),
                          //       boxShadow: [
                          //         BoxShadow(
                          //           color: Colors.blue.withValues(alpha: 0.3),
                          //           blurRadius: 12,
                          //           offset: const Offset(0, 6),
                          //         ),
                          //       ],
                          //     )
                          //   : null,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: SpinKitFadingCircle(
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.send_rounded,
                                        size: 22,
                                      ),
                              label: Text(
                                _isLoading ? "Submitting..." : "Submit Request",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ).copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.disabled,
                                      )) {
                                        return Colors.grey.shade300;
                                      }
                                      return null; // Handled by BoxDecoration
                                    }),
                              ),
                              onPressed:
                                  _isFormValid() ? _submitLeaveRequest : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required VoidCallback onTap,
    required IconData icon,
    required Color accentColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    date != null
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    date != null
                        ? [Colors.white, accentColor.withValues(alpha: 0.08)]
                        : [Colors.grey.withValues(alpha: 0.03), Colors.white],
              ),
              boxShadow:
                  date != null
                      ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        date != null
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: date != null ? accentColor : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        date != null
                            ? accentColor.withValues(alpha: 0.8)
                            : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date == null ? "Select date" : dateFormat.format(date),
                  style: TextStyle(
                    fontSize: 15,
                    color: date != null ? Colors.black87 : Colors.grey.shade400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
