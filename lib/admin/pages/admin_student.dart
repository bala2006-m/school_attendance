import 'package:flutter/material.dart';
import 'package:school_attendance/admin/pages/staff_absentees.dart';
import 'package:school_attendance/admin/pages/staff_attendance.dart';
import 'package:school_attendance/admin/pages/student_absentees.dart';
import 'package:school_attendance/admin/pages/student_report_between_days.dart';
import 'package:school_attendance/admin/pages/view_staff_attendance.dart';
import 'package:school_attendance/admin/pages/view_student_attendance.dart';

import '../components/build_profile_card_desktop.dart';
import '../components/build_profile_card_mobile.dart';
import 'modify_student_attendance.dart';
import 'monthly_attendance.dart';

class AdminStudent extends StatefulWidget {
  final String school_id;
  final String adminUsername;
  final String adminName;
  final String adminDesignation;
  final Image? adminPhoto;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;

  const AdminStudent({
    super.key,
    required this.school_id,
    required this.adminUsername,
    required this.adminName,
    required this.adminDesignation,
    this.adminPhoto,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });

  @override
  State<AdminStudent> createState() => _AdminStudentState();
}

class _AdminStudentState extends State<AdminStudent> {
  @override
  Widget build(BuildContext context) {
    return buildMainUI(context);
  }

  Widget buildMainUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.15;

    final profileCard =
        screenWidth > 600
            ? BuildProfileCardDesktop.buildProfileCardDesktop(
              adminName: widget.adminName,
              adminDesignation: widget.adminDesignation,
              adminPhoto: widget.adminPhoto,
              schoolAddress: widget.schoolAddress,
              schoolName: widget.schoolName,
            )
            : BuildProfileCard(
              schoolPhoto: widget.schoolPhoto,
              schoolAddress: widget.schoolAddress,
              schoolName: widget.schoolName,
            );

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.004),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileCard,
              SizedBox(height: screenHeight * 0.03),
              ..._buildDashboardButtons(screenWidth, buttonHeight),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardButtons(double screenWidth, double buttonHeight) {
    return [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black26, width: 2),
          boxShadow: [BoxShadow(color: Colors.transparent.withOpacity(0.02))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Staff',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade900,
                      size: 50,
                    ),
                  ],
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'Mark Attendance',
                    Icons.people,
                    StaffAttendance(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.white,
                    Colors.black,
                    Colors.blue,
                    Colors.blue,
                  ),
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'View Absentees',
                    Icons.people_outline,
                    StaffAbsentees(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.white,
                    Colors.black,
                    Colors.blue,
                    Colors.blue,
                  ),
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'View Attendance',
                    Icons.people_outline_outlined,
                    ViewStaffAttendance(
                      school_id: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.white,
                    Colors.black,
                    Colors.blue,
                    Colors.blue,
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      SizedBox(height: 30),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black26, width: 2),
          boxShadow: [BoxShadow(color: Colors.transparent.withOpacity(0.02))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Student',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade900,
                      size: 50,
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'Update Attendance',
                    Icons.mode,
                    ModifyStudentAttendance(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.cyan,
                    Colors.black,
                    Colors.cyan.shade50,
                    Colors.white,
                  ),

                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'View Absentees',
                    Icons.person_remove,
                    StudentAbsent(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.cyan,
                    Colors.black,
                    Colors.cyan.shade50,
                    Colors.white,
                  ),
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'View Attendance',
                    Icons.person_search,
                    ClassList(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.cyan,
                    Colors.black,
                    Colors.cyan.shade50,
                    Colors.white,
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'Monthly Attendance',
                    Icons.calendar_month,
                    MonthlyAttendance(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.cyan,
                    Colors.black,
                    Colors.cyan.shade50,
                    Colors.white,
                  ),
                  buildButtons(
                    context,
                    screenWidth,
                    buttonHeight,
                    'Periodical Report',
                    Icons.report,
                    StudentReportBetweenDays(
                      schoolId: widget.school_id,
                      username: widget.adminUsername,
                    ),
                    Colors.cyan,
                    Colors.black,
                    Colors.cyan.shade50,
                    Colors.white,
                  ),
                ],
              ),
              // SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ];
  }

  Widget buildButtons(
    BuildContext context,
    double screenWidth,
    double buttonHeight,
    String title,
    IconData icon,
    Widget route,
    Color backgroundColor,
    Color textColor,
    Color borderColor,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.22,
          minWidth: screenWidth / 4.5,
          maxWidth: screenWidth / 4.5,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                  shadowColor: Colors.grey,
                  minimumSize: Size(screenWidth / 4.5, buttonHeight * 0.6),
                  maximumSize: Size(screenWidth / 4.5, buttonHeight * 0.65),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => route),
                  );
                },
                child: Icon(icon, size: 40, color: iconColor),
              ),
              SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
