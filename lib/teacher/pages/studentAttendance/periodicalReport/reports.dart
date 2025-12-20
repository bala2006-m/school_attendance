import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../admin/services/admin_api_service.dart';
import '../../../appbar/mobile_appbar.dart';
import '../../../services/teacher_api_service.dart';
import 'student_report_between_days.dart';

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

    // Fetch attendance for all students in parallel
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
    Navigator.push(
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

  // void _fetchAttendanceDetails(String username, String name) async {
  //   setState(() => isAttendanceLoading = true);
  //
  //   final data = await AdminApiService.fetchStudentAttendanceBetweenDays(
  //     username: username,
  //     fromDate: widget.from,
  //     toDate: widget.to,
  //     schoolId: int.parse(widget.schoolId),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: MobileAppbar(
            username: widget.username,
            schoolId: widget.schoolId.toString(),
            title: 'Student Report ',
            enableDrawer: false,
            enableBack: true,
            onBack: () {
              Navigator.push(
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
          ),
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
                    const SizedBox(height: 10),
                    SizedBox(
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
                    const SizedBox(height: 1),
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
                          final totalSessions = totalMarking;
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
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      student['gender'] == 'F'
                                          ? Icons.female
                                          : Icons.male,
                                      color:
                                          student['gender'] == 'F'
                                              ? Colors.red
                                              : Colors.blue,
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
                                        "$username",
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
                                        "${presentSessions / 2} / $totalSessions",
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
                    const SizedBox(height: 50),
                    if (isAttendanceLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
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

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
}
