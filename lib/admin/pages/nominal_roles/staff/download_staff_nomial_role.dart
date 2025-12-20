// download_staff_nominal_role.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';

class DownloadStaffNominalRole extends StatefulWidget {
  const DownloadStaffNominalRole({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<DownloadStaffNominalRole> createState() =>
      _DownloadStaffNominalRoleState();
}

class _DownloadStaffNominalRoleState extends State<DownloadStaffNominalRole> {
  static int selectedIndex = 0;

  List<Map<String, dynamic>> staffs = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await fetchSchoolInfo();
    try {
      staffs = await AdminApiService.fetchStaffData(widget.schoolId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load staff data")),
        );
      }
    }
    setState(() {
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
          try {
            Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
            schoolPhotoBytes = imageBytes;
          } catch (e) {
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load school info")),
        );
      }
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
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

  Future<pw.Document> buildPdfAsync({required String facultyType}) async {
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    final filteredStaffs =
        staffs.where((s) => s['faculty'] == facultyType).toList()..sort(
          (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
        );

    if (filteredStaffs.isEmpty) {
      pdf.addPage(
        pw.Page(
          build:
              (context) => pw.Center(
                child: pw.Text(
                  "No $facultyType staffs found",
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ),
        ),
      );
    } else {
      const rowsPerPage = 25;
      final chunks = <List<Map<String, dynamic>>>[];

      for (var i = 0; i < filteredStaffs.length; i += rowsPerPage) {
        chunks.add(
          filteredStaffs.sublist(
            i,
            i + rowsPerPage > filteredStaffs.length
                ? filteredStaffs.length
                : i + rowsPerPage,
          ),
        );
      }

      for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        final chunk = chunks[chunkIndex];

        pdf.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
            pageFormat: PdfPageFormat.a4,
            header:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (chunkIndex == 0) ...[
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (schoolPhotoBytes != null)
                            pw.Image(
                              pw.MemoryImage(schoolPhotoBytes!),
                              width: 80,
                              height: 80,
                            ),
                          if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
                          pw.Padding(
                            padding: pw.EdgeInsets.only(top: 10),
                            child: pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  if (schoolName?.isNotEmpty == true)
                                    pw.Text(
                                      schoolName!,
                                      textAlign: pw.TextAlign.center,
                                      softWrap: true,
                                      style: pw.TextStyle(
                                        color: PdfColors.blue900,
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  if (schoolName?.isNotEmpty == true)
                                    pw.SizedBox(height: 5),
                                  if (schoolAddress != null)
                                    pw.Text(
                                      schoolAddress!,
                                      textAlign: pw.TextAlign.center,
                                      style: const pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.blue900,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      // pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Text(
                          "${facultyType[0].toUpperCase()}${facultyType.substring(1)} Staff List",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                    ] else
                      pw.SizedBox(height: 10),
                  ],
                ),
            build:
                (context) => [
                  pw.TableHelper.fromTextArray(
                    headers: [
                      "S.No",
                      "Name",
                      "Designation",
                      "Gender",
                      "Mobile",
                      "Email",
                    ],
                    data:
                        chunk.asMap().entries.map((entry) {
                          final index =
                              chunkIndex * rowsPerPage + entry.key + 1;
                          final staff = entry.value;
                          return [
                            index.toString(),
                            staff['name'].toString().toUpperCase(),
                            staff['designation'].toString().toUpperCase(),
                            (staff['gender'] == 'M'
                                ? 'Male'
                                : staff['gender'] == 'F'
                                ? 'Female'
                                : staff['gender'] == 'O'
                                ? 'Others'
                                : ""),
                            staff['mobile'] ?? '',
                            staff['email'] ?? '',
                          ];
                        }).toList(),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
                    columnWidths: {
                      0: pw.FixedColumnWidth(23),
                      1: pw.FlexColumnWidth(4),
                      2: pw.FlexColumnWidth(3),
                      3: pw.FixedColumnWidth(46),
                      4: pw.FixedColumnWidth(77),
                      5: pw.FlexColumnWidth(4),
                    },
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                ],
          ),
        );
      }
    }

    return pdf;
  }

  Future<pw.Document> buildPdfAsync1({required String facultyType}) async {
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    final filteredStaffs =
        staffs.where((s) => s['faculty'] == facultyType).toList()..sort(
          (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
        );

    if (filteredStaffs.isEmpty) {
      pdf.addPage(
        pw.Page(
          build:
              (context) => pw.Center(
                child: pw.Text(
                  "No $facultyType staffs found",
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ),
        ),
      );
    } else {
      const rowsPerPage = 25;
      final chunks = <List<Map<String, dynamic>>>[];

      for (var i = 0; i < filteredStaffs.length; i += rowsPerPage) {
        chunks.add(
          filteredStaffs.sublist(
            i,
            i + rowsPerPage > filteredStaffs.length
                ? filteredStaffs.length
                : i + rowsPerPage,
          ),
        );
      }

      for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        final chunk = chunks[chunkIndex];

        pdf.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
            pageFormat: PdfPageFormat.a4,
            header:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (chunkIndex == 0) ...[
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (schoolPhotoBytes != null)
                            pw.Image(
                              pw.MemoryImage(schoolPhotoBytes!),
                              width: 80,
                              height: 80,
                            ),
                          if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
                          pw.Padding(
                            padding: pw.EdgeInsets.only(top: 10),
                            child: pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  if (schoolName?.isNotEmpty == true)
                                    pw.Text(
                                      schoolName!,
                                      textAlign: pw.TextAlign.center,
                                      softWrap: true,
                                      style: pw.TextStyle(
                                        color: PdfColors.blue900,
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  if (schoolName?.isNotEmpty == true)
                                    pw.SizedBox(height: 5),
                                  if (schoolAddress != null)
                                    pw.Text(
                                      schoolAddress!,
                                      textAlign: pw.TextAlign.center,
                                      style: const pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.blue900,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      // pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Text(
                          "${facultyType[0].toUpperCase()}${facultyType.substring(1)} Staff List",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                    ] else
                      pw.SizedBox(height: 10),
                  ],
                ),
            build:
                (context) => [
                  pw.TableHelper.fromTextArray(
                    headers: [
                      "S.No",
                      "User Id",
                      "Name",
                      // "Designation",
                      // "Gender",
                      "Mobile",
                      "Email",
                    ],
                    data:
                        chunk.asMap().entries.map((entry) {
                          final index =
                              chunkIndex * rowsPerPage + entry.key + 1;
                          final staff = entry.value;
                          return [
                            index.toString(),
                            staff['username'].toString().toUpperCase(),

                            staff['name'].toString().toUpperCase(),
                            // staff['designation'].toString().toUpperCase(),
                            // (staff['gender'] == 'M'
                            //     ? 'Male'
                            //     : staff['gender'] == 'F'
                            //     ? 'Female'
                            //     : staff['gender'] == 'O'
                            //     ? 'Others'
                            //     : ""),
                            // '', '',
                            // staff['mobile'] ?? '',
                            // staff['email'] ?? '',
                          ];
                        }).toList(),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
                    columnWidths: {
                      0: pw.FixedColumnWidth(23),
                      // 1: pw.FlexColumnWidth(0.1),
                      // 2: pw.FlexColumnWidth(0.1),
                      3: pw.FixedColumnWidth(80),
                      4: pw.FixedColumnWidth(80),
                      //5: pw.FlexColumnWidth(4),
                    },
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                ],
          ),
        );
      }
    }

    return pdf;
  }

  Future<void> handleDownload() async {
    final facultyType = selectedIndex == 0 ? 'teaching' : 'nonteaching';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf: () => buildPdfAsync(facultyType: facultyType),
              title:
                  '${facultyType[0].toUpperCase()}${facultyType.substring(1)} Staff List',
              fileName: '${facultyType}_staff_list',
            ),
      ),
    );
  }

  Future<void> handleDownload1() async {
    final facultyType = selectedIndex == 0 ? 'teaching' : 'nonteaching';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf: () => buildPdfAsync1(facultyType: facultyType),
              title:
                  '${facultyType[0].toUpperCase()}${facultyType.substring(1)} Staff List',
              fileName: '${facultyType}_staff_list',
            ),
      ),
    );
  }

  Widget staffSection(List<Map<String, dynamic>> list, String title) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, color: Colors.teal, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        '$title:',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${list.length}',
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
                'Do you want to generate the $title as a PDF?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: list.isEmpty ? null : handleDownload,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Generate PDF'),
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
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: list.isEmpty ? null : handleDownload1,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Generate PDF(email/mobile)'),
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
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    'Download is disabled because there are no staffs to report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final teachingStaffs =
        staffs.where((s) => s['faculty'] == 'teaching').toList();
    final nonTeachingStaffs =
        staffs.where((s) => s['faculty'] == 'nonteaching').toList();

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
                    title: 'Staff List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
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
                    title: 'Staff List',
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
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
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : IndexedStack(
                  index: selectedIndex,
                  children: [
                    staffSection(teachingStaffs, "Teaching Staff"),
                    staffSection(nonTeachingStaffs, "Non Teaching Staff"),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() => selectedIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              label: 'Teaching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 30),
              label: 'Non Teaching',
            ),
          ],
        ),
      ),
    );
  }
}
