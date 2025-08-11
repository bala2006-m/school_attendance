import 'dart:core';

import 'package:flutter/material.dart';

import '../../admin/components/desktop_stats.dart';
import '../../admin/components/message_box.dart';
import '../components/build_profile_card_mobile.dart';
import '../pages/view_staff_attendance.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.message,
    required this.totalStudents,
    required this.presentStudentFN,
    required this.presentStudentAN,
    required this.schoolId,
    required this.username,
    required this.classIds,
  });
  final String message;
  final String totalStudents;
  final String presentStudentFN;
  final String presentStudentAN;
  final String schoolId;
  final String username;
  final List<dynamic> classIds;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            children: [
              BuildProfileCard(),
              SizedBox(height: 10),
              MessageBox(message: widget.message),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
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
                              'View Your Attendance',
                              Icons.insert_chart,
                              ViewStaffAttendance(
                                username: widget.username,
                                schoolId: widget.schoolId,
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
              ),
              SizedBox(height: 10),
              DesktopStats(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                total: widget.totalStudents,
                name: 'Students',
                presentFN: widget.presentStudentFN,
                presentAN: widget.presentStudentAN,
                isClassShown: true,
                classIds: widget.classIds,
                schoolId: widget.schoolId,
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
