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
import '../../administrator/services/administrator_api_service.dart';
import '../../login_page.dart';
import '../../services/api_service.dart';
import '../widget/staff_dashboard_desktop.dart';
import './edit_profile_screen.dart';

class StaffDashboard extends StatefulWidget {
  final String username;
  final String schoolId;
  const StaffDashboard({
    super.key,
    required this.username,
    required this.schoolId,
  });

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
  bool isBlocked = false;
  String? reason;
  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _checkBlocked(int.parse(widget.schoolId));
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


  Future<void> _loadStaffData() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();

      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.username,
        schoolId: int.parse(widget.schoolId),
      );
      //print(data);
      prefs.setString('schoolId', widget.schoolId);
      prefs.setString('staffName', '${data?['name']}');
      prefs.setString('staffUsername', widget.username);
      if (data?['name'] == null ||
          data?['name'] == '' ||
          data?['name'] == 'null' ||
          data!['name'].toString().isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => EditProfileScreen(
                  username: widget.username,
                  submit: () {
                    _loadStaffData();
                  },
                  schoolId: int.parse(widget.schoolId),
                ),
          ),
        );
      }
      if (data?['photo'] != null && data?['photo'] is Map) {
        // Convert the Map<int,int> to Uint8List
        final photoBytes = Uint8List.fromList(
          List<int>.from(data?['photo'].values),
        );
        // Encode to Base64
        final base64String = base64Encode(photoBytes);
        prefs.setString('staffPhoto', base64String);
      } else {
        prefs.remove('staffPhoto'); // Or store a placeholder
      }
      // print(data);
      fetchSchoolInfo(data);
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
      final studentAttendanceFn = results[1] as Map;
      int presentStuAn = 0;
      final studentAttendanceAn = results[2] as Map;
      int presentStuFn = 0;
      final mes = results[0] as String;
      int count = 0;
      final rawClassIds = data?['class_ids'].toString();
      List<dynamic> classId = [];
      // if (rawClassIds != 'null') {
      //   classId = jsonDecode(rawClassIds!);
      //   for (int i = 0; i < classId.length; i++) {
      //     final s = await TeacherApiServices.fetchStudentData(
      //       schoolId: schoolId,
      //       classId: '${classId[i]}',
      //     );
      //     count += s.length;
      //   }
      //
      //   for (int i = 0; i < classId.length; i++) {
      //     final intClassId = int.parse('${classId[i]}');
      //
      //     presentStuFn +=
      //         studentAttendanceFn.values
      //             .where(
      //               (s) => s['status'] == 'P' && s['class_id'] == intClassId,
      //             )
      //             .length;
      //   }
      //
      //   for (int i = 0; i < classId.length; i++) {
      //     final intClassId = int.parse('${classId[i]}');
      //     presentStuAn +=
      //         studentAttendanceAn.values
      //             .where(
      //               (s) => s['status'] == 'P' && s['class_id'] == intClassId,
      //             )
      //             .length;
      //   }
      // }
      final c = await AdminApiService.countStudentUsernames(
        '${data?['school_id']}',
      );
      final studentFn = await ApiService.fetchTodayStudentAttendance(
        currentDate,
        'fn',
        '${data?['school_id']}',
      );
      final studentAn = await ApiService.fetchTodayStudentAttendance(
        currentDate,
        'an',
        '${data?['school_id']}',
      );
      int presentStFn = studentFn.values.where((s) => s == 'P').length;
      int presentSAn = studentAn.values.where((s) => s == 'P').length;

      count = int.parse(c.toString());
      setState(() {
        staff = data!;
        classIds = classId;
        message = mes;
        totalStudents = count;
        presentStudentFN = presentStFn;
        presentStudentAN = presentSAn;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading staff data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> fetchSchoolInfo(staff1) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final schoolData = await ApiService.fetchSchoolData(
        '${staff1['school_id']}',
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
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching school info: $e');
      setState(() {
        _isLoading = false;
      });
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
                submit: _loadStaffData,
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
                submit: _loadStaffData,
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
                schoolPhoto: schoolPhoto,
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
