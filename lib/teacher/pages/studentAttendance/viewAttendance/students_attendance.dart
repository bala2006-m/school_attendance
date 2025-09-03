import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../admin/widget/attendance_screen.dart';
import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../appbar/desktop_appbar.dart';
import '../../../appbar/mobile_appbar.dart';
import '../../../services/teacher_api_service.dart';
import 'view_student_attendance.dart';

class ViewStudentAttendance extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String className;
  final String section;
  final String username;

  const ViewStudentAttendance({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
    required this.username,
  });

  @override
  State<ViewStudentAttendance> createState() => _ViewStudentAttendanceState();
}

class _ViewStudentAttendanceState extends State<ViewStudentAttendance> {
  final GlobalKey _attendanceKey = GlobalKey();
  String userName = '';
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> holidayList = [];

  bool isLoadingAttendance = false;
  bool isLoadingStudents = true;
  bool enableAttendance = false;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      students = await TeacherApiServices.fetchStudentData(
        classId: widget.classId,
        schoolId: widget.schoolId,
      );
      filteredStudents = students;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load students")));
    } finally {
      setState(() {
        isLoadingStudents = false;
      });
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentAttendanceClasses(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> fetchAttendanceData({required String username}) async {
    setState(() {
      isLoadingAttendance = true;
      enableAttendance = false;
    });

    try {
      final fetchedAttendance =
          await StudentApiServices.fetchStudentAttendanceByClassid(
            schoolId: widget.schoolId,
            classId: widget.classId,
            username: username,
          );
      final fetchedHolidays = await ApiService.fetchHolidays(widget.schoolId);

      setState(() {
        userName = username;
        attendance = fetchedAttendance;
        holidayList = List<Map<String, dynamic>>.from(fetchedHolidays);
        enableAttendance = true;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        final ctx = _attendanceKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      //print('Error fetching attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch attendance')),
      );
    } finally {
      setState(() {
        isLoadingAttendance = false;
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStudents = students;
      } else {
        final search = query.toLowerCase();
        filteredStudents =
            students.where((student) {
              final name = (student['name'] ?? '').toString().toLowerCase();
              final username =
                  (student['username'] ?? '').toString().toLowerCase();
              return name.contains(search) || username.contains(search);
            }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    title: 'Student Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StudentAttendanceClasses(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'View Student Attendance'),
        ),
        body:
            isLoadingStudents
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : students.isEmpty
                ? const Center(child: Text("No students found"))
                : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: const Icon(Icons.class_),
                              title: Text('Class: ${widget.className}'),
                              subtitle: Text('Section: ${widget.section}'),
                            ),
                          ),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search by name or username",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: _filterStudents,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Select a Student',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 1,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredStudents.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(student['name']),
                                  subtitle: Text(student['username']),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap:
                                      () => fetchAttendanceData(
                                        username: student['username'],
                                      ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (enableAttendance)
                            Column(
                              key: _attendanceKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 32),
                                Text(
                                  'Attendance for: $userName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (attendance.isNotEmpty)
                                  Column(
                                    children: [
                                      AttendanceScreen(
                                        schoolId: widget.schoolId,
                                        holidayList: holidayList,
                                        data: attendance,
                                        title: 'Student Attendance',
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                else
                                  const Text('No attendance data found.'),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (isLoadingAttendance)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: SpinKitFadingCircle(
                            color: Colors.blueAccent,
                            size: 60.0,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
