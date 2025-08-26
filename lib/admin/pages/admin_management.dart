import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/add_or_remove_admin.dart';
import 'package:school_attendance/admin/pages/add_or_remove_staff.dart';
import 'package:school_attendance/admin/pages/add_or_remove_student.dart';
import 'package:school_attendance/admin/pages/bulk_upload_register_student.dart';
import 'package:school_attendance/admin/pages/post_tickets.dart';
import 'package:school_attendance/admin/pages/view_feedback.dart';
import 'package:school_attendance/admin/pages/view_leave_request.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../components/build_profile_card_desktop.dart';
import '../components/build_profile_card_mobile.dart';
import 'add_or_remove_class.dart';
import 'bulk_upload_register_admin.dart';
import 'bulk_upload_register_staff.dart';
import 'create_today_message.dart';
import 'mark_leave_list.dart';

class AdminManagement extends StatefulWidget {
  final String adminUsername;
  final String schoolId;
  final String schoolName;
  final String schoolAddress;
  final Image? schoolPhoto;
  const AdminManagement({
    super.key,
    required this.adminUsername,
    required this.schoolId,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });

  @override
  State<AdminManagement> createState() => _AdminManagementState();
}

class _AdminManagementState extends State<AdminManagement> {
  String adminName = '';
  String designation = '';
  Image? adminPhoto;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      final adminData = await AdminApiService.fetchAdminData(
        username: widget.adminUsername,
        schoolId: widget.schoolId,
      );
      setState(() {
        adminName = adminData?['name'] ?? '';
        designation = adminData?['designation'] ?? '';
        if (adminData?['photo'] != null) {
          Uint8List imageBytes = base64Decode(adminData?['photo']);
          adminPhoto = Image.memory(imageBytes);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      body:
          isLoading
              ? SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0)
              : SingleChildScrollView(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MediaQuery.of(context).size.width > 600
                        ? BuildProfileCardDesktop.buildProfileCardDesktop(
                          adminName: adminName,
                          adminDesignation: designation,
                          adminPhoto: adminPhoto,
                          schoolAddress: widget.schoolAddress,
                          schoolName: widget.schoolName,
                        )
                        : BuildProfileCard(
                          schoolPhoto: widget.schoolPhoto,
                          schoolAddress: widget.schoolAddress,
                          schoolName: widget.schoolName,
                        ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.transparent.withOpacity(0.02),
                          ),
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
                                  "Message",
                                  CreateTodayMessage(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.message,
                                ),
                                const SizedBox(height: 30),
                                buildElevatedButton(
                                  context,
                                  'Admin',
                                  AddOrRemoveAdmin(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.admin_panel_settings,
                                ),
                                const SizedBox(height: 30),
                                buildElevatedButton(
                                  context,
                                  'Staff',
                                  AddOrRemoveStaff(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.person_add_alt_1_outlined,
                                ),
                              ],
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildElevatedButton(
                                  context,
                                  'Student',
                                  StudentRegistration(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.people_alt_outlined,
                                ),
                                const SizedBox(height: 30),
                                buildElevatedButton(
                                  context,
                                  'Class',
                                  ClassRegistration(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.class_,
                                ),
                                const SizedBox(height: 30),
                                buildElevatedButton(
                                  context,
                                  ' Holiday',
                                  MarkLeaveList(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.calendar_month,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.transparent.withOpacity(0.02),
                          ),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildElevatedButton(
                                  context,
                                  'View Leave\nRequest',
                                  ViewLeaveRequest(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.remove_from_queue,
                                ),

                                buildElevatedButton(
                                  context,
                                  'View\nFeedback',
                                  ViewFeedback(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.feed,
                                ),
                                buildElevatedButton(
                                  context,
                                  'submit\nTicket',
                                  PostTickets(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.feed,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.transparent.withOpacity(0.02),
                          ),
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
                                    'Bulk Upload',
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
                                buildElevatedButton(
                                  context,
                                  'Admin\nUpload',
                                  BulkUploadRegisterAdmin(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.remove_from_queue,
                                ),
                                buildElevatedButton(
                                  context,
                                  'Staff\nUpload',
                                  BulkUploadRegisterStaff(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.remove_from_queue,
                                ),
                                buildElevatedButton(
                                  context,
                                  'Student\nUpload',
                                  BulkUploadRegisterStudent(
                                    schoolId: widget.schoolId,
                                    username: widget.adminUsername,
                                  ),
                                  Icons.remove_from_queue,
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

  Future<Widget> buildProfileCard() async {
    var adminData = await AdminApiService.fetchAdminData(
      username: widget.adminUsername,
      schoolId: widget.schoolId,
    );
    var adminName = adminData?['name'] ?? '';
    var adminDesignation = adminData?['designation'] ?? '';
    Image? adminPhoto;

    try {
      if (adminData?['photo'] != null) {
        Uint8List imageBytes = base64Decode(adminData?['photo']);
        adminPhoto = Image.memory(imageBytes);
      }
    } catch (e) {
      print('Image decode error: $e');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // A light, professional, and calming color for the profile card background
        color:
            Colors
                .teal, // A very light blue, suggesting calmness and professionalism
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          adminPhoto != null
              ? CircleAvatar(radius: 30, backgroundImage: adminPhoto.image)
              : const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adminName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                adminDesignation,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ), //
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
