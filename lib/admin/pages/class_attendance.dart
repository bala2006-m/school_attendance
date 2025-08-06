import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/date_button.dart';
import 'admin_dashboard.dart';
import 'class_wise_attendance.dart';

class ClassAttendance extends StatefulWidget {
  final String classId;
  final String schoolId;
  final DateTime date;
  final String username;
  const ClassAttendance({
    super.key,
    required this.classId,
    required this.schoolId,
    required this.date,
    required this.username,
  });

  @override
  State<ClassAttendance> createState() => _ClassAttendanceState();
}

class _ClassAttendanceState extends State<ClassAttendance> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> attendanceData = [];

  String selectedSession = 'forenoon';
  bool isLoading = true;
  bool hasError = false;
  int totalAbsentForenoon = 0;
  int totalAbsentAfternoon = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final data = await TeacherApiServices.fetchStudentData(
        schoolId: widget.schoolId,
        classId: widget.classId,
      ).timeout(const Duration(seconds: 15));

      final attendance = await ApiService.fetchStudentAttendance(
        date: DateFormat('yyyy-MM-dd').format(DateTime.parse('${widget.date}')),
        schoolId: widget.schoolId,
        classId: widget.classId,
      );

      totalAbsentForenoon =
          attendance.where((s) => s['fn_status'] != 'P').length;
      totalAbsentAfternoon =
          attendance.where((s) => s['an_status'] != 'P').length;

      setState(() {
        students = List<Map<String, dynamic>>.from(data);
        attendanceData = List<Map<String, dynamic>>.from(attendance);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClassWiseAttendance(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Class Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Class Attendance'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : hasError
                ? const Center(child: Text("Failed to load student data."))
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child:
                            isMobile
                                ? dateBuilder(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.parse('${widget.date}')),
                                )
                                : null,
                      ),

                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedSession = 'forenoon';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedSession == 'forenoon'
                                        ? Colors.teal
                                        : Colors.grey,
                              ),
                              child: const Text(
                                'Forenoon',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedSession = 'afternoon';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedSession == 'afternoon'
                                        ? Colors.teal
                                        : Colors.grey,
                              ),
                              child: const Text(
                                'Afternoon',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Table(
                          border: TableBorder.all(),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Colors.teal),
                              children: [
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Total Students',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Present',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Absent',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(students.length.toString()),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${students.length - (selectedSession == 'forenoon' ? totalAbsentForenoon : totalAbsentAfternoon)}',
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${selectedSession == 'forenoon' ? totalAbsentForenoon : totalAbsentAfternoon}',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const Text(
                        'Student Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: ListView.builder(
                          itemCount: attendanceData.length,
                          itemBuilder: (context, index) {
                            final student = attendanceData[index];
                            final name = student['name'] ?? 'Unknown';
                            final status =
                                selectedSession == 'forenoon'
                                    ? student['fn_status']
                                    : student['an_status'];

                            return ListTile(
                              title: Text(name),
                              trailing: Text(
                                status ?? 'N/A',
                                style: TextStyle(
                                  color:
                                      status == 'P' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
