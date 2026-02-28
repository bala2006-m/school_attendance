import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:school_attendance/teacher/widget/mobile_drawer.dart';
import 'package:school_attendance/teacher/widget/staff_dashboard_mobile.dart';
import 'package:school_attendance/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/services/admin_api_service.dart';
import '../../administrator/services/administrator_api_service.dart';
import '../../login_page.dart';
import '../../services/api_service.dart';
import 'drawer/edit_profile_screen.dart';

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
  final String formattedCurrentDate = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now());

  bool isBlocked = false;
  String? reason;
  final Map<String, bool> canTakeAttendanceFn = {};
  final Map<String, bool> canTakeAttendanceAn = {};

  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    _loadFromCache().then((_) {
      // Load fresh data silently without blocking UI
      final id = int.tryParse(widget.schoolId);
      if (id != null) {
        _checkBlocked(id);
      }
      _loadStaffData();
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStaffString = prefs.getString('staffData');
      final cachedSchoolName = prefs.getString('schoolName') ?? '';
      final cachedSchoolAddress = prefs.getString('schoolAddress') ?? '';
      final cachedSchoolPhotoStr = prefs.getString('schoolPhoto');
      final cachedMessage = prefs.getString('latestMessage') ?? '';
      final cachedTotalStudents = prefs.getInt('totalStudents') ?? 0;
      final cachedPresentFn = prefs.getInt('presentStudentFN') ?? 0;
      final cachedPresentAn = prefs.getInt('presentStudentAN') ?? 0;
      final cachedClassIdsString = prefs.getString('classIds');
      final cachedClassesString = prefs.getString('classes');

      Map<String, dynamic> cachedStaffData = {};
      if (cachedStaffString != null) {
        cachedStaffData = jsonDecode(cachedStaffString);
      }
      List<dynamic> cachedClassIds = [];
      if (cachedClassIdsString != null) {
        cachedClassIds = jsonDecode(cachedClassIdsString);
      }
      List<Map<String, dynamic>> cachedClassesData = [];
      if (cachedClassesString != null) {
        final parsed = jsonDecode(cachedClassesString);
        if (parsed is List) {
          cachedClassesData = List<Map<String, dynamic>>.from(parsed);
        }
      }

      Image? photo;
      if (cachedSchoolPhotoStr != null && cachedSchoolPhotoStr.isNotEmpty) {
        try {
          final bytes = base64Decode(cachedSchoolPhotoStr);
          photo = Image.memory(bytes, gaplessPlayback: true);
        } catch (_) {
          photo = null;
        }
      }

      if (!mounted) return;
      setState(() {
        staff = cachedStaffData;
        schoolName = cachedSchoolName;
        schoolAddress = cachedSchoolAddress;
        schoolPhoto = photo;
        message = cachedMessage;
        totalStudents = cachedTotalStudents;
        presentStudentFN = cachedPresentFn;
        presentStudentAN = cachedPresentAn;
        classIds = cachedClassIds;
        classes = cachedClassesData;
        _isLoading =
            false; // Hide initial loading spinner now that UI can display cached data
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); // Hide spinner on error too
      }
    }
  }

  Future<void> fetchClasses() async {
    try {
      final fetched = await TeacherApiServices.fetchClassData(widget.schoolId);
      fetched.sort((a, b) {
        final classCompare = a['class'].compareTo(b['class']);
        return classCompare != 0
            ? classCompare
            : a['section'].compareTo(b['section']);
      });
      if (!mounted) return;

      // Cache classes data to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('classes', jsonEncode(fetched));

      setState(() => classes = fetched);
    } catch (e) {
      return;
    }
  }

  Future<void> fetchAttendanceStatusForAll() async {
    try {
      final String schoolId = widget.schoolId;
      final String formattedDate = formattedCurrentDate;
      final List<Future<void>> futures = [];

      for (var cls in classes) {
        final classId = cls['id'].toString();

        futures.add(
          ApiService.checkAttendanceStatusSession(
                schoolId,
                classId,
                formattedDate,
                'FN',
              )
              .then((result) {
                canTakeAttendanceFn[classId] = (result == false);
              })
              .catchError((e) {
                canTakeAttendanceFn[classId] = true;
              }),
        );

        futures.add(
          ApiService.checkAttendanceStatusSession(
                schoolId,
                classId,
                formattedDate,
                'AN',
              )
              .then((result) {
                canTakeAttendanceAn[classId] = (result == false);
              })
              .catchError((e) {
                canTakeAttendanceAn[classId] = true;
              }),
        );
      }

      await Future.wait(futures);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      return;
    }
  }

  Future<void> _checkBlocked(int schoolId) async {
    try {
      final result = await AdministratorApiService.isSchoolBlocked(schoolId);

      if (!mounted) return;
      setState(() {
        isBlocked = result['isBlocked'] ?? false;
        reason = result['reason'];
      });

      if (isBlocked && mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('School Blocked'),
                content: Text(reason ?? "This school is blocked."),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      setState(() => isBlocked = false);
    }
  }

  Future<void> _loadStaffData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.username,
        schoolId: int.tryParse(widget.schoolId) ?? 0,
      );

      if (data == null) {
        throw Exception('Staff data is null for ${widget.username}');
      }

      await prefs.setString('schoolId', widget.schoolId);
      await prefs.setString('staffName', '${data['name']}');
      await prefs.setString('class_ids', '${data['class_ids']}');
      await prefs.setString('staffUsername', widget.username);
      await prefs.setString('staffData', jsonEncode(data));

      final nameStr = '${data['name']}';
      if (nameStr.isEmpty || nameStr == 'null') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => EditProfileScreen(
                  username: widget.username,
                  submit: () => _loadStaffData(),
                  schoolId: int.tryParse(widget.schoolId) ?? 0,
                ),
          ),
        );
        return;
      }

      if (data['photo'] != null && data['photo'] is Map) {
        final photoBytes = Uint8List.fromList(
          List<int>.from(data['photo'].values),
        );
        final base64String = base64Encode(photoBytes);
        await prefs.setString('staffPhoto', base64String);
      } else {
        await prefs.remove('staffPhoto');
      }

      await fetchSchoolInfo(data);

      if (!mounted) return;

      final schoolId = '${data['school_id']}';

      // Parallel fetches: latest message + attendance summaries
      final results = await Future.wait([
        AdminApiService.fetchLatestMessageRole(schoolId, 'staff'),
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

      final String mes = results[0] as String;

      final c = await AdminApiService.countStudentUsernames(schoolId);
      final studentFn = await ApiService.fetchTodayStudentAttendance(
        currentDate,
        'fn',
        schoolId,
      );
      final studentAn = await ApiService.fetchTodayStudentAttendance(
        currentDate,
        'an',
        schoolId,
      );

      final presentStFn = studentFn.values.where((s) => s == 'P').length;
      final presentSAn = studentAn.values.where((s) => s == 'P').length;
      await prefs.setString('latestMessage', mes);
      await prefs.setInt('totalStudents', int.tryParse(c.toString()) ?? 0);
      await prefs.setInt('presentStudentFN', presentStFn);
      await prefs.setInt('presentStudentAN', presentSAn);

      final List<dynamic> parsedClassIds = [];

      if (!mounted) return;
      setState(() {
        staff = data;
        classIds = parsedClassIds;
        message = mes;
        totalStudents = int.tryParse(c.toString()) ?? 0;
        presentStudentFN = presentStFn;
        presentStudentAN = presentSAn;
      });

      await fetchClasses();
      await fetchAttendanceStatusForAll();
    } catch (e) {
      return;
    }
  }

  Future<bool> onWillPop() async {
    return false;
  }

  Future<void> fetchSchoolInfo(dynamic staffData) async {
    try {
      final fetchedSchoolData = await ApiService.fetchSchoolData(
        '${staffData['school_id']}',
      );
      if (fetchedSchoolData.isEmpty) {
        throw Exception('fetchSchoolData returned empty list');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('schoolName', '${fetchedSchoolData[0]['name']}');
      await prefs.setString(
        'schoolAddress',
        '${fetchedSchoolData[0]['address']}',
      );
      await prefs.setString('schoolPhoto', '${fetchedSchoolData[0]['photo']}');

      final fetchedName = fetchedSchoolData[0]['name'] ?? '';
      final fetchedAddress = fetchedSchoolData[0]['address'] ?? '';

      Image? photo;
      try {
        final encoded = fetchedSchoolData[0]['photo'];
        if (encoded != null && encoded is String && encoded.isNotEmpty) {
          Uint8List imageBytes = base64Decode(encoded);
          photo = Image.memory(imageBytes, gaplessPlayback: true);
        }
      } catch (_) {
        photo = null;
      }

      if (!mounted) return;
      setState(() {
        schoolName = fetchedName;
        schoolAddress = fetchedAddress;
        schoolPhoto = photo;
      });
    } catch (e) {
      return;
    }
  }

  Uint8List _extractPhotoOrEmpty(dynamic photoData) {
    if (photoData != null && photoData is Map) {
      return Uint8List.fromList(List<int>.from(photoData.values));
    }
    return Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final isMobile = screenWidth < 500;
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
    final mobile = staff['mobile'] ?? 'Staff';

    final Uint8List photoBytes = _extractPhotoOrEmpty(staff['photo']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: MobileAppbar(
            username: widget.username,
            schoolId: widget.schoolId.toString(),
            title: 'Staff Dashboard',
            enableDrawer: true,
            enableBack: false,
            onBack: safeExit,
          ),
        ),
        drawer: MobileDrawer(
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
        body: StaffDashboardMobile(
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
          attendanceStatusMapFn: canTakeAttendanceFn,
          attendanceStatusMapAn: canTakeAttendanceAn,
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
      ),
    );
  }
}
