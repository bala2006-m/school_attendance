import 'package:flutter/material.dart';

import '../components/build_profile_card_mobile.dart';
import '../pages/attendance_page.dart';
import '../pages/post_leave_request.dart';

class StudentAttendancePage extends StatelessWidget {
  final String username;
  final String name;
  final String email;
  final String schoolId;
  final String classId;
  final String gender;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final String message;

  const StudentAttendancePage({
    super.key,
    required this.username,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.classId,
    required this.gender,
    this.schoolPhoto,
    required this.schoolName,
    required this.schoolAddress,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: BuildProfileCard(),
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
                padding: const EdgeInsets.all(12),
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
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildElevatedButton(
                          context,
                          "View\nAttendance",
                          AttendancePage(
                            username: username,
                            name: name,
                            schoolId: schoolId,
                            classId: classId,
                            email: email,
                            gender: gender,
                            schoolPhoto: schoolPhoto,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                            message: message,
                          ),
                          Icons.access_time_outlined,
                        ),
                        buildElevatedButton(
                          context,
                          "Apply Leave\nRequest",
                          PostLeaveRequest(
                            username: username,
                            schoolId: schoolId,
                            classId: classId,
                          ),
                          Icons.post_add,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  backgroundColor: Colors.white,
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
                child: Icon(icon, size: 40, color: Colors.blue),
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
}
