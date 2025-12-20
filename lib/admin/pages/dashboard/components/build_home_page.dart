import 'package:flutter/material.dart';

import '../../../components/build_marking_card.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../../components/message_box.dart';
import 'desktop_stats.dart';
import 'fee_stats.dart';
import 'mobile_stats.dart';

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
    required Map<String, dynamic> allPendingTermFees,
    required Map<String, dynamic> allPendingBusFees,
    required Map<String, dynamic> allPendingRteFees,
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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: BuildProfileCard(
                schoolPhoto: schoolPhoto,
                schoolAddress: schoolAddress,
                schoolName: schoolName,
              ),
            ),
            MessageBox(message: message),
            const SizedBox(height: 10),
            if (allPendingTermFees['allFees'].toString() != '0' &&
                allPendingTermFees['allFees'] != null &&
                allPendingTermFees != {} &&
                allPendingTermFees.toString() != '{}')
              buildTermFeeStats(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                allPendingTermFees: allPendingTermFees,
              ),
            SizedBox(height: 10),
            if (allPendingBusFees['totalBusFees'].toString() != '0' &&
                allPendingBusFees['totalBusFees'] != null &&
                allPendingBusFees != {} &&
                allPendingBusFees.toString() != '{}')
              buildBusFeeStats(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                allPendingBusFees: allPendingBusFees,
              ),
            SizedBox(height: 10),
            if (allPendingRteFees['totalRteFees'].toString() != '0' &&
                allPendingRteFees['totalRteFees'] != null &&
                allPendingRteFees != {} &&
                allPendingRteFees.toString() != '{}')
              buildRteFeeStats(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                allPendingRteFees: allPendingRteFees,
              ),
            SizedBox(height: 10),
            MobileStats(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              total: totalStaff,
              name: 'Staff',
              presentFN: presentStaffFN,
              presentAN: presentStaffAN,
              isClassShown: false,
              classIds: [],
              schoolId: '',
            ),
            SizedBox(height: 10),
            MobileStats(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              total: totalStudents,
              name: 'Students',
              presentFN: presentStudentFN,
              presentAN: presentStudentAN,
              isClassShown: false,
              classIds: [],
              schoolId: '',
            ),
            SizedBox(height: 10),
            BuildMarkingCard(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              attendanceStatusMapFn: attendanceStatusMapFn,
              attendanceStatusMapAn: attendanceStatusMapAn,
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.008),
      child: Column(
        children: [
          BuildProfileCard(
            schoolPhoto: schoolPhoto,
            schoolAddress: schoolAddress,
            schoolName: schoolName,
          ),
          const SizedBox(height: 40),
          MessageBox(message: message),
          const SizedBox(height: 10),
          DesktopStats(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            total: totalStaff,
            name: 'Staff',
            presentFN: presentStaffFN,
            presentAN: presentStaffAN,
            isClassShown: false,
            classIds: [],
            schoolId: '',
          ),
          SizedBox(height: 10),
          DesktopStats(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            total: totalStudents,
            name: 'Students',
            presentFN: presentStudentFN,
            presentAN: presentStudentAN,
            isClassShown: false,
            classIds: [],
            schoolId: '',
          ),
          SizedBox(height: 10),
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
