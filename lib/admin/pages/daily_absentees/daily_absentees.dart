import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/pdf_preview_custom_page.dart';
import '../dashboard/admin_dashboard.dart';
import 'build_daily_absentees.dart';

class DailyAbsentees extends StatefulWidget {
  const DailyAbsentees({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<DailyAbsentees> createState() => _DailyAbsenteesState();
}

class _DailyAbsenteesState extends State<DailyAbsentees> {
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  bool isLoading = false;
  DateTime? date;
  bool isDownloading = false;
  Map<String, dynamic> absentees = {};
  @override
  void initState() {
    fetchSchoolInfo();
    super.initState();
  }

  Future<void> getAbsentees() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date!);

    try {
      absentees = await ApiService.fetchAbsenteesSchool(
        formattedDate.toString(),
        widget.schoolId,
      );
    } catch (e) {
      return;
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

  Future<void> handleDownload() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date!);
    setState(() => isDownloading = true);
    await fetchSchoolInfo();
    await getAbsentees();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildPdf(
                      absentees: absentees,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                      date: date,
                    ),
                title: 'Absentees $formattedDate',
                fileName: 'absentees_$formattedDate',
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
                    title: 'Daily Absentees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
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
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Daily Absentees',

                    onBack: () {
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
                    },
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(color: Colors.blue, size: 50),
                )
                : Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          Text(
                            'Do you want to generate the Student Absentees Report as a PDF For whole School?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: pickDate,
                                child: Text(
                                  date == null
                                      ? 'Select Date'
                                      : 'From: ${date!.toLocal().toIso8601String().split('T')[0]}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                (date != null)
                                    ? () async {
                                      if (true) {
                                        await handleDownload();
                                      }
                                    }
                                    : null,
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

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select  Date",
    );

    if (picked != null) {
      setState(() {
        date = picked;
      });
    }
  }
}
