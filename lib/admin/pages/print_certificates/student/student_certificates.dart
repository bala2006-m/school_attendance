import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/print_student_certificates.dart';

import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import './download.dart';
import './widget/build_periodical_report_class.dart';

class StudentCertificates extends StatefulWidget {
  const StudentCertificates({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
  });

  final String username;
  final String className;
  final String section;
  final String schoolId;
  final String classId;

  @override
  State<StudentCertificates> createState() => _StudentCertificatesState();
}

class _StudentCertificatesState extends State<StudentCertificates> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  DateTime? fromDate;
  DateTime? toDate;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final results = await Future.wait([
        TeacherApiServices.fetchStudentData(
          schoolId: widget.schoolId,
          classId: widget.classId,
        ),
        ApiService.fetchSchoolData(widget.schoolId),
      ]);

      students = List<Map<String, dynamic>>.from(results[0]);
      final schoolData = results[1];

      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }

      sortStudents();
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void sortStudents() {
    students.sort((a, b) {
      if (a['gender'] == b['gender']) {
        final numA = int.tryParse(a['username'].toString());
        final numB = int.tryParse(b['username'].toString());
        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        } else {
          return a['username'].compareTo(b['username']);
        }
      } else if (a['gender'] == 'M') {
        return -1;
      } else {
        return 1;
      }
    });
  }

  Future<void> fetchAllStudents({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final studentList = await TeacherApiServices.fetchStudentData(
        classId: widget.classId,
        schoolId: widget.schoolId,
      );

      await Future.wait(
        studentList.map((student) async {
          try {
            final classData = await StudentApiServices.fetchClassDatas(
              widget.schoolId,
              widget.classId,
            );

            student['class'] = classData?['class'] ?? '';
            student['section'] = classData?['section'] ?? '';

            final data =
                await AdminApiService.fetchStudentAttendanceBetweenDays(
                  username: student['username'],
                  fromDate: fromDate,
                  toDate: toDate,
                  schoolId: int.parse(widget.schoolId),
                );

            student['fnPresentDates'] = data?['fnPresentDates'] ?? [];
            student['anPresentDates'] = data?['anPresentDates'] ?? [];
            student['TotalMarking'] = data?['TotalMarking'] ?? [];
            student['fnAbsentDates'] = data?['fnAbsentDates'] ?? [];
            student['anAbsentDates'] = data?['anAbsentDates'] ?? [];
            student['totalPercentage'] = data?['totalPercentage'] ?? [];
          } catch (e) {
            setState(() {});
          }
        }),
      );

      setState(() => students = studentList);
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> pickDatesAndGeneratePdf() async {
    final start = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (start == null) return;

    DateTime? end;
    if (mounted) {
      end = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: start,
        lastDate: DateTime(2100),
      );
    }

    if (end == null) return;

    setState(() {
      fromDate = start;
      toDate = end;
      isLoading = true;
    });

    await fetchAllStudents(fromDate: fromDate!, toDate: toDate!);
    await _generatePdf();

    setState(() => isLoading = false);
  }

  Future<void> _generatePdf() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              title: 'Periodical Report Class',
              fileName: 'periodical_report_class',
              buildPdf:
                  () => buildPdf(
                    classStudents: students,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
            ),
      ),
    );
  }

  Future<bool> _navigateBack() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => PrintStudentCertificates(
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
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 180 : 140),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Generate Report',
                    schoolId: widget.schoolId,
                    username: widget.username,
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => _navigateBack(),
                  )
                  : AdminAppbarDesktop(
                    title: 'Generate Report',
                    schoolId: widget.schoolId,
                    username: widget.username,
                    onBack: () => _navigateBack(),
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60,
                  ),
                )
                : students.isEmpty
                ? _buildEmptyView()
                : _buildStudentView(),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "No Students Found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            "Generate Periodical Attendance Report as PDF for Class ${widget.className}-${widget.section}.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: Colors.grey[700]),
          ),
        ),

        // Row with From and To date pickers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final selectedFromDate = await showDatePicker(
                    context: context,
                    initialDate: fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selectedFromDate != null) {
                    setState(() {
                      fromDate = selectedFromDate;
                      // Ensure toDate is on or after fromDate
                      if (toDate != null && toDate!.isBefore(fromDate!)) {
                        toDate = fromDate;
                      }
                    });
                  }
                },
                child: Text(
                  fromDate == null
                      ? "Select From Date"
                      : "From: ${fromDate!.toLocal().toString().split(' ')[0]}",
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed:
                    fromDate == null
                        ? null
                        : () async {
                          final selectedToDate = await showDatePicker(
                            context: context,
                            initialDate: toDate ?? fromDate!,
                            firstDate: fromDate!,
                            lastDate: DateTime(2100),
                          );
                          if (selectedToDate != null) {
                            setState(() {
                              toDate = selectedToDate;
                            });
                          }
                        },
                child: Text(
                  toDate == null
                      ? "Select To Date"
                      : "To: ${toDate!.toLocal().toString().split(' ')[0]}",
                ),
              ),
            ],
          ),
        ),

        // Generate PDF Button
        ElevatedButton.icon(
          onPressed:
              (fromDate != null && toDate != null)
                  ? () async {
                    setState(() => isLoading = true);
                    await fetchAllStudents(
                      fromDate: fromDate!,
                      toDate: toDate!,
                    );
                    await _generatePdf();
                    setState(() => isLoading = false);
                  }
                  : null,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Generate PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: students.length,
            itemBuilder: (context, i) {
              final s = students[i];
              final isFemale = s['gender'] == 'F';
              return Card(
                color: isFemale ? Colors.pink[50] : Colors.blue[50],
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isFemale ? Icons.female : Icons.male,
                    color: isFemale ? Colors.pink : Colors.blue,
                    size: 30,
                  ),
                  title: Text(
                    s['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: ${s['username']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => Download(
                              classId: widget.classId,
                              className: widget.className,
                              section: widget.section,
                              schoolId: widget.schoolId,
                              username: widget.username,
                              studentUsername: s['username'],
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
