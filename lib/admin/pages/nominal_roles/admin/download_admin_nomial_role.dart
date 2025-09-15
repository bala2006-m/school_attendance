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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load Admin data")),
      );
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
            debugPrint('Image decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load school info")),
      );
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

  /// 📄 Build PDF content
  Future<void> buildPdf() async {
    final pdf = pw.Document();

    // Sort the admins list by 'username'
    final sortedAdmins = List.from(admins);
    sortedAdmins.sort(
      (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
    );

    if (sortedAdmins.isEmpty) {
      pdf.addPage(
        pw.Page(
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
          build: (pw.Context context) {
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (schoolPhotoBytes != null)
                    pw.Image(
                      pw.MemoryImage(schoolPhotoBytes!),
                      width: 80,
                      height: 80,
                    ),
                  if (schoolName != null)
                    pw.Text(
                      schoolName!,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (schoolAddress != null)
                    pw.Text(
                      schoolAddress!,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      "Admin List",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: [
                      "S.No",
                      "Admn.No",
                      "Name",
                      "Gender",
                      "Mobile",
                      "Email",
                      "Designation",
                    ],
                    data:
                        sortedAdmins.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final admin = entry.value;
                          return [
                            index.toString(),
                            admin['username'] ?? '',
                            admin['name'] ?? '',
                            (admin['gender'] == 'M'
                                ? 'Male'
                                : admin['gender'] == 'F'
                                ? 'Female'
                                : admin['gender'] == 'O'
                                ? 'Others'
                                : ""),
                            admin['mobile'] ?? '',
                            admin['email'] ?? '',
                            admin['designation'] ?? '',
                          ];
                        }).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    columnWidths: {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(2.5),
                      2: pw.FlexColumnWidth(3),
                      3: pw.FlexColumnWidth(2),
                      4: pw.FlexColumnWidth(3.2),
                      5: pw.FlexColumnWidth(3),
                      6: pw.FlexColumnWidth(3.2),
                    },
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// 📥 Handle download & print logic
  Future<void> handleDownload() async {
    await buildPdf();
    //
    // if (Platform.isAndroid || Platform.isIOS) {
    //   var status = await Permission.storage.status;
    //   if (!status.isGranted) {
    //     status = await Permission.storage.request();
    //   }
    //   if (!status.isGranted) {
    //     var manageStatus = await Permission.manageExternalStorage.request();
    //     if (!manageStatus.isGranted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Storage permission denied')),
    //       );
    //       return;
    //     }
    //   }
    //
    //   // 📂 Save to Downloads folder
    //   const downloadsPath = "/storage/emulated/0/Download";
    //   final file = File("$downloadsPath/admin_nominal_role.pdf");
    //   await file.writeAsBytes(pdfBytes);
    //
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text("PDF saved to: ${file.path}")));
    // } else {
    //   // 💻 On desktop, ask user for path
    //   final path = await FilePicker.platform.saveFile(
    //     dialogTitle: 'Save Admin Nominal Role PDF',
    //     fileName: 'admin_nominal_role.pdf',
    //   );
    //
    //   if (path != null) {
    //     final file = File(path);
    //     await file.writeAsBytes(pdfBytes);
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(SnackBar(content: Text("PDF saved to: $path")));
    //   }
    // }
    //
    // // 🖨️ Printing option
    // final printers = await Printing.listPrinters();
    // if (printers.isNotEmpty) {
    //   final shouldPrint = await showDialog<bool>(
    //     context: context,
    //     builder:
    //         (context) => AlertDialog(
    //           title: const Text("Print PDF"),
    //           content: const Text(
    //             "A printer is available. Do you want to print?",
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.pop(context, false),
    //               child: const Text("No"),
    //             ),
    //             TextButton(
    //               onPressed: () => Navigator.pop(context, true),
    //               child: const Text("Yes"),
    //             ),
    //           ],
    //         ),
    //   );
    //
    //   if (shouldPrint == true) {
    //     await Printing.layoutPdf(
    //       onLayout: (PdfPageFormat format) async => pdfBytes,
    //     );
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
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
                            'Do you want to download the Admin List as a PDF?',
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
                            label: const Text('Download PDF'),
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
