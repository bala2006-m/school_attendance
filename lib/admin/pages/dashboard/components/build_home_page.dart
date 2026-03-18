import 'package:flutter/material.dart';

import '../../../components/build_marking_card.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../../components/message_box.dart';
import 'analysis_card.dart';
import 'analytics_section.dart';
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
    required String schoolId,
    required String username,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            BuildProfileCard(
              schoolPhoto: schoolPhoto,
              schoolAddress: schoolAddress,
              schoolName: schoolName,
            ),
            const SizedBox(height: 16),
            MessageBox(message: message),
            const SizedBox(height: 24),
            if (allPendingTermFees['allFees'].toString() != '0' &&
                allPendingTermFees['allFees'] != null &&
                allPendingTermFees != {} &&
                allPendingTermFees.toString() != '{}')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pending Term Fees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildTermFeeStats(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      allPendingTermFees: allPendingTermFees,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (allPendingBusFees['totalBusFees'].toString() != '0' &&
                allPendingBusFees['totalBusFees'] != null &&
                allPendingBusFees != {} &&
                allPendingBusFees.toString() != '{}')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.directions_bus, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Pending Bus Fees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildBusFeeStats(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      allPendingBusFees: allPendingBusFees,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (allPendingRteFees['totalRteFees'].toString() != '0' &&
                allPendingRteFees['totalRteFees'] != null &&
                allPendingRteFees != {} &&
                allPendingRteFees.toString() != '{}')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.school, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Pending RTE Fees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildRteFeeStats(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      allPendingRteFees: allPendingRteFees,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.people, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Staff Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.group, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Student Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Attendance Marking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BuildMarkingCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    attendanceStatusMapFn: attendanceStatusMapFn,
                    attendanceStatusMapAn: attendanceStatusMapAn,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.analytics, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'Analysis Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnalysisCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    totalStudents: totalStudents,
                    presentStudentFN: presentStudentFN,
                    totalStaff: totalStaff,
                    presentStaffFN: presentStaffFN,
                    presentStudentAN: presentStudentAN,
                    presentStaffAN: presentStaffAN,
                    allPendingTermFees: allPendingTermFees,
                    allPendingBusFees: allPendingBusFees,
                    allPendingRteFees: allPendingRteFees,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnalyticsSection(schoolId: schoolId, username: username),
            // const SizedBox(height: 16),
            // AdminAnalyticsMobile(schoolId: schoolId, username: username),
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
    required Map<String, dynamic> allPendingTermFees,
    required Map<String, dynamic> allPendingBusFees,
    required Map<String, dynamic> allPendingRteFees,
    required String schoolId,
    required String username,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BuildProfileCard(
                schoolPhoto: schoolPhoto,
                schoolAddress: schoolAddress,
                schoolName: schoolName,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MessageBox(message: message),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.people, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              'Staff Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.group, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Student Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Attendance Marking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BuildMarkingCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    attendanceStatusMapFn: attendanceStatusMapFn,
                    attendanceStatusMapAn: attendanceStatusMapAn,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.analytics, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'Analysis Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnalysisCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    totalStudents: totalStudents,
                    presentStudentFN: presentStudentFN,
                    totalStaff: totalStaff,
                    presentStaffFN: presentStaffFN,
                    presentStudentAN: presentStudentAN,
                    presentStaffAN: presentStaffAN,
                    allPendingTermFees: allPendingTermFees,
                    allPendingBusFees: allPendingBusFees,
                    allPendingRteFees: allPendingRteFees,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          AnalyticsSection(schoolId: schoolId, username: username),
          // const SizedBox(height: 24),
          // AdminAnalyticsMobile(schoolId: schoolId, username: username),
        ],
      ),
    );
  }
}
