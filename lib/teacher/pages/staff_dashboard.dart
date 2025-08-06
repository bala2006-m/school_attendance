import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:school_attendance/teacher/widget/mobile_drawer.dart';
import 'package:school_attendance/teacher/widget/staff_dashboard_mobile.dart';

import '../widget/staff_dashboard_desktop.dart';

class StaffDashboard extends StatefulWidget {
  final String username;
  const StaffDashboard({super.key, required this.username});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic>? staff;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final data = await TeacherApiServices.fetchStaffDataUsername(
      widget.username,
    );

    if (!mounted) return;

    setState(() {
      staff = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (staff == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    final name = staff?['name'] ?? 'Staff';
    final schoolId = staff?['school_id'];

    return Scaffold(
      drawer:
          MediaQuery.sizeOf(context).width > 600
              ? null
              : MobileDrawer(name: name, username: widget.username),

      appBar:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopAppbar(title: 'Staff Dashboard')
              : MobileAppbar(title: 'Staff Dashboard'),
      body:
          MediaQuery.sizeOf(context).width > 600
              ? StaffDashboardDesktop(
                name: name,
                schoolId: '$schoolId',
                username: widget.username,
              )
              : StaffDashboardMobile(schoolId: '$schoolId'),
    );
  }
}
