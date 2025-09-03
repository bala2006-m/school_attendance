import 'package:flutter/material.dart';

import '../../Appbar/student_appbar_desktop.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../student_dashboard.dart';

class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
  });
  final String username;
  final String schoolId;
  final String classId;

  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Student Attendance',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 0;
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
                : const StudentAppbarDesktop(title: 'Student Attendance'),
      ),
    );
  }
}
