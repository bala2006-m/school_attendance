import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';

import '../../admin/widget/attendance_screen.dart';
import '../../services/api_service.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch attendance')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StaffDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: MobileAppbar(
            username: widget.username,
            schoolId: widget.schoolId.toString(),
            title: 'View Attendance',
            enableDrawer: false,
            enableBack: true,
            onBack: () {
              StaffDashboardState.selectedIndex = 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => StaffDashboard(
                        username: widget.username,
                        schoolId: widget.schoolId,
                      ),
                ),
              );
            },
          ),
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
