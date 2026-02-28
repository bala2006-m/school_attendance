import 'dart:async';

import 'package:flutter/material.dart';

import '../../admin/services/admin_api_service.dart';
import '../components/build_profile_card_mobile.dart';
import '../pages/exam_marks/exam_marks_classes.dart';
import '../pages/homework/homework_class_list.dart';
import '../pages/manage/post_tickets.dart';
import '../pages/time_table/timetable_class_list.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classIds,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });
  final String schoolId;
  final String username;
  final List<dynamic> classIds;
  final String schoolName;
  final String schoolAddress;
  final Image? schoolPhoto;
  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late Timer _refreshTimer;
  Map<String, Map<String, dynamic>> staffAccessData = {};
  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchStaffAccess(widget.username);
    });
  }

  Future<void> fetchStaffAccess(String username) async {
    final response = await AdminApiService.fetchStaffAccess(
      schoolId: widget.schoolId,
      username: username,
    );
    if (response != null &&
        response['data'] != null &&
        response['data']['access'] != null) {
      Map<String, dynamic>? accessData;

      if (response['data']['access'] is Map) {
        if (response['data']['access']['access'] is Map) {
          accessData = Map<String, dynamic>.from(
            response['data']['access']['access'],
          );
        } else {
          accessData = Map<String, dynamic>.from(response['data']['access']);
        }
      }

      if (accessData != null && mounted) {
        setState(() {
          staffAccessData[username] = accessData!;
        });
      }
    }
  }

  bool hasAccess(String title) {
    final access = staffAccessData[widget.username];
    return access != null && access[title] == true;
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.15;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BuildProfileCard(
              schoolName: widget.schoolName,
              schoolAddress: widget.schoolAddress,
              schoolPhoto: widget.schoolPhoto,
            ),
            SizedBox(height: 10),
            hasAccess('manage')
                ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26, width: 2),
                    boxShadow: [BoxShadow(color: Colors.transparent)],
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

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildButtons(
                              context,
                              screenWidth,
                              buttonHeight,
                              'Time\nTable',
                              Icons.calendar_month_outlined,
                              TimetableClassList(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                              Colors.cyan,
                              Colors.black,
                              Colors.blue,
                              Colors.white,
                            ),
                            // buildButtons(
                            //   context,
                            //   screenWidth,
                            //   buttonHeight,
                            //   'Leave\nRequest',
                            //   Icons.remove_from_queue,
                            //   ViewLeaveRequest(
                            //     schoolId: schoolId,
                            //     username: username,
                            //   ),
                            //   Colors.cyan,
                            //   Colors.black,
                            //   Colors.blue,
                            //   Colors.white,
                            // ),
                            buildButtons(
                              context,
                              screenWidth,
                              buttonHeight,
                              'Assign\nHomework',
                              Icons.maps_home_work_outlined,
                              HomeworkClassList(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                              Colors.cyan,
                              Colors.black,
                              Colors.blue,
                              Colors.white,
                            ),
                            buildButtons(
                              context,
                              screenWidth,
                              buttonHeight,
                              'Mark\nEntry',
                              Icons.collections_bookmark_outlined,
                              ExamMarksClasses(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                              Colors.cyan,
                              Colors.black,
                              Colors.blue,
                              Colors.white,
                            ),
                          ],
                        ),
                        // Row(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                )
                : SizedBox(),
            SizedBox(height: 10),
            hasAccess('services')
                ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26, width: 2),
                    boxShadow: [BoxShadow(color: Colors.transparent)],
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
                                'Services',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildButtons(
                              context,
                              screenWidth,
                              buttonHeight,
                              'Submit\nTicket',
                              Icons.feed,
                              PostTickets(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                              Colors.cyan,
                              Colors.black,
                              Colors.blue,
                              Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                : SizedBox(),
          ],
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
