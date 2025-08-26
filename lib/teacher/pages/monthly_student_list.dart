import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';

import '../services/teacher_api_service.dart';
import 'monthly_attendance.dart';

class StudentList extends StatefulWidget {
  final String username;
  final String schoolId;
  final String classId;
  final String month;
  final String year;
  final String className;
  final String section;
  const StudentList({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.month,
    required this.year,
    required this.username,
    required this.className,
    required this.section,
  });

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
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

    for (final student in students) {
      final username = student['username'];
      final data = await AdminApiService.fetchStudentMonthlyAttendance(
        username: username,
        month: widget.month,
        year: widget.year,
        schoolId: int.parse(widget.schoolId),
      );
      attendanceData[username] = data;
    }

    setState(() => isLoading = false);
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => MonthlyAttendance(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  // Helper widget for cleaner code
  Widget _buildInfoTile(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
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
                  ? MobileAppbar(
                    title: 'Monthly Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MonthlyAttendance(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'Monthly Attendance'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : students.isEmpty
                ? const Center(child: Text('No Students Found'))
                : Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // First Row: Class & Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoTile("Class", widget.className),
                              _buildInfoTile("Section", widget.section),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Second Row: Month & Year
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoTile("Month", widget.month),
                              _buildInfoTile("Year", widget.year),
                            ],
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

                          final total =
                              data?['TotalMarking']?.toString() ?? '-';
                          final present =
                              ((data?['fnPresentDates']?.length ?? 0) +
                                      (data?['anPresentDates']?.length ?? 0))
                                  .toString();
                          final absent =
                              ((data?['fnAbsentDates']?.length ?? 0) +
                                      (data?['anAbsentDates']?.length ?? 0))
                                  .toString();
                          final percentage =
                              data?['totalPercentage']?.toString() ?? '-';

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color:
                                student['gender'] == 'F'
                                    ? Colors.red[50]
                                    : Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        student['gender'] == 'F'
                                            ? Icons.female
                                            : Icons.male,
                                        color:
                                            student['gender'] == 'F'
                                                ? Colors.pink
                                                : Colors.blue,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Roll: $username",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _statTile(
                                        '',
                                        '${int.parse(present) / 2}/$total',
                                      ),
                                      _statTile('%', percentage),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
