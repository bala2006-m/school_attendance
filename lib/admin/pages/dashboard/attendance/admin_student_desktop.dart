import 'package:flutter/material.dart';
import 'package:school_attendance/admin/pages/staff_attendance/staff_absentees.dart';
import 'package:school_attendance/admin/pages/staff_attendance/staff_attendance.dart';
import 'package:school_attendance/admin/pages/staff_attendance/view_staff_attendance.dart';
import 'package:school_attendance/admin/pages/student_attendance/periodicalReport/student_report_between_days.dart';
import 'package:school_attendance/admin/pages/student_attendance/viewAbsentees/student_absentees.dart';
import 'package:school_attendance/admin/pages/student_attendance/viewAttendance/view_student_attendance.dart';

import '../../../components/build_profile_card_mobile.dart';
import '../../student_attendance/mark_old_attendance/mark_old_attendance.dart';
import '../../student_attendance/monthelyAttendance/monthly_attendance.dart';
import '../../student_attendance/update_attendance/modify_student_attendance.dart';

class AdminStudentDesktop extends StatefulWidget {
  final String schoolId;
  final String adminUsername;
  final String adminName;
  final String adminDesignation;
  final Image? adminPhoto;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;

  const AdminStudentDesktop({
    super.key,
    required this.schoolId,
    required this.adminUsername,
    required this.adminName,
    required this.adminDesignation,
    this.adminPhoto,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });

  @override
  State<AdminStudentDesktop> createState() => _AdminStudentDesktopState();
}

class _AdminStudentDesktopState extends State<AdminStudentDesktop> {
  ScrollController _scrollController = ScrollController();
  static double savedScrollOffset = 0;
  static int? savedClickedButtonIndex;
  int? _clickedButtonIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: savedScrollOffset,
    );
    _clickedButtonIndex = savedClickedButtonIndex;
  }

  @override
  void dispose() {
    // Save scroll position only if attached
    if (_scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
    }
    savedClickedButtonIndex = _clickedButtonIndex;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildMainUI(context);
  }

  Widget buildMainUI(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final profileCard = BuildProfileCard(
      schoolPhoto: widget.schoolPhoto,
      schoolAddress: widget.schoolAddress,
      schoolName: widget.schoolName,
    );

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        controller: _scrollController,

        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileCard,
              SizedBox(height: screenHeight * 0.03),
              buildStaffSection(),
              SizedBox(height: 30),
              buildStudentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStaffSection() {
    return buildSectionContainer(
      title: 'Staff',
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildElevatedButton(
                buttonIndex: 0,
                context,
                'Mark Attendance',
                StaffAttendance(
                  schoolId: widget.schoolId,
                  username: widget.adminUsername,
                ),
                Icons.people,
              ),
              buildElevatedButton(
                buttonIndex: 1,
                context,
                'View Absentees',
                StaffAbsentees(
                  schoolId: widget.schoolId,
                  username: widget.adminUsername,
                ),
                Icons.people_outline,
              ),
              buildElevatedButton(
                buttonIndex: 2,
                context,
                'View Attendance',
                ViewStaffAttendance(
                  schoolId: widget.schoolId,
                  username: widget.adminUsername,
                ),
                Icons.people_outline_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStudentSection() {
    return buildSectionContainer(
      title: 'Student',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildElevatedButton(
              buttonIndex: 3,
              context,
              'Update Attendance',
              ModifyStudentAttendance(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.mode,
            ),
            buildElevatedButton(
              buttonIndex: 4,
              context,
              'View Absentees',
              StudentAbsent(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.person_remove,
            ),
            buildElevatedButton(
              buttonIndex: 5,
              context,
              'View Attendance',
              ClassList(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.person_search,
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildElevatedButton(
              buttonIndex: 6,
              context,
              'Monthly Attendance',
              MonthlyAttendance(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.calendar_month,
            ),
            buildElevatedButton(
              buttonIndex: 7,
              context,
              'Periodical Report',
              StudentReportBetweenDays(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.report,
            ),
            buildElevatedButton(
              buttonIndex: 8,
              context,
              'Mark Old Attendance',
              MarkOldAttendance(
                schoolId: widget.schoolId,
                username: widget.adminUsername,
              ),
              Icons.mode_edit_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black26, width: 2),
        boxShadow: [BoxShadow(color: Colors.transparent)],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
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
                Column(mainAxisSize: MainAxisSize.min, children: children),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildElevatedButton(
    BuildContext context,
    String text,
    Widget page,
    IconData icon, {
    required int buttonIndex,
  }) {
    bool isClicked = _clickedButtonIndex == buttonIndex;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.22,
          minWidth:
              MediaQuery.of(context).size.width > 638
                  ? MediaQuery.of(context).size.width / 6.1
                  : MediaQuery.of(context).size.width > 510
                  ? MediaQuery.of(context).size.width / 7
                  : MediaQuery.of(context).size.width / 7.5,
          maxWidth:
              MediaQuery.of(context).size.width > 638
                  ? MediaQuery.of(context).size.width / 6.1
                  : MediaQuery.of(context).size.width > 510
                  ? MediaQuery.of(context).size.width / 7
                  : MediaQuery.of(context).size.width / 7.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isClicked ? Colors.cyan.shade800 : Colors.cyan,
                minimumSize: Size(
                  MediaQuery.of(context).size.width / 4.5,
                  MediaQuery.of(context).size.height * 0.09,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: () {
                setState(() {
                  _clickedButtonIndex = buttonIndex;
                });
                savedScrollOffset = _scrollController.offset;
                savedClickedButtonIndex = buttonIndex;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
              },
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
