import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/excel_preview_page.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
// import 'build_student_list_excel.dart';
import 'build_student_list_pdf.dart';
import 'classes/download_student_nomial_role_classes.dart';
import 'classes/excel/download_student_nomial_role_classes_excel.dart';

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
  int totalStudents = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      totalStudents = await AdminApiService.countStudentUsernames(
        widget.schoolId,
      );

      if (mounted) setState(() => isLoading = false);

      _loadDetailsInBackground();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadDetailsInBackground() async {
    // if (StudentCache.students.isNotEmpty) {
    //   students = StudentCache.students;
    //   schoolName = StudentCache.schoolName;
    //   schoolAddress = StudentCache.schoolAddress;
    //   schoolPhotoBytes = StudentCache.schoolPhotoBytes;
    //   if (mounted) setState(() {});
    //   return;
    // }
    students = [];
    try {
      final results = await Future.wait([
        fetchSchoolInfo(),
        AdminApiService.fetchAllStudentDataWithClass(widget.schoolId),
      ]);

      students = results[1] as List<Map<String, dynamic>>;

      students.sort((a, b) => a["class_id"].compareTo(b["class_id"]));
      students.sort((a, b) {
        // Gender: Males ('M') first, then Females
        if (a['gender'] == b['gender']) {
          var aUsername = a['username'].toString();
          var bUsername = b['username'].toString();

          // Check if both usernames are numeric
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);

          if (numA != null && numB != null) {
            // Both numeric: compare numerically
            return numA.compareTo(numB);
          } else {
            // Otherwise: compare as strings
            return aUsername.compareTo(bUsername);
          }
        } else if (a['gender'] == 'M') {
          return -1;
        } else {
          return 1;
        }
      });
      setState(() {
        isDownloading = false;
      });
      StudentCache.students = students;
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        StudentCache.schoolName = schoolName;
        StudentCache.schoolAddress = schoolAddress;

        if (schoolData[0]['photo'] != null) {
          Uint8List? decodeBase64(dynamic data) {
            if (data == null) return null;
            return base64Decode(data as String);
          }

          schoolPhotoBytes = await compute(
            decodeBase64,
            schoolData[0]['photo'],
          );

          StudentCache.schoolPhotoBytes = schoolPhotoBytes;
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> handleDownload() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    students: students,
                    schoolName: schoolName ?? '',
                    schoolAddress: schoolAddress ?? '',
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: 'Student List',
              fileName: 'student_list_school',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
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
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student List',
                    onBack: onWillPop,
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
                : totalStudents == 0
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
                                    '$totalStudents',
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
                            'Do you want to generate the Student List as a PDF For whole School?',
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
                              isDownloading ? 'Generating...' : 'Generate PDF',
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
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: Icon(Icons.file_copy),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ExcelPreviewPage(
                                        students: students,
                                        title: 'Student List',
                                        fileName: 'student_list_school',
                                        buildPdf:
                                            () => buildPdf(
                                              students: students,
                                              schoolName: schoolName ?? '',
                                              schoolAddress:
                                                  schoolAddress ?? '',
                                              schoolPhotoBytes:
                                                  schoolPhotoBytes,
                                            ),
                                      ),
                                ),
                              );
                            },
                            label: Text('Generate Excel'),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Do you want to generate the Student List as a PDF For Class Wise?',
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
                            label: const Text('Class Wise PDF'),
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
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          DownloadStudentNomialRoleClassesExcel(
                                            username: widget.username,
                                            schoolId: widget.schoolId,
                                          ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_right_alt_sharp),
                            label: const Text('Class Wise Excel'),
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
    Navigator.pop(context);
    return false;
  }
}
