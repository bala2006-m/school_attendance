import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:school_attendance/teacher/widget/mobile_drawer.dart';
import 'package:school_attendance/teacher/widget/staff_dashboard_mobile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/services/admin_api_service.dart';
import '../../services/api_service.dart';
import '../widget/staff_dashboard_desktop.dart';

class StaffDashboard extends StatefulWidget {
  final String username;

  const StaffDashboard({super.key, required this.username});

  @override
  State<StaffDashboard> createState() => StaffDashboardState();
}

class StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic> staff = {};
  Map<String, dynamic> schoolData = {};
  Map<String, dynamic> classData = {};
  List<dynamic> classIds = [];
  String schoolName = '';
  String schoolAddress = '';
  Image? schoolPhoto;
  String message = '';
  int totalStudents = 0;
  int presentStudentFN = 0;
  int presentStudentAN = 0;
  bool _isLoading = true;
  static int selectedIndex = 1;
  final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();

      final data = await TeacherApiServices.fetchStaffDataUsername(
        widget.username,
      );
      if (!mounted) return;
      final schoolId = '${data?['school_id']}';

      final results = await Future.wait([
        AdminApiService.fetchLatestMessage(schoolId),
        ApiService.fetchTodayStudentAttendanceClass(
          currentDate,
          'fn',
          schoolId,
        ),
        ApiService.fetchTodayStudentAttendanceClass(
          currentDate,
          'an',
          schoolId,
        ),
      ]);

      // Extract results
      final mes = results[0] as String;
      int count = 0;
      final rawClassIds = data?['class_ids'].toString();
      final List<dynamic> classId = jsonDecode(rawClassIds!);
      for (int i = 0; i < classId.length; i++) {
        final s = await TeacherApiServices.fetchStudentData(
          schoolId: schoolId,
          classId: '${classId[i]}',
        );
        count += s.length;
      }
      final studentAttendanceFn = results[1] as Map;
      final studentAttendanceAn = results[2] as Map;

      int presentStuFn = 0;
      for (int i = 0; i < classId.length; i++) {
        final intClassId = int.parse('${classId[i]}');

        presentStuFn +=
            studentAttendanceFn.values
                .where((s) => s['status'] == 'P' && s['class_id'] == intClassId)
                .length;
      }

      int presentStuAn = 0;
      for (int i = 0; i < classId.length; i++) {
        final intClassId = int.parse('${classId[i]}');
        presentStuAn +=
            studentAttendanceAn.values
                .where((s) => s['status'] == 'P' && s['class_id'] == intClassId)
                .length;
      }

      prefs.setString('schoolId', schoolId);
      prefs.setString('staffName', '${data?['name']}');
      prefs.setString('staffUsername', widget.username);

      // Update state
      setState(() {
        staff = data!;
        classIds = classId;
        fetchSchoolInfo();
        message = mes;
        totalStudents = count;
        presentStudentFN = presentStuFn;
        presentStudentAN = presentStuAn;
      });
    } catch (e) {
      print("Error loading staff data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(
        '${staff['school_id']}',
      );
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('schoolName', '${schoolData[0]['name']}');
      prefs.setString('schoolAddress', '${schoolData[0]['address']}');
      await prefs.setString('schoolPhoto', '${schoolData[0]['photo']}');
      schoolName = schoolData[0]['name'];
      schoolAddress = schoolData[0]['address'];

      if (schoolData[0]['photo'] != null) {
        try {
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          schoolPhoto = Image.memory(imageBytes, gaplessPlayback: true);
        } catch (_) {
          schoolPhoto = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = MediaQuery.of(context).size.width < 500;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    final name = staff['name'] ?? 'Staff';
    final schoolId = staff['school_id'];
    final email = staff['email'] ?? 'Staff';
    final classId = staff['class_id'] ?? 'Staff';
    final gender = staff['gender'] ?? 'Staff';
    final photoData = staff['photo'] ?? 'Staff';
    final mobile = staff['mobile'] ?? 'Staff';
    // final schoolId = '${studentData?['school_id'] ?? ''}';
    // final name = studentData?['name'] ?? '';
    final Uint8List photoBytes =
        (photoData != null && photoData is Map)
            ? Uint8List.fromList(List<int>.from(photoData.values.toList()))
            : Uint8List(0);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Staff Dashboard',
                  enableDrawer: true,
                  enableBack: false,
                  onBack: () {
                    exit(0);
                  },
                )
                : const DesktopAppbar(title: 'Staff Dashboard'),
      ),
      drawer:
          screenWidth > 600
              ? null
              : MobileDrawer(
                name: name,
                email: email,
                classId: '$classId',
                schoolId: '$schoolId',
                photo: photoBytes,
                username: widget.username,
                mobile: mobile,
                schoolName: schoolName,
              ),
      body:
          screenWidth > 600
              ? StaffDashboardDesktop(
                username: widget.username,
                name: name,
                email: email,
                schoolId: schoolId,
                classId: classId,
                gender: gender,
                photo: photoBytes,
                mobile: mobile,
                schoolName: schoolName,
                message: message,
                schoolAddress: schoolAddress,
                schoolPhoto: schoolPhoto,
              )
              : StaffDashboardMobile(
                username: widget.username,
                name: name,
                email: email,
                schoolId: '$schoolId',
                classId: '$classId',
                gender: gender,
                schoolName: schoolName,
                selectedIndex: selectedIndex,
                schoolAddress: schoolAddress,
                message: message,
                totalStudents: '$totalStudents',
                presentStudentFN: '$presentStudentFN',
                presentStudentAN: '$presentStudentAN',
                classIds: classIds,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics, size: 30),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
