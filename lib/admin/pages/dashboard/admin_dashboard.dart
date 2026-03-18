import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/widget/admin_mobile_drawer.dart';
import 'package:school_attendance/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../../administrator/services/administrator_api_service.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';
import '../../../services/bus_fee_payment_api.dart';
import '../../../services/rte_fees_service.dart';
import '../../../services/term_fee_structure_api.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
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
  Map<String, dynamic> allPendingTermFees = {};
  Map<String, dynamic> allPendingBusFees = {};
  Map<String, dynamic> allPendingRteFees = {};
  int totalStudents = 0;
  int totalStaff = 0;
  int presentStaffFN = 0;
  int presentStaffAN = 0;
  int presentStudentFN = 0;
  int presentStudentAN = 0;
  Map<String, dynamic>? adminAccess;
  String message = '';
  bool _isLoading = true;
  bool dialogOpen = false;
  static bool _hasLoadedOnce = false;

  bool isBlocked = false;
  String? reason;
  Timer? _realTimeTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCachedData();
      fetchFreshData();
      _startRealTimeTimer();
    });
  }

  @override
  void dispose() {
    _realTimeTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeTimer() {
    _realTimeTimer?.cancel();
    _realTimeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshRealTimeData();
    });
  }

  Future<void> _refreshRealTimeData() async {
    // 1. Refresh Access
    try {
      final accessResponse = await AdminApiService.fetchAdminAccess(
        username: widget.username,
        schoolId: widget.schoolId,
      );
      final finalAccess = _extractAccess(accessResponse);
      if (finalAccess != null && mounted) {
        // Only update if it actually changed to avoid unnecessary rebuilds
        if (jsonEncode(finalAccess) != jsonEncode(adminAccess)) {
          setState(() {
            adminAccess = finalAccess;
          });
        }
      }
    } catch (e) {
      // Ignore background fetch errors
    }

    // 2. Check Blocked Status
    _checkBlocked(int.parse(widget.schoolId));
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

      // Load Statistics
      totalStudents = prefs.getInt('totalStudents') ?? 0;
      totalStaff = prefs.getInt('totalStaff') ?? 0;
      presentStaffFN = prefs.getInt('presentStaffFN') ?? 0;
      presentStaffAN = prefs.getInt('presentStaffAN') ?? 0;
      presentStudentFN = prefs.getInt('presentStudentFN') ?? 0;
      presentStudentAN = prefs.getInt('presentStudentAN') ?? 0;
      message = prefs.getString('dashboardMessage') ?? '';

      final classesStr = prefs.getString('classesJson');
      if (classesStr != null) {
        classes = List<Map<String, dynamic>>.from(jsonDecode(classesStr));
      }

      final attFnStr = prefs.getString('attFnJson');
      if (attFnStr != null) {
        attendanceStatusMapFn = Map<String, bool>.from(jsonDecode(attFnStr));
      }

      final attAnStr = prefs.getString('attAnJson');
      if (attAnStr != null) {
        attendanceStatusMapAn = Map<String, bool>.from(jsonDecode(attAnStr));
      }

      final termFeesStr = prefs.getString('termFeesJson');
      if (termFeesStr != null) {
        allPendingTermFees = Map<String, dynamic>.from(jsonDecode(termFeesStr));
      }

      final busFeesStr = prefs.getString('busFeesJson');
      if (busFeesStr != null) {
        allPendingBusFees = Map<String, dynamic>.from(jsonDecode(busFeesStr));
      }

      final rteFeesStr = prefs.getString('rteFeesJson');
      if (rteFeesStr != null) {
        allPendingRteFees = Map<String, dynamic>.from(jsonDecode(rteFeesStr));
      }

      _isLoading = adminName.isEmpty; // only show loader if no cached data
    });
  }

  Map<String, dynamic>? _extractAccess(
    Map<String, dynamic>? accessDataWrapper,
  ) {
    if (accessDataWrapper == null) return null;

    // Option 1: It's directly the map (has common permission keys)
    if (accessDataWrapper.containsKey('manage') ||
        accessDataWrapper.containsKey('staff') ||
        accessDataWrapper.containsKey('student')) {
      return Map<String, dynamic>.from(accessDataWrapper);
    }

    // Option 1.5: It's a list (some backends return a list for single queries)
    if (accessDataWrapper['data'] is List &&
        (accessDataWrapper['data'] as List).isNotEmpty) {
      final firstItem = (accessDataWrapper['data'] as List).first;
      if (firstItem is Map<String, dynamic>) {
        return _extractAccess(firstItem);
      }
    }

    // Option 2: It's wrapped in 'data' and/or 'access'
    final accessData =
        (accessDataWrapper['data'] is Map)
            ? accessDataWrapper['data'] as Map<String, dynamic>
            : accessDataWrapper;
    final rawAccess = accessData['access'];

    if (rawAccess is Map) {
      if (rawAccess['access'] is Map) {
        return Map<String, dynamic>.from(rawAccess['access']);
      } else {
        return Map<String, dynamic>.from(rawAccess);
      }
    } else if (accessData.containsKey('manage') ||
        accessData.containsKey('staff')) {
      // Case where it was wrapped in 'data' but 'access' key is missing
      return Map<String, dynamic>.from(accessData);
    }

    return null;
  }

  Future<void> fetchFreshData() async {
    if (!_hasLoadedOnce && adminName.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        ApiService.fetchAdminAndSchoolData(
          username: widget.username,
          schoolId: widget.schoolId,
        ),
        AdminApiService.fetchAdminAccess(
          username: widget.username,
          schoolId: widget.schoolId,
        ),
      ]);

      final response = results[0] as Map<String, dynamic>;
      final accessResponse = results[1];

      if (response['status'] != 'success') {
        throw Exception('API returned failure status');
      }

      final data = response['data'] as Map<String, dynamic>?;
      final adminData = data?['adminData'] as Map<String, dynamic>?;
      final schoolData = data?['schoolData'] as Map<String, dynamic>?;
      final finalAccess = _extractAccess(accessResponse);

      adminName = adminData?['name'] ?? '';
      if (adminName.isEmpty || adminName == 'null') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => EditProfile(
                    username: widget.username,
                    schoolName: schoolData?['name'],
                    schoolAddress: schoolData?['address'],
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
        }
        return;
      }

      adminDesignation = adminData?['designation'] ?? '';
      mobile = adminData?['mobile'] ?? '';
      schoolName = schoolData?['name'] ?? '';
      schoolAddress = schoolData?['address'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminName', adminName);
      await prefs.setString('adminDesignation', adminDesignation);
      await prefs.setString('schoolName', schoolName!);
      await prefs.setString('schoolAddress', schoolAddress!);
      await prefs.setString('adminPhoto', adminData?['photo'] ?? '');
      await prefs.setString('schoolPhoto', schoolData?['photo'] ?? '');

      setState(() {
        adminAccess = finalAccess;
        if (adminData?['photo'] != null && adminData!['photo'].isNotEmpty) {
          adminPhoto = Image.memory(
            base64Decode(adminData['photo']),
            gaplessPlayback: true,
          );
        }
        if (schoolData?['photo'] != null && schoolData!['photo'].isNotEmpty) {
          schoolPhoto = Image.memory(
            base64Decode(schoolData['photo']),
            gaplessPlayback: true,
          );
        }
      });

      await fetchSecondaryData();
      _hasLoadedOnce = true;

      // Check if school is blocked
      // _checkBlocked(int.parse(widget.schoolId));
    } catch (e) {
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBlocked(int schoolId) async {
    try {
      final result = await AdministratorApiService.isSchoolBlocked(schoolId);

      setState(() {
        isBlocked = result['isBlocked'] ?? false;
        reason = result['reason'];
      });
      if (!isBlocked) {
        if (dialogOpen && mounted) {
          Navigator.of(navigatorKey.currentState!.overlay!.context).pop();
        }

        dialogOpen = false;

        return;
      }
      if (isBlocked) {
        if (mounted) {
          if (dialogOpen) return;

          dialogOpen = true;

          final ctx = navigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) return;

          showDialog(
            context: ctx,
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
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      setState(() => isBlocked = false);
    }
  }

  Future<void> initializeInitialData() async {
    if (_hasLoadedOnce && adminName.isNotEmpty) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schoolId', widget.schoolId);

    try {
      // Call unified combined API endpoint
      final Map<String, dynamic> response =
          await ApiService.fetchAdminAndSchoolData(
            username: widget.username,
            schoolId: widget.schoolId,
          );

      if (response['status'] != 'success') {
        throw Exception('Failed to load data');
      }

      final data = response['data'] as Map<String, dynamic>?;
      final adminData = data?['adminData'] as Map<String, dynamic>?;
      final schoolData = data?['schoolData'] as Map<String, dynamic>?;

      adminName = adminData?['name'] ?? '';
      if (adminName.isEmpty || adminName == 'null') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => EditProfile(
                    username: widget.username,
                    schoolName: schoolData?['name'],
                    schoolAddress: schoolData?['address'],
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
        }
        return;
      }

      adminDesignation = adminData?['designation'] ?? '';
      mobile = adminData?['mobile'];
      schoolName = schoolData?['name'];
      schoolAddress = schoolData?['address'];

      // Save to cache for offline use
      await prefs.setString('adminName', adminName);
      await prefs.setString('adminDesignation', adminDesignation);
      await prefs.setString('schoolName', schoolName ?? '');
      await prefs.setString('schoolAddress', schoolAddress ?? '');
      await prefs.setString('adminPhoto', adminData?['photo'] ?? '');
      await prefs.setString('schoolPhoto', schoolData?['photo'] ?? '');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (adminData?['photo'] != null && adminData!['photo'].isNotEmpty) {
            adminPhoto = Image.memory(
              base64Decode(adminData['photo']),
              gaplessPlayback: true,
            );
          }
          if (schoolData?['photo'] != null && schoolData!['photo'].isNotEmpty) {
            schoolPhoto = Image.memory(
              base64Decode(schoolData['photo']),
              gaplessPlayback: true,
            );
          }
        });
      });

      await fetchSecondaryData();

      _hasLoadedOnce = true;
    } catch (e) {
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchSecondaryData() async {
    try {
      final RteFeesService service = RteFeesService();

      final results = await Future.wait([
        ApiService.fetchCombinedData(widget.schoolId),
        TermFeeStructureApi.countAllPendingTermFees(int.parse(widget.schoolId)),
        BusFeePaymentApi.getPaidPendingBySchoolId(int.parse(widget.schoolId)),
        service.countRtePaidStudents(int.parse(widget.schoolId)),
      ]);

      final combinedData = results[0] as Map<String, dynamic>;
      final allPendingTermFee = results[1] as Map<String, dynamic>;
      final allPendingBusFee = results[2];
      final pendingPaid = results[3] as Map<String, dynamic>;

      setState(() {
        allPendingTermFees = allPendingTermFee;
        allPendingBusFees = allPendingBusFee ?? {};
        allPendingRteFees = pendingPaid;
      });

      totalStudents = int.parse(combinedData['totalStudents'].toString());
      totalStaff = int.parse(combinedData['totalStaff'].toString());
      message =
          combinedData['lastMessage']['messages'] == null
              ? '-'
              : combinedData['lastMessage']['messages'].toString();

      classes = List.from(combinedData['classes']);

      classes.sort((a, b) {
        int classCompare = a['class'].compareTo(b['class']);
        return classCompare != 0
            ? classCompare
            : a['section'].compareTo(b['section']);
      });

      // These two can also run in parallel
      await Future.wait([fetchAttendanceStatusForAll(), fetchAttendanceData()]);

      await _saveStatsToCache();
      await makeSundayHoliday(classes);
    } catch (e) {
      return;
    }
  }

  Future<void> _saveStatsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalStudents', totalStudents);
      await prefs.setInt('totalStaff', totalStaff);
      await prefs.setInt('presentStaffFN', presentStaffFN);
      await prefs.setInt('presentStaffAN', presentStaffAN);
      await prefs.setInt('presentStudentFN', presentStudentFN);
      await prefs.setInt('presentStudentAN', presentStudentAN);
      await prefs.setString('dashboardMessage', message);
      await prefs.setString('classesJson', jsonEncode(classes));
      await prefs.setString('attFnJson', jsonEncode(attendanceStatusMapFn));
      await prefs.setString('attAnJson', jsonEncode(attendanceStatusMapAn));
      await prefs.setString('termFeesJson', jsonEncode(allPendingTermFees));
      await prefs.setString('busFeesJson', jsonEncode(allPendingBusFees));
      await prefs.setString('rteFeesJson', jsonEncode(allPendingRteFees));
    } catch (e) {
      // Ignore cache saving errors
    }
  }

  Future<void> makeSundayHoliday(List<Map<String, dynamic>> classes) async {
    // Dynamically build classIds list from classes parameter as int list
    final List<int> classIds =
        classes.map((c) => int.parse(c['id'].toString())).toList();

    // Get current date info and first/last day of current month
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Collect all Sundays in the current month
    List<DateTime> sundays = [];
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(now.year, now.month, day);
      if (date.weekday == DateTime.sunday) {
        sundays.add(date);
      }
    }

    // Fetch existing holidays from your API
    final holidays = await ApiService.fetchHolidays(widget.schoolId);

    for (final sunday in sundays) {
      final sundayStr = DateFormat('yyyy-MM-dd').format(sunday);

      // Find existing holiday entry for sunday
      final existingHoliday = holidays.firstWhere((h) {
        final holidayDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(h['date']));
        return holidayDate == sundayStr;
      }, orElse: () => {});

      bool needsAddOrUpdate = false;
      // Check if all classIds are included in existing holiday's class_ids
      List<dynamic> existingClassIdsDynamic =
          existingHoliday['class_ids'] ?? [];
      List<int> existingClassIds =
          existingClassIdsDynamic.map((e) => int.parse(e.toString())).toList();

      final missingClassIds =
          classIds.where((id) => !existingClassIds.contains(id)).toList();
      if (missingClassIds.isNotEmpty) {
        needsAddOrUpdate = true;
      }

      if (needsAddOrUpdate) {
        await ApiService.addHoliday(
          date: sundayStr,
          reason: 'Sunday',
          schoolId: widget.schoolId,
          classIds: classIds,
          fn: 'H',
          an: 'H',
        );
      }
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
      // AdminApiService.fetchStaffData(widget.schoolId),
      // AdminApiService.fetchAllStudentData(widget.schoolId),
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

    final staffAttendanceFn = attendanceFutures[0] as Map<String, dynamic>;
    final staffAttendanceAn = attendanceFutures[1] as Map<String, dynamic>;
    final studentAttendanceFn = attendanceFutures[2] as Map<String, dynamic>;
    final studentAttendanceAn = attendanceFutures[3] as Map<String, dynamic>;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {},
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
            await fetchFreshData();
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
                    allPendingTermFees: allPendingTermFees,
                    allPendingBusFees: allPendingBusFees,
                    allPendingRteFees: allPendingRteFees,
                    adminAccess: adminAccess,
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
                    allPendingTermFees: allPendingTermFees,
                    allPendingBusFees: allPendingBusFees,
                    allPendingRteFees: allPendingRteFees,
                    adminAccess: adminAccess,
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
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.bar_chart, size: 30),
            //   label: 'Analytics',
            // ),
          ],
        ),
      ),
    );
  }
}
