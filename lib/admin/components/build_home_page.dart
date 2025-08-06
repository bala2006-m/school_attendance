import 'package:flutter/material.dart';

import 'build_marking_card.dart';
import 'build_profile_card_desktop.dart';
import 'build_profile_card_mobile.dart';
import 'desktop_stats.dart';
import 'message_box.dart';

class BuildHomePage {
  static Widget buildHomePage({
    required Map<String, bool> attendanceStatusMapFn,
    required Map<String, bool> attendanceStatusMapAn,
    required BuildContext context,
    required String totalStudents,
    required String presentStudentFN,
    required String totalStaff,
    required String presentStaffFN,
    required String presentStudentAN,
    required String presentStaffAN,
    required String adminName,
    required String adminDesignation,
    required Image? adminPhoto,
    required String schoolName,
    required String schoolAddress,
    required String message,
    required Image? schoolPhoto,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        child: Column(
          children: [
            MediaQuery.of(context).size.width > 600
                ? BuildProfileCardDesktop.buildProfileCardDesktop(
                  adminName: adminName,
                  adminDesignation: adminDesignation,
                  adminPhoto: adminPhoto,
                  schoolAddress: schoolAddress,
                  schoolName: schoolName,
                )
                : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: BuildProfileCard(
                    schoolPhoto: schoolPhoto,
                    schoolAddress: schoolAddress,
                    schoolName: schoolName,
                  ),
                ),
            MessageBox(message: message),
            const SizedBox(height: 10),

            BuildMarkingCard(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              attendanceStatusMapFn: attendanceStatusMapFn,
              attendanceStatusMapAn: attendanceStatusMapAn,
            ),
            SizedBox(height: 10),
            DesktopStats(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              total: totalStaff,
              name: 'Staff',
              presentFN: presentStaffFN,
              presentAN: presentStaffAN,
            ),
            SizedBox(height: 10),
            DesktopStats(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              total: totalStudents,
              name: 'Students',
              presentFN: presentStudentFN,
              presentAN: presentStudentAN,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class BuildHomePageDesktop {
  static Widget buildHomePageDesktop({
    required BuildContext context,
    required String totalStudents,
    required String presentStudentFN,
    required String totalStaff,
    required String presentStaffFN,
    required String presentStudentAN,
    required String presentStaffAN,
    required String adminName,
    required String adminDesignation,
    required Image? adminPhoto,
    required String schoolName,
    required String schoolAddress,
    required Image? schoolPhoto,
    required Map<String, bool> attendanceStatusMapFn,
    required Map<String, bool> attendanceStatusMapAn,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.008),
      child: Column(
        children: [
          MediaQuery.of(context).size.width > 600
              ? BuildProfileCardDesktop.buildProfileCardDesktop(
                adminName: adminName,
                adminDesignation: adminDesignation,
                adminPhoto: adminPhoto,
                schoolAddress: schoolAddress,
                schoolName: schoolName,
              )
              : BuildProfileCard(
                schoolPhoto: schoolPhoto,
                schoolAddress: schoolAddress,
                schoolName: schoolName,
              ),
          const SizedBox(height: 40),
          // Wrap(
          //   spacing: 15,
          //   runSpacing: 15,
          //   alignment: WrapAlignment.center,
          //   children:
          //       DateTime.now().hour < 13
          //           ? [
          //             BuildStatsCardMobile.buildStatCard(
          //               icon: Icons.school,
          //               label: 'Students',
          //               value:
          //                   presentStudentFN == -1
          //                       ? 'T: $totalStudents\tP: N/A'
          //                       : 'T: $totalStudents\tP: $presentStudentFN',
          //               context: context,
          //             ),
          //             BuildStatsCardMobile.buildStatCard(
          //               icon: Icons.people,
          //               label: 'Staff',
          //               value: 'T: $totalStaff\tP: $presentStaffFN',
          //               context: context,
          //             ),
          //           ]
          //           : [
          //             BuildStatsCardMobile.buildStatCard(
          //               icon: Icons.school,
          //               label: 'Students', //
          //               value: 'T: $totalStudents\tP: $presentStudentAN',
          //               context: context,
          //             ),
          //             BuildStatsCardMobile.buildStatCard(
          //               icon: Icons.people,
          //               label: 'Staff',
          //               value: 'T: $totalStaff\tP: $presentStaffAN',
          //               context: context,
          //             ),
          //           ],
          // ),
          BuildMarkingCard(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            attendanceStatusMapFn: attendanceStatusMapFn,
            attendanceStatusMapAn: attendanceStatusMapAn,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
