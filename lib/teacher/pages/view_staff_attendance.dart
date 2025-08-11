import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';

import '../../admin/widget/attendance_screen.dart';
import '../../services/api_service.dart';
import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';

class ViewStaffAttendance extends StatefulWidget {
  const ViewStaffAttendance({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<ViewStaffAttendance> createState() => _ViewStaffAttendanceState();
}

class _ViewStaffAttendanceState extends State<ViewStaffAttendance> {
  bool isLoading = false;
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> holidayList = [];
  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedAttendance = await ApiService.fetchStaffAttendanceByUsername(
        widget.username,
        widget.schoolId,
      );
      final fetchedHolidays = await ApiService.fetchHolidays(widget.schoolId);

      setState(() {
        attendance = fetchedAttendance;
        holidayList = List<Map<String, dynamic>>.from(fetchedHolidays);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch attendance')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StaffDashboard(username: widget.username),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? MobileAppbar(
                    title: 'View Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      StaffDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  StaffDashboard(username: widget.username),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'View Attendance'),
        ),
        body: Column(
          children: [
            AttendanceScreen(
              schoolId: widget.schoolId,
              holidayList: holidayList,
              data: attendance,
              title: '',
            ),
          ],
        ),
      ),
    );
  }
}
