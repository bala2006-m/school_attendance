import 'package:flutter/material.dart';
import 'package:school_attendance/student/pages/bus_fees/bus_fees.dart';

import '../components/build_profile_card_mobile.dart';
import '../pages/events.dart';
import '../pages/exam_marks/student_exam_marks.dart';
import '../pages/homework/student_homework_page.dart';
import '../pages/student_fees/student_fees_screen.dart';

class StudentManagePage extends StatelessWidget {
  const StudentManagePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.message,
    this.schoolPhoto,
    required this.studentRoute,
    required this.schoolData,
  });
  final String schoolId;
  final String classId;
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String message;
  final String studentRoute;
  final Image? schoolPhoto;
  final Map<String, dynamic>? schoolData;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: BuildProfileCard(),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     buildElevatedButton(
                //       context,
                //       "Holidays",
                //       HolidayPage(
                //         schoolId: schoolId,
                //         classId: classId,
                //         username: username,
                //       ),
                //       Icons.view_day,
                //     ),
                //     const SizedBox(height: 30),
                //   ],
                // ),
                SizedBox(height: 10),
                schoolData?['student_access']['events'] == true ||
                        schoolData?['student_access']['viewHomework'] == true
                    ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: [BoxShadow(color: Colors.transparent)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  Text(
                                    'Views',
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
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                schoolData?['student_access'] == null
                                    ? buildElevatedButton(
                                      context,
                                      "View\nHomework",
                                      StudentHomeworkPage(
                                        username: username,
                                        schoolId: schoolId,
                                        classId: classId,
                                      ),
                                      Icons.home_work_outlined,
                                    )
                                    : schoolData?['student_access']['viewHomework'] ==
                                        true
                                    ? buildElevatedButton(
                                      context,
                                      "View\nHomework",
                                      StudentHomeworkPage(
                                        username: username,
                                        schoolId: schoolId,
                                        classId: classId,
                                      ),
                                      Icons.home_work_outlined,
                                    )
                                    : SizedBox(),

                                schoolData?['student_access'] == null
                                    ? buildElevatedButton(
                                      context,
                                      "Events",
                                      Events(
                                        username: username,
                                        schoolId: schoolId,
                                        classId: classId,
                                      ),
                                      Icons.event,
                                    )
                                    : schoolData?['student_access']['events'] ==
                                        true
                                    ? buildElevatedButton(
                                      context,
                                      "Events",
                                      Events(
                                        username: username,
                                        schoolId: schoolId,
                                        classId: classId,
                                      ),
                                      Icons.event,
                                    )
                                    : SizedBox(),

                                // buildElevatedButton(
                                //   context,
                                //   "Location",
                                //   LocationMapPage(),
                                //   Icons.location_pin,
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    : SizedBox(),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26, width: 2),
                    boxShadow: [BoxShadow(color: Colors.transparent)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Text(
                                'Payments',
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
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildElevatedButton(
                              context,
                              "Term Fees",
                              StudentFeesScreen(
                                username: username,
                                schoolId: int.parse(schoolId),
                                classId: int.parse(classId),
                              ),
                              Icons.payments,
                            ),
                            if (studentRoute.isNotEmpty &&
                                studentRoute != 'null')
                              buildElevatedButton(
                                context,

                                "Bus Fees",
                                BusFees(
                                  username: username,
                                  schoolId: int.parse(schoolId),
                                  classId: int.parse(classId),
                                ),
                                Icons.bus_alert,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26, width: 2),
                    boxShadow: [BoxShadow(color: Colors.transparent)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Text(
                                'Reports',
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
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildElevatedButton(
                              context,
                              "Exams",
                              StudentExamMarks(
                                username: username,
                                schoolId: schoolId,
                                classId: classId,
                              ),
                              Icons.collections_bookmark_outlined,
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
        ],
      ),
    );
  }
}

Widget buildElevatedButton(
  BuildContext context,
  String text,
  Widget page,
  IconData icon,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.22,
        minWidth: MediaQuery.of(context).size.width / 4.5,
        maxWidth: MediaQuery.of(context).size.width / 4.5,
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
                backgroundColor: Colors.cyan,
                minimumSize: Size(
                  MediaQuery.of(context).size.width / 4.5,
                  MediaQuery.of(context).size.height * 0.09,
                ),
                maximumSize: Size(
                  MediaQuery.of(context).size.width / 4.5,
                  MediaQuery.of(context).size.height * 0.09,
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                shadowColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
              },
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              textAlign: TextAlign.center,
              text,
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}
