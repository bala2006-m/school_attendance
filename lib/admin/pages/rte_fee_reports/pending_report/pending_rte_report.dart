import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';
import '../../../../services/rte_fees_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import './build_rte_pending_fee.dart';

class PendingRteReport extends StatefulWidget {
  const PendingRteReport({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
    required this.username,
  });

  final int schoolId;
  final int classId;
  final String className;
  final String section;
  final String username;

  @override
  State<PendingRteReport> createState() => _PendingRteReportState();
}

class _PendingRteReportState extends State<PendingRteReport> {
  final RteFeesService _service = RteFeesService();
  bool isLoading = true;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> pendingStudents = [];
  List<Map<String, dynamic>> paidStudents = [];
  List<Map<String, dynamic>> feeStructures = [];

  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() => isLoading = true);

    await fetchSchoolInfo();
    await loadStructures();
    await loadStudents();

    setState(() => isLoading = false);
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(
        widget.schoolId.toString(),
      );
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];
        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (_) {
            schoolPhotoBytes = null;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> loadStructures() async {
    try {
      final resp = await _service.getStructuresBySchool(
        widget.schoolId,
        classId: widget.classId,
      );
      feeStructures = (resp)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      feeStructures = [];
    }
  }

  Future<void> loadStudents() async {
    try {
      final resp = await _service.getRtePaidStudents(
        widget.schoolId,
        classId: widget.classId,
      );
      students = (resp)?.cast<Map<String, dynamic>>() ?? [];

      pendingStudents = [];
      paidStudents = [];

      for (final student in students) {
        final payments =
            (student['rteFeePayment'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

        // If no fee structure found, skip
        if (feeStructures.isEmpty) continue;
        final structure = feeStructures.first;
        final totalAmount =
            double.tryParse(structure['total_amount']?.toString() ?? '0') ?? 0;

        final paidAmount = payments.fold<double>(
          0.0,
          (sum, p) => sum + (p['amount_paid'] ?? 0),
        );

        if (payments.isEmpty || paidAmount < totalAmount - 0.01) {
          final pendingAmount = (totalAmount - paidAmount).clamp(
            0,
            double.infinity,
          );
          final pendingStudent = Map<String, dynamic>.from(student);
          pendingStudent['pending_amount'] = pendingAmount;
          pendingStudents.add(pendingStudent);
        } else {
          paidStudents.add(Map<String, dynamic>.from(student));
        }
      }
    } catch (e) {
      students = [];
      pendingStudents = [];
      paidStudents = [];
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => BuildClasses(
              schoolId: widget.schoolId.toString(),
              username: widget.username,
              title: 'Class List',
              onTap: ({
                required String schoolId,
                required String username,
                required String className,
                required String section,
                required String classId,
              }) {
                return PendingRteReport(
                  schoolId: widget.schoolId,
                  username: username,
                  className: className,
                  section: section,
                  classId: int.parse(classId),
                );
              },
              onWillPop: AdminDashboard(
                schoolId: widget.schoolId.toString(),
                username: widget.username,
              ),
            ),
      ),
    );
    return false;
  }

  Future<void> handleDownload() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildRtePdf(
                      students: pendingStudents,
                      structures: feeStructures,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                      className: widget.className,
                      section: widget.section,
                    ),
                title: 'Pending RTE Fee Report',
                fileName: 'pending_rte_fee_report',
              ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to generate PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Pending RTE Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Pending RTE Fees List',
                    onBack: () => onWillPop(),
                  ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class: ${widget.className} - ${widget.section}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _summaryTile(
                                  icon: Icons.people_alt,
                                  label: 'Total',
                                  value:
                                      (paidStudents.length +
                                              pendingStudents.length)
                                          .toString(),
                                  color: Colors.white70,
                                ),
                                _summaryTile(
                                  icon: Icons.check_circle_outline,
                                  label: 'Paid',
                                  value: paidStudents.length.toString(),
                                  color: Colors.greenAccent.shade100,
                                ),
                                _summaryTile(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'Pending',
                                  value: pendingStudents.length.toString(),
                                  color: Colors.orangeAccent.shade100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pending List
                      Expanded(
                        child:
                            pendingStudents.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_rounded,
                                        color: Colors.green.shade600,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'All students have paid their RTE fees!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: pendingStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = pendingStudents[index];
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 3,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.indigo.shade100,
                                          child: Text(
                                            student['name']
                                                    ?.toString()
                                                    .substring(0, 1)
                                                    .toUpperCase() ??
                                                '?',
                                            style: const TextStyle(
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          student['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Text(
                                            'Adm No: ${student['username']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.pending_actions_rounded,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '₹${student['pending_amount'] ?? 0}',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),

                      const SizedBox(height: 16),

                      // PDF Download Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: handleDownload,
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Generate Pending Report',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
