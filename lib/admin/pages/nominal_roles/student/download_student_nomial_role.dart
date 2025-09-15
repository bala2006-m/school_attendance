import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';
import 'build_student_list_pdf.dart';
import 'classes/download_student_nomial_role_classes.dart';

/// Singleton cache for student data to avoid refetching
class StudentCache {
  static List<Map<String, dynamic>> students = [];
  static String? schoolName;
  static String? schoolAddress;
  static Uint8List? schoolPhotoBytes;
}

class DownloadStudentNomialRole extends StatefulWidget {
  const DownloadStudentNomialRole({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<DownloadStudentNomialRole> createState() =>
      _DownloadStudentNomialRoleState();
}

class _DownloadStudentNomialRoleState extends State<DownloadStudentNomialRole>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  bool isDownloading = false;
  List<Map<String, dynamic>> students = [];
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  bool get wantKeepAlive => true; // Keep the state alive

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // Use cached data if available
    if (StudentCache.students.isNotEmpty) {
      students = StudentCache.students;
      schoolName = StudentCache.schoolName;
      schoolAddress = StudentCache.schoolAddress;
      schoolPhotoBytes = StudentCache.schoolPhotoBytes;
      setState(() => isLoading = false);
      return;
    }

    try {
      await fetchSchoolInfo();
      students = await AdminApiService.fetchAllStudentData(widget.schoolId);

      // Sort by class_id
      students.sort((a, b) => a["class_id"].compareTo(b["class_id"]));

      // Fetch class & section info for each student
      for (int i = 0; i < students.length; i++) {
        try {
          final classData = await StudentApiServices.fetchClassDatas(
            widget.schoolId,
            students[i]["class_id"].toString(),
          );
          students[i]['class'] = classData?['class'] ?? '';
          students[i]['section'] = classData?['section'] ?? '';
        } catch (e) {
          debugPrint("Error fetching class data: $e");
        }
      }

      // Cache data
      StudentCache.students = students;
      StudentCache.schoolName = schoolName;
      StudentCache.schoolAddress = schoolAddress;
      StudentCache.schoolPhotoBytes = schoolPhotoBytes;
    } catch (e) {
      debugPrint("Error initializing data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];
        if (schoolData[0]['photo'] != null) {
          try {
            Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
            schoolPhotoBytes = imageBytes;
          } catch (e) {
            debugPrint('Image decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
    }
  }

  /// PDF download/print logic placeholder
  Future<void> handleDownload() async {
    // Your PDF logic here
    await buildPdf(
      students: students,
      schoolName: schoolName ?? '',
      schoolAddress: schoolAddress ?? '',
      schoolPhotoBytes: schoolPhotoBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student List',

                    onBack: () {
                      onWillPop();
                    },
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : students.isEmpty
                ? const Center(
                  child: Text(
                    'Student List is empty.',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                )
                : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: Colors.teal,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Total Students:',
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${students.length}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Do you want to download the Student List as a PDF For whole School?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed:
                                students.isEmpty || isDownloading
                                    ? null
                                    : handleDownload,
                            icon:
                                isDownloading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Center(
                                        child: SpinKitFadingCircle(
                                          color: Colors.blueAccent,
                                          size: 60.0,
                                        ),
                                      ),
                                    )
                                    : const Icon(Icons.download_rounded),
                            label: Text(
                              isDownloading ? 'Downloading...' : 'Download PDF',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Do you want to download the Student List as a PDF For Class Wise?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          DownloadStudentNomialRoleClasses(
                                            username: widget.username,
                                            schoolId: widget.schoolId,
                                          ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_right_alt_sharp),
                            label: const Text('Class Wise'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }
}
