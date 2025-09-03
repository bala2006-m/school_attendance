import 'package:flutter/material.dart';
import 'package:school_attendance/administrator/pages/view_feedback.dart';

import '../pages/admin_registration.dart';
import '../pages/block_school.dart';
import '../pages/view_ticket.dart';

class ManagePage extends StatelessWidget {
  const ManagePage({
    super.key,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
  });
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
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
                            'Register',
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
                    // SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        buildElevatedButton(
                          context,
                          'Admins',
                          AdminRegistration(
                            username: username,
                            schoolId: int.parse(schoolId),
                            schoolAddress: schoolAddress,
                            schoolName: schoolName,
                          ),
                          Icons.admin_panel_settings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
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
                            'Manage',
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
                    // SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildElevatedButton(
                          context,
                          "block\nSchool",
                          // CreateTodayMessage(
                          //   schoolId: widget.schoolId,
                          //   username: widget.adminUsername,
                          // ),
                          BlockSchool(
                            username: username,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                            schoolId: schoolId,
                          ),
                          Icons.class_outlined,
                        ),
                        // const SizedBox(height: 30),
                        // buildElevatedButton(
                        //   context,
                        //   'Delete\nSchool',
                        //   AdministratorDashboard(userName: username),
                        //   Icons.admin_panel_settings,
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
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
                            'View',
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
                    // SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildElevatedButton(
                          context,
                          "Feedback",
                          // CreateTodayMessage(
                          //   schoolId: widget.schoolId,
                          //   username: widget.adminUsername,
                          // ),
                          ViewFeedback(
                            username: username,
                            schoolId: schoolId,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                          ),
                          Icons.feed,
                        ),
                        const SizedBox(height: 30),
                        buildElevatedButton(
                          context,
                          'Ticket',
                          ViewTicket(
                            username: username,
                            schoolId: schoolId,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                          ),
                          Icons.sticky_note_2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
}
