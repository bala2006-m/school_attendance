import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
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
    try {
      students = await TeacherApiServices.fetchStudentData(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      students.sort((a, b) {
        // Gender: Males ('M') first, then Females
        if (a['gender'] == b['gender']) {
          var aUsername = a['username'].toString();
          var bUsername = b['username'].toString();

          // Check if both usernames are numeric
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);

          if (numA != null && numB != null) {
            // Both numeric: compare numerically
            return numA.compareTo(numB);
          } else {
            // Otherwise: compare as strings
            return aUsername.compareTo(bUsername);
          }
        } else if (a['gender'] == 'M') {
          return -1;
        } else {
          return 1;
        }
      });

      for (final student in students) {
        final uname = student['username'];
        final data = await AdminApiService.fetchStudentMonthlyAttendance(
          username: uname,
          month: widget.month,
          year: widget.year,
          schoolId: int.parse(widget.schoolId),
        );
        attendanceData[uname] = data;
      }
    } catch (e) {
      setState(() => isLoading = false);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final monthMap = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Monthly Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
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
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Monthly Attendance',

                    onBack: () {
                      Navigator.push(
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
                  ),
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
                    const SizedBox(height: 20),
                    // Info Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoTile("Class", widget.className),
                              _buildInfoTile("Section", widget.section),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoTile(
                                "Month",
                                monthMap[(int.parse(widget.month) - 1)],
                              ),
                              _buildInfoTile("Year", widget.year),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Student List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final uname = student['username'];
                          String name = student['name'] ?? 'Unnamed';
                          if (name.length > 15) {
                            name = '${name.substring(0, 15)}...';
                          }
                          final data = attendanceData[uname];

                          final total =
                              data?['TotalMarking']?.toString() ?? '-';

                          final presentCount =
                              ((data?['fnPresentDates']?.length ?? 0) +
                                  (data?['anPresentDates']?.length ?? 0));

                          // final absentCount =
                          //     ((data?['fnAbsentDates']?.length ?? 0) +
                          //         (data?['anAbsentDates']?.length ?? 0));

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
                                  Icon(
                                    student['gender'] == 'F'
                                        ? Icons.female
                                        : Icons.male,
                                    color:
                                        student['gender'] == 'F'
                                            ? Colors.red
                                            : Colors.blue,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                student['gender'] == 'M'
                                                    ? Colors.blue
                                                    : student['gender'] == 'F'
                                                    ? Colors.red
                                                    : Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Roll: $uname",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _statTile(
                                        '',
                                        '${(presentCount / 2).toStringAsFixed(1)}/$total',
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
}
