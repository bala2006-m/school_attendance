import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';

class DownloadAdminNomialRole extends StatefulWidget {
  const DownloadAdminNomialRole({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<DownloadAdminNomialRole> createState() =>
      _DownloadAdminNomialRoleState();
}

class _DownloadAdminNomialRoleState extends State<DownloadAdminNomialRole> {
  List<Map<String, dynamic>> admins = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    await fetchSchoolInfo();
    try {
      admins = await AdminApiService.fetchAllAdmin(schoolId: widget.schoolId);
      admins.sort((a, b) {
        if (a['gender'] == b['gender']) {
          var aUsername = a['username'].toString();
          var bUsername = b['username'].toString();

          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);

          if (numA != null && numB != null) {
            return numA.compareTo(numB);
          } else {
            return aUsername.compareTo(bUsername);
          }
        } else if (a['gender'] == 'M') {
          return -1;
        } else {
          return 1;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load Admin data")),
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
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          schoolPhotoBytes = imageBytes;
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

  /// 📄 Build and return PDF document
  Future<pw.Document> buildPdf() async {
    final pdf = pw.Document();

    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    // Sort the admins similarly
    final sortedAdmins = List.from(admins);
    sortedAdmins.sort((a, b) {
      if (a['gender'] == b['gender']) {
        var aUsername = a['username'].toString();
        var bUsername = b['username'].toString();

        final numA = int.tryParse(aUsername);
        final numB = int.tryParse(bUsername);

        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        } else {
          return aUsername.compareTo(bUsername);
        }
      } else if (a['gender'] == 'M') {
        return -1;
      } else {
        return 1;
      }
    });

    if (sortedAdmins.isEmpty) {
      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build:
              (context) => pw.Center(
                child: pw.Text(
                  "No Admin Found",
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (pw.Context context) {
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
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
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (schoolName?.isNotEmpty == true)
                                pw.Text(
                                  schoolName!,
                                  textAlign: pw.TextAlign.center,
                                  softWrap: true,
                                  style: pw.TextStyle(
                                    color: PdfColors.blue900,
                                    fontSize: 13,
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
                  //pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      "Admin List",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
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
                        sortedAdmins.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final admin = entry.value;
                          return [
                            index.toString(),
                            admin['name'].toString().toUpperCase(),
                            admin['designation'].toString().toUpperCase(),
                            (admin['gender'] == 'M'
                                ? 'Male'
                                : admin['gender'] == 'F'
                                ? 'Female'
                                : admin['gender'] == 'O'
                                ? 'Others'
                                : ""),
                            admin['mobile'] ?? '',
                            admin['email'] ?? '',
                          ];
                        }).toList(),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    columnWidths: {
                      0: pw.FixedColumnWidth(23),
                      1: pw.FlexColumnWidth(4),
                      2: pw.FlexColumnWidth(3),
                      3: pw.FixedColumnWidth(46),
                      4: pw.FixedColumnWidth(77),
                      5: pw.FlexColumnWidth(4),
                    },

                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    return pdf;
  }

  /// Navigate to PDF preview screen on button press
  Future<void> handleDownload() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf: buildPdf,
              title: 'Admin List',
              fileName: 'admin_list',
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
                    title: 'Admin List',
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
                    title: 'Admin List',
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
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : admins.isEmpty
                ? Center(
                  child: const Text(
                    'Admin List is empty.',
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
                                    'Total Admins:',
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${admins.length}',
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
                            'Do you want to generate the Admin List as a PDF?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: admins.isEmpty ? null : handleDownload,
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
                          if (admins.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text(
                                'Download is disabled because there are no admins to report.',
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
                ),
      ),
    );
  }
}
