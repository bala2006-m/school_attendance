import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/services/student_api_services.dart';
import 'package:school_attendance/student/widget/student_desktop_dashboard.dart';
import 'package:school_attendance/student/widget/student_mobile_dashboard.dart';
import 'package:school_attendance/student/widget/student_mobile_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/services/admin_api_service.dart';
import '../../administrator/services/administrator_api_service.dart';
import '../../login_page.dart';
import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';

class StudentDashboard extends StatefulWidget {
  final String username;
  final int schoolId;
  const StudentDashboard({
    super.key,
    required this.username,
    required this.schoolId,
  });

  @override
  StudentDashboardState createState() => StudentDashboardState();
}

class StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? studentData;
  Map<String, dynamic>? schoolData;
  Map<String, dynamic>? classData;
  String schoolName = '';
  String schoolAddress = '';
  Image? schoolPhoto;
  String message = '';
  List<String> timetable = [];
  bool _isLoading = true;
  static int selectedIndex = 1;
  bool isBlocked = false;
  String? reason;
  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _checkBlocked(widget.schoolId);
  }

  Future<void> _checkBlocked(int schoolId) async {
    try {
      final result = await AdministratorApiService.isSchoolBlocked(schoolId);

      setState(() {
        isBlocked = result['isBlocked'] ?? false;
        reason = result['reason'];
      });

      if (isBlocked) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('School Blocked'),
                content: Text(reason ?? "This school is blocked."),
                actions: [
                  TextButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        isBlocked = false;
      });
    } finally {}
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final data = await StudentApiServices.fetchStudentDataUsername(
        username: widget.username,
        schoolId: widget.schoolId,
      );

      prefs.setString('schoolId', '${data?['school_id']}');
      prefs.setString('studentName', '${data?['name']}');

      final photoData = data?['photo'];
      Uint8List photoBytes = Uint8List(0);
      if (photoData != 'null') {
        photoBytes =
            (photoData != null && photoData is Map)
                ? Uint8List.fromList(List<int>.from(photoData.values.toList()))
                : Uint8List(0);
      } else {
        photoBytes = Uint8List(0);
      }
      prefs.setString('studentPhoto', '$photoBytes');

      setState(() {
        studentData = data;
      });
      _loadSchoolAndClassData();
    } catch (e) {
      print("Error loading student data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchoolAndClassData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (studentData == null) return;

      int weekday = DateTime.now().weekday;
      List<String> weekdayNames = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];

      final results = await Future.wait([
        AdminApiService.fetchLatestMessage('${studentData!["school_id"]}'),
        StudentApiServices.fetchSchoolData('${studentData!["school_id"]}'),
        StudentApiServices.fetchClassDatas(
          '${studentData!["school_id"]}',
          '${studentData!["class_id"]}',
        ),
        StudentApiServices.fetchTimetable(
          schoolId: '${studentData!["school_id"]}',
          classId: '${studentData!["class_id"]}',
        ),
      ]);

      final String mes = results[0] as String;
      final schoolResult = results[1] as List<dynamic>;
      final classResult = results[2] as Map<String, dynamic>;
      final timeTable = results[3] as Map<String, List<String>>;

      await prefs.setString('schoolAddress', '${schoolResult[0]['address']}');
      await prefs.setString('schoolName', '${schoolResult[0]['name']}');
      await prefs.setString('schoolPhoto', '${schoolResult[0]['photo']}');

      setState(() {
        timetable = timeTable[weekdayNames[weekday - 1]] ?? [];
        message = mes;
        schoolData = (schoolResult.isNotEmpty) ? schoolResult[0] : null;
        classData = classResult;
        schoolName = schoolData?['name'] ?? 'Unknown School';
        schoolAddress = schoolData?['address'] ?? '';
        final photoData = schoolData?['photo'];
        final Uint8List photoBytes =
            (photoData != null && photoData is Map)
                ? Uint8List.fromList(List<int>.from(photoData.values.toList()))
                : Uint8List(0);
        schoolPhoto = Image.memory(photoBytes);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading school/class data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    if (studentData == null) {
      return Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? StudentAppbarMobile(
                    title: 'Student Dashboard',
                    enableDrawer: true,
                    enableBack: false,
                    onBack: () {
                      exit(0);
                    },
                  )
                  : const StudentAppbarDesktop(title: 'Student Dashboard'),
        ),
        body: const Center(
          child: Text(
            'Failed to load student data.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final name = studentData?['name'] ?? '';
    final email = studentData?['email'] ?? '';
    final schoolId = '${studentData?['school_id'] ?? ''}';
    final classId = '${studentData?['class_id'] ?? ''}';
    final gender = studentData?['gender'] ?? '';
    final mobile = studentData?['mobile'] ?? '';
    final photoData = studentData?['photo'];

    final Uint8List photoBytes =
        (photoData != null && photoData is Map)
            ? Uint8List.fromList(List<int>.from(photoData.values.toList()))
            : Uint8List(0);

    final schoolName = schoolData?['name'] ?? 'Unknown School';
    final schoolAddress = schoolData?['address'] ?? '';
    final className =
        '${classData?['class'] ?? 'Unknown Class'} ${classData?['section'] ?? ''}';
    final photoData1 = schoolData?['photo'];

    final Uint8List photoBytes1 =
        (photoData1 != null && photoData1 is Map)
            ? Uint8List.fromList(List<int>.from(photoData1.values.toList()))
            : Uint8List(0);
    final schoolPhoto1 = Image.memory(photoBytes1);
    //print(schoolPhoto1);
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Student Dashboard',
                  enableDrawer: true,
                  enableBack: false,
                  onBack: () {
                    exit(0);
                  },
                )
                : const StudentAppbarDesktop(title: 'Student Dashboard'),
      ),
      drawer:
          screenWidth > 600
              ? null
              : Drawer(
                child: StudentMobileDrawer(
                  onSave: _loadStudentData,
                  name: name,
                  email: email,
                  classId: classId,
                  schoolId: schoolId,
                  photo: photoBytes,
                  username: widget.username,
                  mobile: mobile,
                  schoolName: schoolName,
                  className: className,
                ),
              ),
      body:
          screenWidth > 600
              ? StudentDesktopDashboard(
                username: widget.username,
                name: name,
                email: email,
                schoolId: schoolId,
                classId: classId,
                gender: gender,
                photo: photoBytes,
                mobile: mobile,
                schoolName: schoolName,
                className: className,
                Message: message,
                SchoolAddress: schoolAddress,
                SchoolPhoto: schoolPhoto1,
              )
              : StudentMobileDashboard(
                schoolPhoto: schoolPhoto1,
                timetable: timetable,
                username: widget.username,
                name: name,
                email: email,
                schoolId: schoolId,
                classId: classId,
                gender: gender,
                schoolName: schoolName,
                className: className,
                selectedIndex: selectedIndex,
                schoolAddress: schoolAddress,
                message: message,
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group, size: 30),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.analytics, size: 30),
          //   label: 'Manage',
          // ),
        ],
      ),
    );
  }
}
