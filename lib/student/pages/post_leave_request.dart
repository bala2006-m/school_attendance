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
      debugPrint("Error loading student data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load student data")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
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
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Apply Leave Request',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 0;
                    Navigator.pushReplacement(
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
                : const StudentAppbarDesktop(title: 'Apply Leave Request'),
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
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blueAccent.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person, color: Colors.blueAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    "Student Details",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              _buildDetailRow("Name", name),
                              _buildDetailRow("Email", email),
                              _buildDetailRow("Mobile", mobile),
                              _buildDetailRow(
                                "Gender",
                                gender == 'M'
                                    ? 'Male'
                                    : gender == 'F'
                                    ? 'Female'
                                    : 'Others',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Leave Dates
                      Row(
                        children: const [
                          Icon(Icons.calendar_month, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            "Leave Dates",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateCard(
                              label: "From Date",
                              date: _fromDate,
                              dateFormat: dateFormat,
                              onTap: () => _pickDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateCard(
                              label: "To Date",
                              date: _toDate,
                              dateFormat: dateFormat,
                              onTap: () => _pickDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Reason Field (Required)
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: "Reason for Leave *",
                          hintText: "Briefly explain your reason",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        maxLines: 3,
                        maxLength: 250,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Reason is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: SpinKitFadingCircle(
                                      color: Colors.blueAccent,
                                      size: 60.0,
                                    ),
                                  )
                                  : const Icon(Icons.send),
                          label: Text(
                            _isLoading
                                ? "Submitting..."
                                : "Submit Leave Request",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isFormValid() ? _submitLeaveRequest : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
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
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null ? label : dateFormat.format(date),
                style: TextStyle(
                  color: date == null ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.blueAccent),
            ],
          ),
        ),
      ),
    );
  }
}
