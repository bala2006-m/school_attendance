import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/add_or_remove/add_or_remove_admin.dart';
import 'package:school_attendance/admin/pages/add_or_remove/add_or_remove_staff.dart';
import 'package:school_attendance/admin/pages/add_or_remove/bulk_upload/bulk_upload_register_student.dart';
import 'package:school_attendance/admin/pages/daily_absentees/daily_absentees.dart';
import 'package:school_attendance/admin/pages/leave_request/view_leave_request.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../components/build_classes.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../accounts/drawing/drawing.dart';
import '../../accounts/expense/expense.dart';
import '../../accounts/finance/finance.dart';
import '../../accounts/income/income.dart';
import '../../add_or_remove/add_or_remove_class.dart';
import '../../add_or_remove/bulk_upload/bulk_upload_register_admin.dart';
import '../../add_or_remove/bulk_upload/bulk_upload_register_staff.dart';
import '../../add_or_remove/student/add_or_remove_class_list.dart';
import '../../app_payment/app_payment.dart';
import '../../bus_fees/activate/activate_bus_fees.dart';
import '../../bus_fees/add_bus_fees/add_bus_fees.dart';
import '../../bus_fees/collect_bus_fees/collect_bus_fees.dart';
import '../../bus_fees/view_status/view_bus_fee_status.dart';
import '../../bus_fees_reports/paid_fee_report/paid_fee_report.dart';
import '../../bus_fees_reports/pending_fee_report/pending_fee_report.dart';
import '../../bus_student_list/bus_student_list.dart';
import '../../collect_fees/collect_fees_classes.dart';
import '../../community_classification/community_classification.dart';
import '../../consecutive-absentees/consecutive_absents_classes.dart';
import '../../daily_report/daily_report.dart';
import '../../exam_mark_report/exam_mark_report_classes.dart';
import '../../exam_marks/exam_mark_classes.dart';
import '../../fee_reports/pending_fee_collection/pending_fee_collection.dart';
import '../../fee_reports/periodical_fee_collection/periodical_fee_collection.dart';
import '../../fee_reports/today_collection/today_collection.dart';
import '../../fee_reports/total_fee_collection/total_fee_collection.dart';
import '../../nominal_roles/admin/download_admin_nomial_role.dart';
import '../../nominal_roles/staff/download_staff_nomial_role.dart';
import '../../nominal_roles/student/download_student_nomial_role.dart';
import '../../print_certificates/student/periodically_attendance_report.dart';
import '../../rte_fee_reports/paid_report/paid_rte_report.dart';
import '../../rte_fee_reports/pending_report/pending_rte_report.dart';
import '../../rte_fees/activate/activate_rte_fees.dart';
import '../../rte_fees/add_rte_fees/add_rte_fees.dart';
import '../../rte_fees/collect_rte_fees/collect_rte_fees.dart';
import '../../rte_fees/status/rte_status.dart';
import '../../rte_students_report/rte_students_report.dart';
import '../../student_fees/admin_fee_structure_classes.dart';
import '../../student_fees/update_status/update_term_fee_status.dart';
import '../../student_fees/view_status/view_term_fee_status.dart';
import '../../time_table/timetable_class_list.dart';
import '../../upload_images/upload_images.dart';
import '../../view_profiles/admin/view_admin_profiles.dart';
import '../../view_profiles/staff/view_staff_profile.dart';
import '../../view_profiles/student/view_student_profile.dart';
import '../admin_dashboard.dart';
import './post_tickets.dart';
import 'create_today_message.dart';
import 'mark_leave_list.dart';

class AdminManagementDesktop extends StatefulWidget {
  final String adminUsername;
  final String schoolId;
  final String schoolName;
  final String schoolAddress;
  final Image? schoolPhoto;
  const AdminManagementDesktop({
    super.key,
    required this.adminUsername,
    required this.schoolId,
    required this.schoolName,
    required this.schoolAddress,
    this.schoolPhoto,
  });

  @override
  State<AdminManagementDesktop> createState() => _AdminManagementDesktopState();
}

