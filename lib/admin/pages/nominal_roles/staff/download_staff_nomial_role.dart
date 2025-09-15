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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load staff data")),
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

  /// 📄 Build PDF content for a specific faculty type
  Future<void> buildPdf({required String facultyType}) async {
    final pdf = pw.Document();

    // Filter and sort the staff by 'username' (admn.no)
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
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
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
                        "${facultyType[0].toUpperCase()}${facultyType.substring(1)} Staff List",
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
                          filteredStaffs.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final staff = entry.value;
                            return [
                              index.toString(),
                              staff['username'] ?? '',
                              staff['name'] ?? '',
                              (staff['gender'] == 'M'
                                  ? 'Male'
                                  : staff['gender'] == 'F'
                                  ? 'Female'
                                  : staff['gender'] == 'O'
                                  ? 'Others'
                                  : ""),
                              staff['mobile'] ?? '',
                              staff['email'] ?? '',
                              staff['designation'] ?? '',
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
              ],
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// 📥 Handle download based on selected faculty
  Future<void> handleDownload() async {
    final facultyType = selectedIndex == 0 ? 'teaching' : 'nonteaching';
    await buildPdf(facultyType: facultyType);
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
                'Do you want to download the $title List as a PDF?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: list.isEmpty ? null : handleDownload,
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
                    title: 'Staff List',
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
                    title: 'Staff List',

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
                : IndexedStack(
                  index: selectedIndex,
                  children: [
                    staffSection(teachingStaffs, "Teaching Staffs"),
                    staffSection(nonTeachingStaffs, "Non Teaching Staffs"),
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
