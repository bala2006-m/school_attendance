import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/student/services/student_api_services.dart';
import 'package:school_attendance/student/widget/student_timetable_desktop.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../widget/student_timetable_mobile.dart';

class TimeTablePage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String username;

  const TimeTablePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
  });

  @override
  State<TimeTablePage> createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {
  Map<String, List<String>> timetable = {};
  bool isLoading = true;
  String? error;

  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> periodHeaders = [
    '1\n(FN)',
    '2\n(FN)',
    '3\n(FN)',
    '4\n(FN)',
    '5\n(AN)',
    '6\n(AN)',
    '7\n(AN)',
    '8\n(AN)',
  ];

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    try {
      final data = await StudentApiServices.fetchTimetable(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      setState(() {
        timetable = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Weekly TimeTable',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 1;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : const StudentAppbarDesktop(title: 'Weekly TimeTable'),
      ),
      body:
          isLoading
              ? Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : error != null
              ? Center(child: Text('Error: $error'))
              : isDesktop
              ? StudentTimetableDesktop(
                days: days,
                periodHeaders: periodHeaders,
                timetable: timetable,
              )
              : StudentTimetableMobile(
                days: days,
                periodHeaders: periodHeaders,
                timetable: timetable,
              ),
    );
  }
}
