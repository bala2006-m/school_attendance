import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../services/api_service.dart';
import '../../student/services/student_api_services.dart';
import '../../teacher/services/teacher_api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/build_profile_card_mobile.dart';
import '../components/export_attendance_to_excel.dart';
import '../widget/attendance_screen.dart';
import 'admin_dashboard.dart';

class ClassList extends StatefulWidget {
  final String schoolId;
  final String username;
  const ClassList({super.key, required this.schoolId, required this.username});

  @override
  State<ClassList> createState() => _ClassListState();
}

class _ClassListState extends State<ClassList> {
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
        // Convert roman numerals if needed
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
          // Try to parse to int
          final parsed = int.tryParse(val);
          if (parsed != null) return parsed;
          // Check if it's a Roman numeral
          return romanMap[val] ?? 999; // fallback for unknown
        }

        return 999; // fallback for null or unknown
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
            (context) => AdminDashboard(
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

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Class List',
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
                  : const AdminAppbarDesktop(title: 'Class List'),
        ),
        body:
            isLoading
                ? const SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BuildProfileCard(
                        schoolPhoto: schoolPhoto,
                        schoolAddress: '$schoolAddress',
                        schoolName: '$schoolName',
                      ),
                      const SizedBox(height: 16),
                      classes.isEmpty
                          ? const Center(
                            child: Text(
                              "No Classes Found",
                              style: TextStyle(fontSize: 16),
                            ),
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
                              final classId = item['id'].toString();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ViewStudentAttendance(
                                            classId: classId,
                                            className: item['class'],
                                            section: item['section'],
                                            username: widget.username,
                                            school_id: widget.schoolId,
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
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "${item['section']} Sec",
                                          style: TextStyle(
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

class ViewStudentAttendance extends StatefulWidget {
  final String school_id;
  final String classId;
  final String className;
  final String section;
  final String username;

  const ViewStudentAttendance({
    super.key,
    required this.school_id,
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
  final TextEditingController _mobileController = TextEditingController();
  String userName = '';
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> holidayList = [];
  bool isLoading = false;
  bool enableAttendance = false;
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    students = await TeacherApiServices.fetchStudentData(
      classId: widget.classId,
      schoolId: widget.school_id,
    );
    setState(() {});
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClassList(
              schoolId: widget.school_id,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> fetchAttendanceData({required String username}) async {
    setState(() {
      isLoading = true;
      enableAttendance = false;
    });

    try {
      final fetchedAttendance =
          await StudentApiServices.fetchStudentAttendanceByClassid(
            schoolId: widget.school_id,
            classId: widget.classId,
            username: username,
          );
      final fetchedHolidays = await ApiService.fetchHolidays(widget.school_id);

      setState(() {
        userName = username;
        attendance = fetchedAttendance;
        holidayList = List<Map<String, dynamic>>.from(fetchedHolidays);
        enableAttendance = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(
          _attendanceKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    } catch (e) {
      print('Error fetching attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch attendance')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
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
                  ? AdminAppbarMobile(
                    title: 'View Student Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ClassList(
                                schoolId: widget.school_id,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'View Student Attendance'),
        ),
        body:
            students.isEmpty
                ? const Center(child: CircularProgressIndicator())
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
                              itemCount: students.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final student = students[index];
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
                                        schoolId: widget.school_id,
                                        holidayList: holidayList,
                                        data: attendance,
                                        title: 'Student Attendance',
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.download_outlined,
                                          ),
                                          label: const Text("Export Excel"),
                                          onPressed:
                                              () => exportAttendanceToExcel(
                                                context,
                                                attendance,
                                                userName,
                                              ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Text('No attendance data found.'),
                              ],
                            ),
                        ],
                      ),
                    ),

                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
      ),
    );
  }
}
