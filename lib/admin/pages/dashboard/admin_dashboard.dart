import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/admin/widget/admin_mobile_drawer.dart';
import 'package:school_attendance/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../../administrator/services/administrator_api_service.dart';
import '../../../services/api_service.dart';
import '../../../teacher/services/teacher_api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/admin_mobile_dashboard.dart';
import '../drawer/edit_profile.dart';
import 'widget/admin_desktop_dashboard.dart';

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

  static bool _hasLoadedOnce = false;

  bool isBlocked = false;
  String? reason;

  @override
  void initState() {
    super.initState();
    loadCachedData();
    fetchFreshData();
  }

  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      adminName = prefs.getString('adminName') ?? '';
      adminDesignation = prefs.getString('adminDesignation') ?? '';
      schoolName = prefs.getString('schoolName');
      schoolAddress = prefs.getString('schoolAddress');
      mobile = prefs.getString('mobile');

      final cachedAdminPhoto = prefs.getString('adminPhoto');
      if (cachedAdminPhoto != null) {
        adminPhoto = Image.memory(
          base64Decode(cachedAdminPhoto),
          gaplessPlayback: true,
        );
      }

      final cachedSchoolPhoto = prefs.getString('schoolPhoto');
      if (cachedSchoolPhoto != null) {
        schoolPhoto = Image.memory(
          base64Decode(cachedSchoolPhoto),
          gaplessPlayback: true,
        );
      }

      _isLoading = adminName.isEmpty; // only show loader if no cached data
    });
  }

  Future<void> fetchFreshData() async {
    try {
      final List responses = await Future.wait([
        AdminApiService.fetchAdminData(
          username: widget.username,
          schoolId: widget.schoolId,
        ),
        ApiService.fetchSchoolData(widget.schoolId),
      ]);

      adminData = responses[0] as Map<String, dynamic>?;
      schoolData = responses[1] as List<Map<String, dynamic>>?;

      adminName = adminData?['name'] ?? '';
      adminDesignation = adminData?['designation'] ?? '';
      mobile = adminData?['mobile'];
      schoolName = schoolData?[0]['name'];
      schoolAddress = schoolData?[0]['address'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminName', adminName);
      await prefs.setString('adminDesignation', adminDesignation);
      await prefs.setString('schoolName', '$schoolName');
      await prefs.setString('schoolAddress', '$schoolAddress');
      await prefs.setString('adminPhoto', '${adminData!['photo']}');
      await prefs.setString('schoolPhoto', '${schoolData?[0]['photo']}');

      // decode images
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (adminData?['photo'] != null) {
            adminPhoto = Image.memory(
              base64Decode(adminData!['photo']),
              gaplessPlayback: true,
            );
          }
          if (schoolData?[0]['photo'] != null) {
            schoolPhoto = Image.memory(
              base64Decode(schoolData![0]['photo']),
              gaplessPlayback: true,
            );
          }
        });
      });

      await fetchSecondaryData();
      _hasLoadedOnce = true;
    } catch (e) {
      debugPrint("Fresh data fetch failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadCachedDataOrInitialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached data immediately
    setState(() {
      adminName = prefs.getString('adminName') ?? '';
      adminDesignation = prefs.getString('adminDesignation') ?? '';
      schoolName = prefs.getString('schoolName');
      schoolAddress = prefs.getString('schoolAddress');
      mobile = prefs.getString('mobile');

      final cachedAdminPhoto = prefs.getString('adminPhoto');
      if (cachedAdminPhoto != null) {
        adminPhoto = Image.memory(
          base64Decode(cachedAdminPhoto),
          gaplessPlayback: true,
        );
      }

      final cachedSchoolPhoto = prefs.getString('schoolPhoto');
      if (cachedSchoolPhoto != null) {
        schoolPhoto = Image.memory(
          base64Decode(cachedSchoolPhoto),
          gaplessPlayback: true,
        );
      }

      _isLoading = false;
    });

    // Check if school is blocked
    _checkBlocked(int.parse(widget.schoolId));

    // Fetch fresh data in background if not loaded yet
    if (!_hasLoadedOnce) {
      initializeInitialData();
    }
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
      setState(() => isBlocked = false);
    }
  }

  Future<void> initializeInitialData() async {
    if (_hasLoadedOnce) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schoolId', widget.schoolId);

    try {
      final List responses = await Future.wait([
        AdminApiService.fetchAdminData(
          username: widget.username,
          schoolId: widget.schoolId,
        ),
        ApiService.fetchSchoolData(widget.schoolId),
      ]);

      adminData = responses[0] as Map<String, dynamic>?;
      schoolData = responses[1] as List<Map<String, dynamic>>?;

      adminName = adminData?['name'] ?? '';
      if (adminName.isEmpty || adminName == 'null') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => EditProfile(
                  username: widget.username,
                  schoolName: schoolData?[0]['name'],
                  schoolAddress: schoolData?[0]['address'],
                  schoolId: widget.schoolId,
                  onBack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
          ),
        );
        return;
      }

      adminDesignation = adminData?['designation'] ?? '';
      mobile = adminData?['mobile'];
      schoolName = schoolData?[0]['name'];
      schoolAddress = schoolData?[0]['address'];

      // Save to cache
      await prefs.setString('adminName', adminName);
      await prefs.setString('adminDesignation', adminDesignation);
      await prefs.setString('schoolAddress', '$schoolAddress');
      await prefs.setString('adminPhoto', '${adminData!['photo']}');
      await prefs.setString('schoolPhoto', '${schoolData?[0]['photo']}');

      // Decode photos after UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (adminData?['photo'] != null) {
            adminPhoto = Image.memory(
              base64Decode(adminData!['photo']),
              gaplessPlayback: true,
            );
          }
          if (schoolData?[0]['photo'] != null) {
            schoolPhoto = Image.memory(
              base64Decode(schoolData![0]['photo']),
              gaplessPlayback: true,
            );
          }
        });
      });

      await fetchSecondaryData();

      _hasLoadedOnce = true;
    } catch (e) {
      debugPrint('Initial load failed: $e');
    } finally {
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
      await fetchAttendanceData();
    } catch (e) {
      debugPrint('Secondary data fetch failed: $e');
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
    final List<Future<void>> futures = [];
    for (var cls in classes) {
      final classId = cls['id'].toString();
      futures.addAll([
        ApiService.checkAttendanceStatusSession(
              widget.schoolId,
              classId,
              formattedCurrentDate,
              'FN',
            )
            .then((result) => attendanceStatusMapFn[classId] = result == false)
            .catchError((_) => attendanceStatusMapFn[classId] = true),
        ApiService.checkAttendanceStatusSession(
              widget.schoolId,
              classId,
              formattedCurrentDate,
              'AN',
            )
            .then((result) => attendanceStatusMapAn[classId] = result == false)
            .catchError((_) => attendanceStatusMapAn[classId] = true),
      ]);
    }
    await Future.wait(futures);
  }

  Future<void> fetchAttendanceData() async {
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
    final staffAttendanceAn = attendanceFutures[3] as Map<String, dynamic>;
    final studentAttendanceFn = attendanceFutures[4] as Map<String, dynamic>;
    final studentAttendanceAn = attendanceFutures[5] as Map<String, dynamic>;

    setState(() {
      presentStaffFN = staffAttendanceFn.values.where((s) => s == 'P').length;
      presentStaffAN = staffAttendanceAn.values.where((s) => s == 'P').length;
      presentStudentFN =
          studentAttendanceFn.values.where((s) => s == 'P').length;
      presentStudentAN =
          studentAttendanceAn.values.where((s) => s == 'P').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (_isLoading && adminName.isEmpty) {
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
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Admin Dashboard',
                    enableDrawer: true,
                    enableBack: false,
                    onBack: () {},
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Admin Dashboard',
                    onBack: () {},
                  ),
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
                ? SizedBox(
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
