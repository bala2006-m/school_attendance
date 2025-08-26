import 'package:flutter/material.dart';

import '..//pages/monthly_attendance.dart';
import '../components/build_profile_card_mobile.dart';
import '../pages/class_list.dart';
import '../pages/post_leave_request.dart';
import '../pages/student_absentees.dart';
import '../pages/student_report_between_days.dart';
import '../pages/view_staff_attendance.dart';
import '../pages/view_student_attendance.dart';

class AttendancePage extends StatelessWidget {
  final String schoolId;
  final String username;
  final List<dynamic> classIds;
  final String schoolName;
  final String schoolAddress;
  final Image? schoolPhoto;
  const AttendancePage({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classIds,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.15;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BuildProfileCard(
                schoolName: schoolName,
                schoolAddress: schoolAddress,
                schoolPhoto: schoolPhoto,
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black26, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.transparent.withOpacity(0.02)),
                  ],
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
                            'Mark\nAttendance',
                            Icons.people,
                            ClassList(schoolId: schoolId, username: username),
                            Colors.white,
                            Colors.black,
                            Colors.blue,
                            Colors.blue,
                          ),
                          buildButtons(
                            context,
                            screenWidth,
                            buttonHeight,
                            'View\nAbsentees',
                            Icons.people_outline_sharp,
                            StudentAbsent(
                              schoolId: schoolId,
                              username: username,
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
                            'View\nAttendance',
                            Icons.person_search,
                            StudentAttendanceClasses(
                              schoolId: schoolId,
                              username: username,
                            ),
                            Colors.white,
                            Colors.black,
                            Colors.blue,
                            Colors.blue,
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
                            'Monthly\nAttendance',
                            Icons.calendar_month,
                            MonthlyAttendance(
                              schoolId: schoolId,
                              username: username,
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
                            'Periodical\nReport',
                            Icons.info,
                            StudentReportBetweenDays(
                              schoolId: schoolId,
                              username: username,
                            ),
                            Colors.white,
                            Colors.black,
                            Colors.blue,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black26, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.transparent.withOpacity(0.02)),
                  ],
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
                              'Myself',
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
                            'View Your\nAttendance',
                            Icons.insert_chart,
                            ViewStaffAttendance(
                              username: username,
                              schoolId: schoolId,
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
                            'Apply Leave\nRequest',
                            Icons.remove_done,
                            PostLeaveRequest(
                              username: username,
                              schoolId: schoolId,
                            ),
                            Colors.white,
                            Colors.black,
                            Colors.blue,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
