import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../services/api_service.dart';
import '../../../services/rte_api_services.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/pdf_preview_custom_page.dart';
import '../dashboard/admin_dashboard.dart';
import './build_bus_student_pdf.dart';

class BusStudentList extends StatefulWidget {
  const BusStudentList({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<BusStudentList> createState() => _BusStudentListState();
}

class _BusStudentListState extends State<BusStudentList> {
  bool isLoading = true;
  bool isDownloading = false;
  Map<String, dynamic> students = {};
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchSchoolInfo(), init()]);
    setState(() => isLoading = false);
  }

  Future<void> init() async {
    final data = await RteApiServices.fetchBusStudentsSchool(
      schoolId: int.parse(widget.schoolId),
    );
    setState(() {
      students = data;
      isLoading = false;
    });
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);

      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];
        if (schoolData[0]['photo'] != null) {
          Uint8List? decodeBase64(dynamic data) {
            if (data == null) return null;
            return base64Decode(data as String);
          }

          schoolPhotoBytes = await compute(
            decodeBase64,
            schoolData[0]['photo'],
          );
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
                    students: students['students'],
                    schoolName: schoolName ?? '',
                    schoolAddress: schoolAddress ?? '',
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: 'RTE Student ',
              fileName: 'rte_student_school',
            ),
      ),
    );
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
                    title: 'Bus Going  Students',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bus Going Students',
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
                : students.isEmpty ||
                    students['totalStudents'].toString() == '0'
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
                                    students['totalStudents'].toString(),
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
                            'Do you want to generate the Bus Going Students List as a PDF For whole School?',
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
