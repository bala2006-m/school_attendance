import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/services/student_api_services.dart';
import 'package:school_attendance/student/widget/student_desktop_dashboard.dart';
import 'package:school_attendance/student/widget/student_mobile_dashboard.dart';
import 'package:school_attendance/student/widget/student_mobile_drawer.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';

class StudentDashboard extends StatefulWidget {
  final String username;

  const StudentDashboard({super.key, required this.username});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? studentData;
  Map<String, dynamic>? schoolData;
  Map<String, dynamic>? classData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final data = await StudentApiServices.fetchStudentDataUsername(
        widget.username,
      );

      setState(() {
        studentData = data;
      });

      await _loadSchoolAndClassData();
    } catch (e) {
      print("Error loading student data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchoolAndClassData() async {
    try {
      if (studentData == null) return;

      final schoolResult = await StudentApiServices.fetchSchoolData(
        '${studentData!["school_id"]}',
      );

      final classResult = await StudentApiServices.fetchClassDatas(
        '${studentData!["school_id"]}',
        '${studentData!["class_id"]}',
      );

      setState(() {
        schoolData = (schoolResult.isNotEmpty) ? schoolResult[0] : null;
        classData = classResult;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading school/class data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    if (studentData == null) {
      return Scaffold(
        appBar: const StudentAppbarMobile(title: 'Student Dashboard'),
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

    final className =
        '${classData?['class'] ?? 'Unknown Class'} ${classData?['section'] ?? ''}';

    return Scaffold(
      appBar:
          screenWidth > 600
              ? const StudentAppbarDesktop(title: 'Student Dashboard')
              : const StudentAppbarMobile(title: 'Student Dashboard'),
      drawer:
          screenWidth > 600
              ? null
              : Drawer(
                child: StudentMobileDrawer(
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
              )
              : StudentMobileDashboard(
                username: widget.username,
                name: name,
                email: email,
                schoolId: schoolId,
                classId: classId,
                gender: gender,
                schoolName: schoolName,
                className: className,
              ),
    );
  }
}
