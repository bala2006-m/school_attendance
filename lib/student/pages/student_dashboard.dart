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

  // Track if data loaded from cache to avoid repeated fetches
  bool _dataLoadedFromCache = false;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _checkBlocked(widget.schoolId);
    await _loadCachedData();
    if (!_dataLoadedFromCache) {
      await _loadStudentData();
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
          barrierDismissible: false,
        );
      }
    } catch (e) {
      debugPrint("Error checking block status: $e");
      setState(() {
        isBlocked = false;
      });
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedStudentName = prefs.getString('studentName');
    final cachedSchoolName = prefs.getString('schoolName');

    // If critical data found in cache, load it and set state
    if (cachedStudentName != null && cachedSchoolName != null) {
      setState(() {
        _dataLoadedFromCache = true;

        studentData = {
          'name': cachedStudentName,
          'school_id': prefs.getString('schoolId'),
          'photo': null, // Photo can be loaded async if needed
          // Could add more fields if cached
        };

        schoolName = cachedSchoolName;
        schoolAddress = prefs.getString('schoolAddress') ?? '';
        message = prefs.getString('latestMessage') ?? '';
        _isLoading = false;
      });

      // Also load cached school photo in background (optional)
      _loadCachedSchoolPhoto(prefs);
    }
  }

  Future<void> _loadCachedSchoolPhoto(SharedPreferences prefs) async {
    final schoolPhotoString = prefs.getString('schoolPhoto');
    if (schoolPhotoString != null && schoolPhotoString.isNotEmpty) {
      try {
        // Assuming you store photo bytes as base64 string, convert here if needed
        // For now, skipping complex photo cache decode
      } catch (_) {
        // Ignore photo errors
      }
    }
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    try {
      final data = await StudentApiServices.fetchStudentDataUsername(
        username: widget.username,
        schoolId: widget.schoolId,
      );

      if (data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Cache critical data
      await prefs.setString('schoolId', '${data['school_id']}');
      await prefs.setString('studentName', '${data['name']}');

      final photoData = data['photo'];
      Uint8List photoBytes = Uint8List(0);
      if (photoData != 'null' && photoData is Map) {
        photoBytes = Uint8List.fromList(
          List<int>.from(photoData.values.toList()),
        );
      }
      // Store photo as string if needed, or skip caching binary data here for simplicity

      await prefs.setString('studentPhoto', '$photoBytes');

      setState(() {
        studentData = data;
      });

      await _loadSchoolAndClassData();
    } catch (e) {
      debugPrint("Error loading student data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSchoolAndClassData() async {
    final prefs = await SharedPreferences.getInstance();

    if (studentData == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
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
      await prefs.setString('latestMessage', mes);

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
      debugPrint("Error loading school/class data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

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
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
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
    final String community = studentData?['community'] ?? '';
    final String fatherName = studentData?['father_name'] ?? '';
    final String DOB = studentData?['DOB'] ?? '';
    final String route = studentData?['route'] ?? '';
    final Uint8List photoBytes =
        (photoData != null && photoData is Map)
            ? Uint8List.fromList(List<int>.from(photoData.values.toList()))
            : Uint8List(0);

    final schoolNameLocal = schoolData?['name'] ?? 'Unknown School';
    final schoolAddressLocal = schoolData?['address'] ?? '';
    final className =
        '${classData?['class'] ?? 'Unknown Class'} ${classData?['section'] ?? ''}';
    final photoData1 = schoolData?['photo'];
    final Uint8List photoBytes1 =
        (photoData1 != null && photoData1 is Map)
            ? Uint8List.fromList(List<int>.from(photoData1.values.toList()))
            : Uint8List(0);
    final schoolPhoto1 = Image.memory(photoBytes1);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
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
                  schoolName: schoolNameLocal,
                  className: className,
                  community: community,
                  father_name: fatherName,
                  DOB: DOB,
                  route: route,
                  gender: gender,
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
                schoolName: schoolNameLocal,
                className: className,
                message: message,
                schoolAddress: schoolAddressLocal,
                schoolPhoto: schoolPhoto1,
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
                schoolName: schoolNameLocal,
                className: className,
                selectedIndex: selectedIndex,
                schoolAddress: schoolAddressLocal,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined, size: 30),
            label: 'Homework',
          ),
        ],
      ),
    );
  }
}
