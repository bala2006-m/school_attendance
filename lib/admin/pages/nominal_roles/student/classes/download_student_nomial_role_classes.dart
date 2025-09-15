import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_attendance/admin/components/build_profile_card_mobile.dart';

import '../../../../../services/api_service.dart';
import '../../../../../teacher/services/teacher_api_service.dart';
import '../../../../appbar/admin_appbar_desktop.dart';
import '../../../../appbar/admin_appbar_mobile.dart';
import '../download_student_nomial_role.dart';

class DownloadStudentNomialRoleClasses extends StatefulWidget {
  const DownloadStudentNomialRoleClasses({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<DownloadStudentNomialRoleClasses> createState() =>
      _DownloadStudentNomialRoleClassesState();
}

class _DownloadStudentNomialRoleClassesState
    extends State<DownloadStudentNomialRoleClasses> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes; // store raw bytes for PDF + UI

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo(), fetchClasses()]);
    if (mounted) {
      setState(() => isLoading = false);
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

  Future<void> fetchClasses() async {
    try {
      final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
      classes = List<Map<String, dynamic>>.from(cls);

      classes.sort((a, b) {
        int getClassValue(dynamic val) {
          const romanMap = {
            'I': 1,
            'II': 2,
            'III': 3,
            'IV': 4,
            'V': 5,
            'VI': 6,
            'VII': 7,
            'VIII': 8,
            'IX': 9,
            'X': 10,
            'XI': 11,
            'XII': 12,
            'XIII': 13,
          };

          if (val is int) return val;
          if (val is String) {
            final parsed = int.tryParse(val);
            if (parsed != null) return parsed;
            return romanMap[val] ?? 999;
          }
          return 999;
        }

        int classCompare = getClassValue(
          a['class'],
        ).compareTo(getClassValue(b['class']));
        if (classCompare != 0) return classCompare;
        return a['section'].toString().compareTo(b['section'].toString());
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  int? parseClassValue(dynamic val) {
    const romanMap = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
      'XI': 11,
      'XII': 12,
    };

    if (val is int) return val;
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;

      final upper = val.toUpperCase().trim();
      if (romanMap.containsKey(upper)) return romanMap[upper];

      return null; // KG, PRE-KG, etc.
    }
    return null;
  }

  List<Map<String, dynamic>> filterKinderGarden() {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value == null;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min && value <= max;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DownloadStudentNomialRole(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  /// 📄 Build PDF content
  Future<void> buildPdf({
    required List<Map<String, dynamic>> students,
    required String cls,
    required String section,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Header Section
          final header = pw.Column(
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
                  "Student List",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  "Class: $cls   Section: $section",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );

          if (students.isEmpty) {
            return [
              header,
              pw.Center(
                child: pw.Text(
                  "No Students Found",
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
            ];
          }

          // Separate by gender and sort
          final maleStudents =
              students.where((s) => s['gender'] == 'M').toList()..sort(
                (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
              );

          final femaleStudents =
              students.where((s) => s['gender'] == 'F').toList()..sort(
                (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
              );

          final otherStudents =
              students
                  .where((s) => s['gender'] != 'M' && s['gender'] != 'F')
                  .toList();

          // Combine all students with blank row between male & female
          final combinedList = [
            ...maleStudents,
            if (maleStudents.isNotEmpty && femaleStudents.isNotEmpty)
              {}, // blank row
            ...femaleStudents,
            ...otherStudents,
          ];

          int serialNo = 1;

          final data =
              combinedList.map((s) {
                if (s.isEmpty) {
                  return ["", "", "", "", "", "", ""]; // blank row
                }
                return [
                  (serialNo++).toString(),
                  s['username'] ?? '',
                  s['name'] ?? '',
                  s['gender'] == 'M'
                      ? 'Male'
                      : s['gender'] == 'F'
                      ? 'Female'
                      : 'Others',
                  s['mobile'] ?? '',
                  s['email'] ?? '',
                  "",
                ];
              }).toList();

          // Table with proportional column widths
          return [
            header,
            pw.Table.fromTextArray(
              headers: [
                "S.No",
                "Admn.No",
                "Name",
                "Gender",
                "Mobile",
                "Email",
                "Remark",
              ],
              data: data,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: pw.FlexColumnWidth(1), // S.No
                1: pw.FlexColumnWidth(3), // Admn.No
                2: pw.FlexColumnWidth(3), // Name
                3: pw.FlexColumnWidth(2), // Gender
                4: pw.FlexColumnWidth(3), // Mobile
                5: pw.FlexColumnWidth(3), // Email
                6: pw.FlexColumnWidth(2), // Remark
              },
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// 📥 Handle download & print logic
  Future<void> handleDownload({
    required List<Map<String, dynamic>> students,
    required String cls,
    required String section,
  }) async {
    await buildPdf(students: students, cls: cls, section: section);
    // final pdfBytes = await buildPdf(
    //   students: students,
    //   cls: cls,
    //   section: section,
    // );
    //
    // final fileName = "student_nominal_role_${cls}_$section.pdf";
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
    //   final downloadsDir = Directory("/storage/emulated/0/Download");
    //   if (!downloadsDir.existsSync()) {
    //     downloadsDir.createSync(recursive: true);
    //   }
    //
    //   final file = File("${downloadsDir.path}/$fileName");
    //   await file.writeAsBytes(pdfBytes);
    //
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text("✅ PDF saved to: ${file.path}")));
    // } else {
    //   final path = await FilePicker.platform.saveFile(
    //     dialogTitle: 'Save Student Nominal Role PDF',
    //     fileName: fileName,
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
    // // 🖨️ Optional Printing
    // final printers = await Printing.listPrinters();
    // if (printers.isNotEmpty) {
    //   final shouldPrint = await showDialog<bool>(
    //     context: context,
    //     builder:
    //         (context) => AlertDialog(
    //           title: const Text("Print PDF"),
    //           content: const Text(
    //             "Printer detected. Do you want to print now?",
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

  Future<void> downloadPdf({
    required String classId,
    required String cls,
    required String section,
  }) async {
    final students = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: classId,
    );
    handleDownload(students: students, cls: cls, section: section);
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
                    title: 'Student List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DownloadStudentNomialRole(
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
                    title: 'Student List',

                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DownloadStudentNomialRole(
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
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BuildProfileCard(
                          schoolPhoto:
                              schoolPhotoBytes != null
                                  ? Image.memory(
                                    schoolPhotoBytes!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          schoolAddress: schoolAddress ?? '',
                          schoolName: schoolName ?? '',
                        ),
                        const SizedBox(height: 20),

                        classes.isEmpty
                            ? const Center(
                              child: Text(
                                "No Classes Found",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClassContainer(
                                  title: "Nursery",
                                  classes: filterKinderGarden(),
                                  context: context,
                                  isKinderGarden: true,
                                ),
                                const SizedBox(height: 20),
                                _buildClassContainer(
                                  title: "Classes 1 to 5",
                                  classes: filterClasses(1, 5),
                                  context: context,
                                  isKinderGarden: false,
                                ),
                                const SizedBox(height: 20),
                                _buildClassContainer(
                                  title: "Classes 6 and above",
                                  classes: filterClassesFrom(6),
                                  context: context,
                                  isKinderGarden: false,
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildClassContainer({
    required String title,
    required List<Map<String, dynamic>> classes,
    required BuildContext context,
    required bool isKinderGarden,
  }) {
    if (classes.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
            children:
                classes.map((classItem) {
                  final classId = classItem['id'].toString();
                  final className = classItem['class'] ?? 'Unnamed';
                  final section = classItem['section'] ?? '';

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      downloadPdf(
                        classId: classId,
                        cls: className,
                        section: section,
                      );
                    },
                    child: Card(
                      color: Colors.teal,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isKinderGarden ? className : 'Class $className',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sec $section',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
