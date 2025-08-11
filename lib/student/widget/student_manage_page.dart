import 'package:flutter/material.dart';

import '../components/build_profile_card_mobile.dart';
import '../pages/holiday_page.dart';

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
  });
  final String schoolId;
  final String classId;
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String message;
  final Image? schoolPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: BuildProfileCard(
              schoolAddress: schoolAddress,
              schoolName: schoolName,
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildElevatedButton(
                        context,
                        "Holidays",
                        HolidayPage(
                          schoolId: schoolId,
                          classId: classId,
                          username: username,
                        ),
                        Icons.view_day,
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
