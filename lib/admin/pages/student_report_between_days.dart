import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/appbar/admin_appbar_desktop.dart';
import 'package:school_attendance/admin/appbar/admin_appbar_mobile.dart';

import '../../services/api_service.dart';
import '../../teacher/services/teacher_api_service.dart';
import '../components/build_profile_card_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class StudentReportBetweenDays extends StatefulWidget {
  final String schoolId;
  final String username;

  const StudentReportBetweenDays({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentReportBetweenDays> createState() =>
      _StudentReportBetweenDaysState();
}

class _StudentReportBetweenDaysState extends State<StudentReportBetweenDays> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool showClasses = false;
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;

  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo(), fetchClasses()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchSchoolInfo() async {
    final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
    schoolName = schoolData[0]['name'];
    schoolAddress = schoolData[0]['address'];

    try {
      if (schoolData[0]['photo'] != null) {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        schoolPhoto = Image.memory(
          imageBytes,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Image decode error: $e');
    }
  }

  Future<void> fetchClasses() async {
    final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
    classes = List.from(cls);

    classes.sort((a, b) {
      int getClassValue(dynamic val) {
        const romanMap = {
          'I': 1,
          'II': 2,
          'III': 3,
          'IV': 4,
          'V': 5,
          'VI': 6,
          'VII': 7,
          'VIII': 8,
          'IX': 9,
          'X': 10,
          'XI': 11,
          'XII': 12,
          'XIII': 13,
        };

        if (val is int) return val;
        if (val is String) {
          final parsed = int.tryParse(val);
          if (parsed != null) return parsed;
          return romanMap[val] ?? 999;
        }
        return 999;
      }

      int classCompare = getClassValue(
        a['class'],
      ).compareTo(getClassValue(b['class']));
      if (classCompare != 0) return classCompare;

      return a['section'].toString().compareTo(b['section'].toString());
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _buildDatePicker(
    String label,
    DateTime selectedDate,
    bool isFromDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextButton(
          onPressed: () => _selectDate(context, isFromDate),
          child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Report Between Days',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                username: widget.username,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Report Between Days'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 50.0,
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      BuildProfileCard(
                        schoolPhoto: schoolPhoto,
                        schoolAddress: '$schoolAddress',
                        schoolName: '$schoolName',
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDatePicker('From', _fromDate, true),
                          _buildDatePicker('To', _toDate, false),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showClasses = true;
                          });
                        },
                        child: const Text('Generate Report'),
                      ),
                      const SizedBox(height: 16),
                      if (showClasses)
                        classes.isEmpty
                            ? const Text(
                              "No Classes Found",
                              style: TextStyle(fontSize: 16),
                            )
                            : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: classes.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.2,
                                  ),
                              itemBuilder: (context, index) {
                                final item = classes[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => Reports(
                                              className: item['class'],
                                              section: item['section'],
                                              classId: item['id'].toString(),
                                              schoolId: widget.schoolId,
                                              username: widget.username,
                                              from: _fromDate,
                                              to: _toDate,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${item['class']} Std",
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "${item['section']} Sec",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class Reports extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String username;
  final DateTime from;
  final DateTime to;
  final String className;
  final String section;
  const Reports({
    super.key,
    required this.schoolId,
    required this.username,
    required this.from,
    required this.to,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  bool isAttendanceLoading = false;
  Map<String, dynamic> attendanceData = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    students = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    // Fetch attendance in parallel
    final futures =
        students.map((student) async {
          final username = student['username'];
          final data = await AdminApiService.fetchStudentAttendanceBetweenDays(
            username: username,
            fromDate: widget.from,
            toDate: widget.to,
            schoolId: int.parse(widget.schoolId),
          );
          attendanceData[username] = data;
        }).toList();

    await Future.wait(futures);

    setState(() => isLoading = false);
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentReportBetweenDays(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  /// Reusable UI builder
  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student Report ',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StudentReportBetweenDays(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Student Report '),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 50.0,
                  ),
                )
                : students.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No Students Found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    const SizedBox(height: 5),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: Wrap(
                          // Wrap handles responsive layout automatically
                          alignment: WrapAlignment.center,
                          spacing: 30,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              'Class',
                              widget.className,
                              Colors.teal,
                            ),
                            _buildInfoChip(
                              'Section',
                              widget.section,
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    Container(
                      height: 80,
                      child: Column(
                        children: [
                          Text(
                            'Attendance Report Between Date',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            '${widget.from.day}-${widget.from.month}-${widget.from.year} and ${widget.to.day}-${widget.to.month}-${widget.to.year}',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final username = student['username'];
                          String name = student['name'] ?? 'Unnamed';
                          name =
                              name.length > 15
                                  ? '${name.substring(0, 15)}...'
                                  : name;
                          final data = attendanceData[username];

                          final totalMarking = data?['TotalMarking'] ?? 0;
                          final presentSessions =
                              ((data?['fnPresentDates']?.length ?? 0) +
                                  (data?['anPresentDates']?.length ?? 0));
                          final percentage =
                              data?['totalPercentage']?.toString() ?? '-';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            color:
                                student['gender'] == 'F'
                                    ? Colors.pink.shade50
                                    : Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        student['gender'] == 'F'
                                            ? Colors.pink.shade100
                                            : Colors.blue.shade100,
                                    child: Icon(
                                      student['gender'] == 'F'
                                          ? Icons.female
                                          : Icons.male,
                                      color:
                                          student['gender'] == 'F'
                                              ? Colors.pink.shade700
                                              : Colors.blue.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        username,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${presentSessions / 2} / $totalMarking",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "$percentage%",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isAttendanceLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.white,
                            size: 50.0,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
