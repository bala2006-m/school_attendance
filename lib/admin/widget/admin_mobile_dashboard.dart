import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/build_home_page.dart';
import '../pages/admin_management.dart';
import '../pages/admin_student.dart';

class AdminMobileDashboard extends StatefulWidget {
  const AdminMobileDashboard({
    super.key,
    required this.schoolId,
    required this.username,
    required this.adminName,
    required this.adminDesignation,
    this.adminPhoto,
    required this.schoolName,
    required this.schoolAddress,
    required this.totalStudents,
    required this.totalStaff,
    required this.presentStaffFN,
    required this.presentStaffAN,
    required this.presentStudentFN,
    required this.presentStudentAN,
    required this.selectedIndex,
    required this.attendanceStatusMapFn,
    required this.message,
    required this.attendanceStatusMapAn,
    this.schoolPhoto,
  });

  final String schoolId;
  final String username;
  final String adminName;
  final String adminDesignation;
  final Image? adminPhoto;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final int totalStudents;
  final int totalStaff;
  final int presentStaffFN;
  final int presentStaffAN;
  final int presentStudentFN;
  final int presentStudentAN;
  final int selectedIndex;
  final String message;
  final Map<String, bool> attendanceStatusMapFn;
  final Map<String, bool> attendanceStatusMapAn;

  @override
  State<AdminMobileDashboard> createState() => _AdminMobileDashboardState();
}

class _AdminMobileDashboardState extends State<AdminMobileDashboard> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role') ?? '';
    if (role == 'admin') {
      _initNotifications();
      _startCheckTimer();
    }
  }

  void _initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Reminders for attendance submission',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  void _startCheckTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = TimeOfDay.now();

      // 12:30 check FN
      if (now.hour == 12 && now.minute == 30) {
        if (widget.attendanceStatusMapFn.values.contains(false)) {
          _showNotification(
            "FN Attendance Pending",
            "Some classes have not marked FN attendance.",
          );
        }
      }

      // 3:30 check AN
      if (now.hour == 15 && now.minute == 30) {
        if (widget.attendanceStatusMapAn.values.contains(false)) {
          _showNotification(
            "AN Attendance Pending",
            "Some classes have not marked AN attendance.",
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.selectedIndex,
      children: [
        AdminStudent(
          school_id: widget.schoolId,
          adminUsername: widget.username,
          adminName: widget.adminName,
          adminDesignation: widget.adminDesignation,
          adminPhoto: widget.adminPhoto,
          schoolName: widget.schoolName,
          schoolAddress: widget.schoolAddress,
        ),
        BuildHomePage.buildHomePage(
          message: widget.message,
          context: context,
          totalStudents: '${widget.totalStudents}',
          presentStudentFN: '${widget.presentStudentFN}',
          totalStaff: '${widget.totalStaff}',
          presentStaffFN: '${widget.presentStaffFN}',
          presentStudentAN: '${widget.presentStudentAN}',
          presentStaffAN: '${widget.presentStaffAN}',
          adminName: widget.adminName,
          adminDesignation: widget.adminDesignation,
          adminPhoto: widget.adminPhoto,
          schoolName: widget.schoolName,
          schoolAddress: widget.schoolAddress,
          schoolPhoto: widget.schoolPhoto,
          attendanceStatusMapFn: widget.attendanceStatusMapFn,
          attendanceStatusMapAn: widget.attendanceStatusMapAn,
        ),
        AdminManagement(
          adminUsername: widget.username,
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          schoolAddress: widget.schoolAddress,
        ),
      ],
    );
  }
}
