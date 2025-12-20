import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_attendance/administrator/pages/dashboard.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'admin/pages/dashboard/admin_dashboard.dart';
import 'login_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> main() async {
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  WidgetsFlutterBinding.ensureInitialized();
  await Geolocator.isLocationServiceEnabled();
  await Permission.manageExternalStorage.isGranted;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('rememberMe') ?? false;
  String role = prefs.getString('role') ?? '';
  String username = prefs.getString('username') ?? '';
  String? schoolId = '';
  if (role == 'administrator') {
    try {
      schoolId = prefs.getInt('schoolId').toString();
    } catch (e) {
      schoolId = prefs.getString('schoolId').toString();
    }
  } else {
    try {
      schoolId = prefs.getString('schoolId').toString();
    } catch (e) {
      schoolId = prefs.getInt('schoolId').toString();
    }
  }
  int id = int.tryParse(schoolId.toString()) ?? 0;
  // String schoolName = prefs.getString('schoolName') ?? '';
  // String schoolAddress = prefs.getString('schoolAddress') ?? '';
  // Image? adminPhoto = prefs.getString('adminPhoto') as Image;
  Widget startPage;

  if (isLoggedIn) {
    if (role == 'student') {
      startPage = StudentDashboard(username: username.toString(), schoolId: id);
    } else if (role == 'staff') {
      startPage = StaffDashboard(username: username, schoolId: schoolId);
    } else if (role == 'admin') {
      startPage = AdminDashboard(
        username: username.toString(),
        schoolId: schoolId.toString(),
      );
    } else if (role == 'administrator') {
      startPage = AdministratorDashboard(userName: username.toString());
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
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
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
      title: 'Ramchin Smart School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Add more if needed
      ],
      // builder:
      //     (context, child) =>
      //         SafeArea(top: false, bottom: true, child: child ?? SizedBox()),
      home: startPage,
      //home: StaffDashboard(username: '2210801'),
      // home: const AdminDashboard(schoolId: '1'),
    );
  }
}