class _AdminManagementDesktopState extends State<AdminManagementDesktop> {
  String adminName = '';
  String designation = '';
  Image? adminPhoto;
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  static double savedScrollOffset = 0;
  static int? savedClickedButtonIndex;
  int? _clickedButtonIndex;
  @override
  void initState() {
    super.initState();
    loadProfileData();
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
      }
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
                controller: _scrollController,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BuildProfileCard(
                      schoolPhoto: widget.schoolPhoto,
                      schoolAddress: widget.schoolAddress,
                      schoolName: widget.schoolName,
                    ),
                    const SizedBox(height: 20),
                    buildManageContainer(),

                    const SizedBox(height: 30),
                    buildFeesContainer(),
                    const SizedBox(height: 30),
                    buildBusFeesContainer(),
                    const SizedBox(height: 30),
                    buildRteFeesContainer(),
                    const SizedBox(height: 30),
                    buildAccountContainer(),
                    const SizedBox(height: 30),
                    buildServiceContainer(),
                    const SizedBox(height: 30),
                    buildBulkUploadContainer(),
                    const SizedBox(height: 30),
                    buildViewProfileContainer(),
                    const SizedBox(height: 30),
                    buildReportsContainer(),
                    const SizedBox(height: 30),
                  ],
                ),
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

  // Future<Widget> buildProfileCard() async {
  //   var adminData = await AdminApiService.fetchAdminData(
  //     username: widget.adminUsername,
  //     schoolId: widget.schoolId,
  //   );
  //   var adminName = adminData?['name'] ?? '';
  //   var adminDesignation = adminData?['designation'] ?? '';
  //   Image? adminPhoto;
  //
  //   if (adminData?['photo'] != null) {
  //     Uint8List imageBytes = base64Decode(adminData?['photo']);
  //     adminPhoto = Image.memory(imageBytes);
  //   }
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       // A light, professional, and calming color for the profile card background
  //       color:
  //           Colors
  //               .teal, // A very light blue, suggesting calmness and professionalism
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
  //     ),
  //     child: Row(
  //       children: [
  //         adminPhoto != null
  //             ? CircleAvatar(radius: 30, backgroundImage: adminPhoto.image)
  //             : const CircleAvatar(
  //               radius: 30,
  //               backgroundColor: Colors.white,
  //               child: Icon(Icons.person, size: 40, color: Colors.grey),
  //             ),
  //         const SizedBox(width: 16),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               adminName,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             Text(
  //               adminDesignation,
  //               style: const TextStyle(color: Colors.white70, fontSize: 18),
  //             ), //
  //           ],
  //         ),
  //         const Spacer(),
  //       ],
  //     ),
  //   );
  // }

  Widget buildManageContainer() {
    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 0,
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
                  buttonIndex: 1,
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
                  buttonIndex: 2,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 3,
                  context,
                  'Student',
                  AddOrRemoveClassList(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.people_alt_outlined,
                ),
                const SizedBox(height: 30),
                buildElevatedButton(
                  buttonIndex: 4,
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
                  buttonIndex: 5,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 6,
                  context,
                  'TimeTable',
                  TimetableClassList(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.people_alt_outlined,
                ),
                buildElevatedButton(
                  buttonIndex: 7,
                  context,
                  'Activate\nProgress\nCard',
                  ExamMarkClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.collections_bookmark_outlined,
                ),
                buildElevatedButton(
                  buttonIndex: 28,
                  context,
                  'Post Events',
                  UploadImagesVideos(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.event,
                ),
              ],
            ),
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //
            //
            //
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget buildFeesContainer() {
    return Container(
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
                    'Term Fees',
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
                buildElevatedButton(
                  buttonIndex: 25,
                  context,
                  'Add Term \nFees',
                  AdminFeeStructureClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.feed,
                ),
                buildElevatedButton(
                  buttonIndex: 26,
                  context,
                  'Collect Term \nFees',
                  CollectFeesClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.collections_bookmark,
                ),
                buildElevatedButton(
                  buttonIndex: 29,
                  context,
                  'Total Fee\nCollected',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      // Return the page you want to navigate to
                      return TotalFeeCollection(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.add,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 31,
                  context,
                  'Periodical\nFee\nCollection',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return PeriodicalFeeCollection(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.select_all,
                ),
                buildElevatedButton(
                  buttonIndex: 32,
                  context,
                  'Pending Fee\nList',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return PendingFeeCollection(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.pending,
                ),
                buildElevatedButton(
                  buttonIndex: 39,
                  context,
                  "View\nStatus",
                  ViewTermFeeStatus(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.analytics,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 46,
                  context,
                  'Activate\nTerm Fees',
                  UpdateTermFeeStatus(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.update,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccountContainer() {
    return Container(
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
                    'Account',
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
                buildElevatedButton(
                  buttonIndex: 30,
                  context,
                  'Daily\nCollected',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return TodayCollectionOptionB(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.today,
                ),
                buildElevatedButton(
                  buttonIndex: 47,
                  context,
                  'Income',
                  Income(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.money,
                ),
                buildElevatedButton(
                  buttonIndex: 48,
                  context,
                  'Expense',
                  Expense(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.outbond_outlined,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 49,
                  context,
                  'Drawing',
                  Drawing(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.drive_folder_upload,
                ),
                buildElevatedButton(
                  buttonIndex: 50,
                  context,
                  'Finance',
                  Finance(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.analytics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBusFeesContainer() {
    return Container(
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
                    'Bus Fees',
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
                buildElevatedButton(
                  buttonIndex: 34,
                  context,
                  'Add Bus\nFees',
                  AddBusFees(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.bus_alert,
                ),
                buildElevatedButton(
                  buttonIndex: 35,
                  context,
                  'Collect Bus\nFees',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      // Return the page you want to navigate to
                      return CollectBusFees(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),

                  Icons.generating_tokens,
                ),
                buildElevatedButton(
                  buttonIndex: 36,
                  context,
                  'Pending Fee\nList',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      // Return the page you want to navigate to
                      return PendingFeeReport(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.pending,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 37,
                  context,
                  'Paid Fee\nList',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      // Return the page you want to navigate to
                      return PaidFeeReport(
                        schoolId: schoolId,
                        username: username,
                        className: className,
                        section: section,
                        classId: classId,
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.currency_rupee,
                ),
                buildElevatedButton(
                  context,
                  'View\nStatus',
                  ViewBusFeeStatus(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.analytics,
                  buttonIndex: 40,
                ),
                buildElevatedButton(
                  buttonIndex: 51,
                  context,
                  'Activate\nBus Fees',
                  ActivateBusFees(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.update,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRteFeesContainer() {
    return Container(
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
                    'RTE Fees',
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
                buildElevatedButton(
                  buttonIndex: 41,
                  context,
                  'Add RTE\nFees',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return AdminRteFeeStructureScreen(
                        schoolId: int.parse(schoolId),
                        username: username,
                        className: className,
                        section: section,
                        classId: int.parse(classId),
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),

                  Icons.rtt,
                ),
                buildElevatedButton(
                  buttonIndex: 42,
                  context,
                  'Collect RTE\nFees',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      //10
                      return CollectRteFees(
                        schoolId: int.parse(schoolId),
                        username: username,
                        className: className,
                        section: section,
                        classId: int.parse(classId),
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),

                  Icons.generating_tokens,
                ),
                buildElevatedButton(
                  buttonIndex: 43,
                  context,
                  'Pending RTE\nList',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return PendingRteReport(
                        schoolId: int.parse(schoolId),
                        username: username,
                        className: className,
                        section: section,
                        classId: int.parse(classId),
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.pending,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 44,
                  context,
                  'Paid RTE\nList',
                  BuildClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                    title: 'Class List',
                    onTap: ({
                      required String schoolId,
                      required String username,
                      required String className,
                      required String section,
                      required String classId,
                    }) {
                      return PaidRteReport(
                        schoolId: int.parse(schoolId),
                        username: username,
                        className: className,
                        section: section,
                        classId: int.parse(classId),
                      );
                    },

                    onWillPop: AdminDashboard(
                      schoolId: widget.schoolId,
                      username: widget.adminUsername,
                    ),
                  ),
                  Icons.currency_rupee,
                ),
                buildElevatedButton(
                  context,
                  'View\nStatus',
                  RteStatus(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.analytics,
                  buttonIndex: 45,
                ),
                buildElevatedButton(
                  buttonIndex: 52,
                  context,
                  'Activate\nRTE Fees',
                  ActivateRteFees(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.update,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildServiceContainer() {
    return Container(
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
                buildElevatedButton(
                  buttonIndex: 8,
                  context,
                  'View Leave\nRequest',
                  ViewLeaveRequest(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.remove_from_queue,
                ),

                // buildElevatedButton(
                //   buttonIndex: 8,
                //   context,
                //   'View\nFeedback',
                //   ViewFeedback(
                //     schoolId: widget.schoolId,
                //     username: widget.adminUsername,
                //   ),
                //   Icons.feed,
                // ),
                buildElevatedButton(
                  buttonIndex: 9,
                  context,
                  'Submit\nTicket',
                  PostTickets(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.feed,
                ),
                buildElevatedButton(
                  buttonIndex: 27,
                  context,
                  'App\nPayment',
                  AppPayment(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.payment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBulkUploadContainer() {
    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 10,
                  context,
                  'Admin\nUpload',
                  BulkUploadRegisterAdmin(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.remove_from_queue,
                ),
                buildElevatedButton(
                  buttonIndex: 11,
                  context,
                  'Staff\nUpload',
                  BulkUploadRegisterStaff(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.remove_from_queue,
                ),
                buildElevatedButton(
                  buttonIndex: 12,
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
    );
  }

  Widget buildViewProfileContainer() {
    return Container(
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
                    'View Profiles',
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
                buildElevatedButton(
                  buttonIndex: 13,
                  context,
                  'Admin',
                  ViewAdminProfile(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.admin_panel_settings_outlined,
                ),
                buildElevatedButton(
                  buttonIndex: 14,
                  context,
                  'Staff',
                  ViewStaffProfile(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.person,
                ),
                buildElevatedButton(
                  buttonIndex: 15,
                  context,
                  'Student',
                  ViewStudentProfile(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.people,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReportsContainer() {
    return Container(
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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 16,
                  context,
                  'Admin\nLists',
                  DownloadAdminNomialRole(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.admin_panel_settings_outlined,
                ),
                buildElevatedButton(
                  buttonIndex: 17,
                  context,
                  'Staff\nLists',
                  DownloadStaffNominalRole(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.person,
                ),
                buildElevatedButton(
                  buttonIndex: 18,
                  context,
                  'Student\nLists',
                  DownloadStudentNomialRole(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.people,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 19,
                  context,
                  'Periodical\nAttendance',
                  PeriodicallyAttendanceReport(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.people,
                ),
                buildElevatedButton(
                  buttonIndex: 20,
                  context,
                  'Daily\nAttendance\nSummary',
                  DailyReport(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.calendar_view_day,
                ),
                buildElevatedButton(
                  buttonIndex: 21,
                  context,
                  'Community\nClustering',
                  CommunityClassification(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.bar_chart_sharp,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 22,
                  context,
                  'Daily\nAbsentees',
                  DailyAbsentees(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.bar_chart_sharp,
                ),
                buildElevatedButton(
                  buttonIndex: 23,
                  context,
                  'Exam\nMark',
                  ExamMarkReportClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.report,
                ),
                buildElevatedButton(
                  buttonIndex: 24,
                  context,
                  'Long\nAbsentees',
                  ConsecutiveAbsentsClasses(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.highlight_remove,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildElevatedButton(
                  buttonIndex: 38,
                  context,
                  'RTE\nStudents',
                  RteStudentsReport(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.rate_review,
                ),
                buildElevatedButton(
                  buttonIndex: 46,
                  context,
                  'Bus Going\nStudents',
                  BusStudentList(
                    schoolId: widget.schoolId,
                    username: widget.adminUsername,
                  ),
                  Icons.bus_alert,
                ),
                // buildElevatedButton(
                //   buttonIndex: 24,
                //   context,
                //   'Long\nAbsentees',
                //   ConsecutiveAbsentsClasses(
                //     schoolId: widget.schoolId,
                //     username: widget.adminUsername,
                //   ),
                //   Icons.highlight_remove,
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
