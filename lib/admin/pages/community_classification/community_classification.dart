import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/pdf_preview_custom_page.dart';
import '../dashboard/admin_dashboard.dart';
import './build_community_pdf.dart';

class CommunityClassification extends StatefulWidget {
  const CommunityClassification({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;

  @override
  State<CommunityClassification> createState() =>
      _CommunityClassificationState();
}

class _CommunityClassificationState extends State<CommunityClassification> {
  bool isLoading = false;
  bool isDownloading = false;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  List<Map<String, dynamic>> students = [];

  Future<void> initData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchCommunityClassification(), fetchSchoolInfo()]);
    setState(() => isLoading = false);
  }

  /// Fetch students and their class/section info
  Future<void> fetchCommunityClassification() async {
    try {
      final fetchedStudents =
          await AdminApiService.fetchAllStudentDataWithClass(widget.schoolId);

      setState(() => students = fetchedStudents);
    } catch (e) {
      return;
    }
  }

  /// Fetch school info (name, address, photo)
  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        setState(() {
          schoolName = schoolData[0]['name'];
          schoolAddress = schoolData[0]['address'];
        });

        if (schoolData[0]['photo'] != null) {
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          setState(() => schoolPhotoBytes = imageBytes);
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> handleDownload() async {
    setState(() => isDownloading = true);
    await initData();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildPdf(
                      schoolPhotoBytes: schoolPhotoBytes,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      students: students,
                    ),
                title: 'Community Report',
                fileName: 'community_classification',
              ),
        ),
      );
    }
    setState(() => isDownloading = false);
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
                    title: 'Community Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Community Report',

                    onBack: () => onWillPop(),
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
                : Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            'Do you want to generate the Student Community List as a PDF for the whole school?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: isDownloading ? null : handleDownload,
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
                          // const SizedBox(height: 60),
                          // Text(
                          //   'Do you want to download the Student Community List as a PDF for Class Wise?',
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     fontSize: 18,
                          //     color: Colors.grey[700],
                          //   ),
                          // ),
                          // const SizedBox(height: 30),
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //
                          //   },
                          //   icon: const Icon(Icons.arrow_right_alt_sharp),
                          //   label: const Text('Class Wise'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.blueAccent,
                          //     foregroundColor: Colors.white,
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 30,
                          //       vertical: 15,
                          //     ),
                          //     textStyle: const TextStyle(
                          //       fontSize: 16,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //   ),
                          // ),
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

  /// 📄 Build PDF
}
