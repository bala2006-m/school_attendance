import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_attendance/administrator/pages/dashboard.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/pages/admin_dashboard.dart';
import 'login_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.manageExternalStorage.isGranted;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('rememberMe') ?? false;
  String role = prefs.getString('role') ?? '';
  String username = prefs.getString('username') ?? '';
  String? schoolId = '';
  if (role == 'administrator') {
    schoolId = prefs.getInt('schoolId').toString() ?? '';
  } else {
    schoolId = prefs.getString('schoolId').toString() ?? '';
  }
  int id = int.tryParse(schoolId.toString()) ?? 0;
  // String schoolName = prefs.getString('schoolName') ?? '';
  // String schoolAddress = prefs.getString('schoolAddress') ?? '';
  // Image? adminPhoto = prefs.getString('adminPhoto') as Image;
  Widget startPage;

  if (isLoggedIn) {
    if (role == 'student') {
      startPage = StudentDashboard(username: username, schoolId: id);
    } else if (role == 'staff') {
      startPage = StaffDashboard(
        username: username,
        schoolId: schoolId.toString(),
      );
    } else if (role == 'admin') {
      startPage = AdminDashboard(
        username: username,
        schoolId: schoolId.toString(),
      );
    } else if (role == 'administrator') {
      startPage = AdministratorDashboard(userName: username);
    } else {
      startPage = const LoginPage();
    }
  } else {
    startPage = const LoginPage();
  }
  // Android init
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS init
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

  // Combine
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  // Initialize
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  runApp(MyApp(startPage: startPage));
}

class MyApp extends StatelessWidget {
  final Widget startPage;
  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: startPage,
      //home: StaffDashboard(username: '2210801'),
      // home: const AdminDashboard(schoolId: '1'),
    );
  }
}
