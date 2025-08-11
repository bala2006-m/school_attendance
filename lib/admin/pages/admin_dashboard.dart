import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/admin/widget/admin_mobile_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/api_service.dart';
import '../../teacher/services/teacher_api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../widget/admin_desktop_dashboard.dart';
import '../widget/admin_mobile_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  final String schoolId;
  final String username;

  const AdminDashboard({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  String adminName = '';
  String adminDesignation = '';
  Image? adminPhoto;
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  String? mobile;
  Map<String, dynamic>? adminData;
  List<Map<String, dynamic>>? schoolData;
  List<Map<String, dynamic>> classes = [];
  Map<String, bool> attendanceStatusMapFn = {};
  Map<String, bool> attendanceStatusMapAn = {};

  static int selectedIndex = 1;
  final String formattedCurrentDate = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now());

  int totalStudents = 0;
  int totalStaff = 0;
  int presentStaffFN = 0;
  int presentStaffAN = 0;
  int presentStudentFN = 0;
  int presentStudentAN = 0;
  String message = '';
  bool _isLoading = true;
  bool _isAttendanceLoading = true;

  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    if (!_hasLoadedOnce) {
      initializeInitialData();
    }
  }

  Future<void> initializeInitialData() async {
    if (_hasLoadedOnce) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('schoolId', widget.schoolId);

    try {
      final List responses = await Future.wait([
        AdminApiService.fetchAdminData(widget.username),
        ApiService.fetchSchoolData(widget.schoolId),
      ]);

      adminData = responses[0] as Map<String, dynamic>?;
      schoolData = responses[1] as List<Map<String, dynamic>>?;

      adminName = adminData?['name'] ?? '';
      adminDesignation = adminData?['designation'] ?? '';
      mobile = adminData?['mobile'];

      schoolName = schoolData?[0]['name'];
      schoolAddress = schoolData?[0]['address'];

      await prefs.setString('adminName', adminName);
      await prefs.setString('schoolAddress', '$schoolAddress');
      await prefs.setString('adminPhoto', '${adminData!['photo']}');
      await prefs.setString('schoolPhoto', '${schoolData?[0]['photo']}');

      setState(() => _isLoading = false); // Show UI immediately

      // Step 2: Decode photos after UI
      if (adminData?['photo'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            adminPhoto = Image.memory(
              base64Decode(adminData!['photo']),
              gaplessPlayback: true,
            );
          });
        });
      }

      if (schoolData?[0]['photo'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            schoolPhoto = Image.memory(
              base64Decode(schoolData![0]['photo']),
              gaplessPlayback: true,
            );
          });
        });
      }

      fetchSecondaryData();

      _hasLoadedOnce = true;
    } catch (e) {
      print('Initial load failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchSecondaryData() async {
    try {
      final results = await Future.wait([
        AdminApiService.countStudentUsernames(widget.schoolId),
        ApiService.countStaffUsernames(widget.schoolId),
        AdminApiService.fetchLatestMessage(widget.schoolId),
        fetchClasses(),
      ]);

      totalStudents = results[0] as int;
      totalStaff = results[1] as int;
      message = results[2] as String;

      await fetchAttendanceStatusForAll();
      fetchAttendanceData();
    } catch (e) {
      print('Secondary data fetch failed: $e');
    }
  }

  Future<void> fetchClasses() async {
    try {
      classes = await TeacherApiServices.fetchClassData(widget.schoolId);
      classes.sort((a, b) {
        int classCompare = a['class'].compareTo(b['class']);
        return classCompare != 0
            ? classCompare
            : a['section'].compareTo(b['section']);
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> fetchAttendanceStatusForAll() async {
    final String schoolId = widget.schoolId;
    final String formattedDate = formattedCurrentDate;
    final List<Future<void>> futures = [];
    for (var cls in classes) {
      final classId = cls['id'].toString();
      futures.addAll([
        ApiService.checkAttendanceStatusSession(
              schoolId,
              classId,
              formattedDate,
              'FN',
            )
            .then((result) => attendanceStatusMapFn[classId] = result == false)
            .catchError((e) {
              debugPrint("FN error class $classId: $e");
              attendanceStatusMapFn[classId] = true;
            }),
        ApiService.checkAttendanceStatusSession(
              schoolId,
              classId,
              formattedDate,
              'AN',
            )
            .then((result) => attendanceStatusMapAn[classId] = result == false)
            .catchError((e) {
              debugPrint("AN error class $classId: $e");
              attendanceStatusMapAn[classId] = true;
            }),
      ]);
    }

    await Future.wait(futures);
    // print(attendanceStatusMapFn);
    // print(attendanceStatusMapAn);
  }

  Future<void> fetchAttendanceData() async {
    try {
      final currentDate = formattedCurrentDate;

      final attendanceFutures = await Future.wait([
        AdminApiService.fetchStaffData(widget.schoolId),
        AdminApiService.fetchAllStudentData(widget.schoolId),
        ApiService.fetchTodayAttendance(currentDate, 'fn', widget.schoolId),
        ApiService.fetchTodayAttendance(currentDate, 'an', widget.schoolId),
        ApiService.fetchTodayStudentAttendance(
          currentDate,
          'fn',
          widget.schoolId,
        ),
        ApiService.fetchTodayStudentAttendance(
          currentDate,
          'an',
          widget.schoolId,
        ),
      ]);

      final staffAttendanceFn = attendanceFutures[2] as Map<String, dynamic>;
      // print(staffAttendanceFn);
      final staffAttendanceAn = attendanceFutures[3] as Map<String, dynamic>;
      final studentAttendanceFn = attendanceFutures[4] as Map<String, dynamic>;
      final studentAttendanceAn = attendanceFutures[5] as Map<String, dynamic>;

      int presentFn = staffAttendanceFn.values.where((s) => s == 'P').length;
      int presentAn = staffAttendanceAn.values.where((s) => s == 'P').length;
      int presentStuFn =
          studentAttendanceFn.values.where((s) => s == 'P').length;
      int presentStuAn =
          studentAttendanceAn.values.where((s) => s == 'P').length;

      setState(() {
        presentStaffFN = presentFn;
        presentStaffAN = presentAn;
        presentStudentFN = presentStuFn;
        presentStudentAN = presentStuAn;
        _isAttendanceLoading = false;
      });
    } catch (e) {
      print('Attendance load failed: $e');
      setState(() => _isAttendanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 20,
                  width: 200,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Admin Dashboard',
                    enableDrawer: true,
                    enableBack: false,
                    onBack: () {},
                  )
                  : const AdminAppbarDesktop(title: 'Admin Dashboard'),
        ),
        drawer:
            isMobile
                ? AdminMobileDrawer(
                  username: widget.username,
                  name: adminName,
                  designation: adminDesignation,
                  photo: adminPhoto,
                  schoolName: '$schoolName',
                  schoolAddress: '$schoolAddress',
                  mobileNumber: '$mobile',
                  schoolId: widget.schoolId,
                )
                : null,
        body: RefreshIndicator(
          onRefresh: () async {
            _hasLoadedOnce = false;
            await initializeInitialData();
          },
          child:
              isMobile
                  ? AdminMobileDashboard(
                    message: message,
                    schoolId: widget.schoolId,
                    username: widget.username,
                    adminName: adminName,
                    adminDesignation: adminDesignation,
                    adminPhoto: adminPhoto,
                    schoolName: '$schoolName',
                    schoolAddress: '$schoolAddress',
                    totalStudents: totalStudents,
                    totalStaff: totalStaff,
                    presentStaffFN: presentStaffFN,
                    presentStaffAN: presentStaffAN,
                    presentStudentFN: presentStudentFN,
                    presentStudentAN: presentStudentAN,
                    selectedIndex: selectedIndex,
                    attendanceStatusMapFn: attendanceStatusMapFn,
                    attendanceStatusMapAn: attendanceStatusMapAn,
                  )
                  : AdminDesktopDashboard(
                    message: message,
                    schoolId: widget.schoolId,
                    username: widget.username,
                    adminName: adminName,
                    adminDesignation: adminDesignation,
                    adminPhoto: adminPhoto,
                    schoolName: '$schoolName',
                    schoolAddress: '$schoolAddress',
                    totalStudents: totalStudents,
                    totalStaff: totalStaff,
                    presentStaffFN: presentStaffFN,
                    presentStaffAN: presentStaffAN,
                    presentStudentFN: presentStudentFN,
                    presentStudentAN: presentStudentAN,
                    selectedIndex: selectedIndex,
                    mobile: '$mobile',
                    attendanceStatusMapFn: attendanceStatusMapFn,
                    attendanceStatusMapAn: attendanceStatusMapAn,
                  ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        floatingActionButton:
            !isMobile
                ? Container(
                  width: MediaQuery.sizeOf(context).width * 0.922,
                  height: 120,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          _hasLoadedOnce = false;
                          await initializeInitialData();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        tooltip: 'Refresh',
                      ),
                    ),
                  ),
                )
                : null,
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
      ),
    );
  }
}
