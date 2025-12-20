import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/pdf_preview_custom_page.dart';
import 'build_exam_mark_report_school.dart';
import 'exam_mark_report_classes.dart';

class ExamMarkReport extends StatefulWidget {
  const ExamMarkReport({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  final String schoolId;
  final String username;
  final String classId;
  final String className;
  final String section;
  @override
  State<ExamMarkReport> createState() => _ExamMarkReportState();
}

class _ExamMarkReportState extends State<ExamMarkReport> {
  List<dynamic> titles = [];
  bool isLoading = true;
  List<Map<String, dynamic>> classData = [];
  List<dynamic> examMarks = [];
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (e) {
            return;
          }
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> fetchExamMarks({required String title}) async {
    examMarks = await AdminApiService.fetchExamMarkClassTitle(
      schoolId: widget.schoolId,
      title: title,
      classId: widget.classId,
    );
  }

  Future<void> handleBuild({required String title}) async {
    await Future.wait([fetchExamMarks(title: title), fetchSchoolInfo()]);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildPdf(
                      title: title,
                      examMarks: examMarks,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                    ),
                title:
                    '${title.substring(0, 1).toString().toUpperCase()}${title.substring(1, title.length).toString().toLowerCase()} Exam Marks',
                fileName: '${title.toString().toLowerCase()}_exam_marks',
              ),
        ),
      );
    }
  }

  Future<void> fetch() async {
    titles = await AdminApiService.fetchExamMarkClassTitles(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamMarkReportClasses(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
                    title: 'Exam Mark Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Exam Mark Report',
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
                : titles.isEmpty
                ? const Center(
                  child: Text(
                    'No exam reports available.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Available Exam Reports",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...titles.map((item) {
                        final title = item['title'] ?? 'Untitled';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              handleBuild(title: title);
                            },
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      ),
    );
  }
}
