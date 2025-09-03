import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../components/build_home_page.dart';
import '../pages/dashboard/attendance/admin_student.dart';
import '../pages/dashboard/manage/admin_management.dart';

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

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role') ?? '';

    if (role == 'admin') {
      await _askNotificationPermission();
      await _initNotifications();
      await _scheduleDailyNotifications();
    }
  }

  Future<void> _askNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _scheduleDailyNotifications() async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Reminders for attendance submission',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'FN Attendance Reminder',
      'Please ensure FN attendance is marked.',
      _nextInstanceOfTime(11, 40),
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      'AN Attendance Reminder',
      'Please ensure AN attendance is marked.',
      _nextInstanceOfTime(15, 30),
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // debugPrint("✅ Daily notifications scheduled.");
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // debugPrint("⏰ Scheduling notification at local: $scheduled (now: $now)");
    return scheduled;
  }

  // Future<void> _showTestNotification() async {
  //   const androidDetails = AndroidNotificationDetails(
  //     'test_channel',
  //     'Test Notifications',
  //     channelDescription: 'Channel for testing notifications',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const iosDetails = DarwinNotificationDetails();
  //   const platformDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     999,
  //     'Test Notification',
  //     'This is a test notification!',
  //     platformDetails,
  //   );
  // }

  // Future<void> _scheduleOneMinuteTestNotification() async {
  //   const androidDetails = AndroidNotificationDetails(
  //     'test_channel',
  //     'Test Notifications',
  //     channelDescription: 'Channel for testing notifications',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const iosDetails = DarwinNotificationDetails();
  //   const platformDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );
  //
  //   final scheduled = tz.TZDateTime.now(
  //     tz.local,
  //   ).add(const Duration(minutes: 1));
  //
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     1000,
  //     'Quick Test',
  //     'This notification should fire in 1 minute.',
  //     scheduled,
  //     platformDetails,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   );
  //
  //   debugPrint("⏰ Quick test scheduled for $scheduled");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.selectedIndex,
        children: [
          AdminStudent(
            schoolId: widget.schoolId,
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
      ),
    );
  }
}
