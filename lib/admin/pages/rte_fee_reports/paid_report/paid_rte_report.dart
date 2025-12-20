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
import 'build_rte_paid_fee_pdf.dart';

class PaidRteReport extends StatefulWidget {
  const PaidRteReport({
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
  State<PaidRteReport> createState() => _PaidRteReportState();
}

class _PaidRteReportState extends State<PaidRteReport> {
  final RteFeesService _service = RteFeesService();
  bool isLoading = true;

  /// Raw students returned by API (each contains `rteFeePayment` list)
  List<Map<String, dynamic>> rteStudents = [];

  /// Flattened payments extracted from students' `rteFeePayment`
  List<Map<String, dynamic>> allPayments = [];

  /// Fee structures for the class/school
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
    await Future.wait([loadStudents(), loadStructures(), fetchSchoolInfo()]);
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
    } catch (e) {
      // ignore fetch failures for school info
    }
  }

  Future<void> loadStudents() async {
    try {
      final resp = await _service.getRtePaidStudents(
        widget.schoolId,
        classId: widget.classId,
      );

      // Expecting a List<Map<String,dynamic>> or similar
      rteStudents = (resp)?.cast<Map<String, dynamic>>() ?? [];

      // Flatten payments: attach student reference to each payment
      allPayments = [];
      for (final s in rteStudents) {
        final payments =
            (s['rteFeePayment'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final p in payments) {
          final copy = Map<String, dynamic>.from(p);
          // student identifier may be username or id; keep both
          copy['student_name'] = s['name'] ?? s['studentName'] ?? 'Unknown';
          copy['student_id'] = (s['username'] ?? s['id']).toString();
          copy['student_raw'] =
              s; // keep original student object if needed in PDF
          allPayments.add(copy);
        }
      }
    } catch (e) {
      rteStudents = [];
      allPayments = [];
    }
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

  Future<void> handleDownload() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildRtePdf(
                      students: rteStudents,
                      payments: allPayments,
                      structures: feeStructures,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                      className: widget.className,
                      section: widget.section,
                    ),
                title: 'Paid RTE Fee Report',
                fileName: 'paid_rte_fee_report',
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to generate PDF')));
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BuildClasses(
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
                return PaidRteReport(
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final totalCollected = allPayments.fold<num>(
      0,
      (s, p) => s + (p['amount_paid'] ?? 0),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) onWillPop();
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
                    title: 'Paid RTE Fees List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Paid RTE Fees List',
                    onBack: onWillPop,
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Loading Paid RTE Report...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Summary Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  "${widget.className} - ${widget.section}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 24,
                                  runSpacing: 8,
                                  children: [
                                    _infoTile(
                                      "Total Students",
                                      rteStudents.length.toString(),
                                      Icons.people,
                                    ),
                                    _infoTile(
                                      "Payments Recorded",
                                      allPayments.length.toString(),
                                      Icons.receipt_long,
                                    ),
                                    _infoTile(
                                      "Total Collected",
                                      "₹$totalCollected",
                                      Icons.account_balance_wallet,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Generate PDF Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              allPayments.isNotEmpty ? handleDownload : null,
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Generate Paid RTE PDF',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Data Section
                        allPayments.isEmpty
                            ? Column(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No paid RTE fee records found.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                const Text(
                                  'Recent Payments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: allPayments.length,
                                  itemBuilder: (context, index) {
                                    final payment = allPayments[index];

                                    // Try to obtain student name from flattened payment
                                    final studentName =
                                        payment['student_name'] ??
                                        payment['student_raw']?['name'] ??
                                        'Unknown';

                                    final structure = feeStructures.firstWhere(
                                      (f) =>
                                          f['id']?.toString() ==
                                          payment['rte_fee_structure_id']
                                              ?.toString(),
                                      orElse: () => {},
                                    );

                                    final descriptionList =
                                        (structure['descriptions'] as List?) ??
                                        [];
                                    final description =
                                        descriptionList.isNotEmpty
                                            ? descriptionList.join(', ')
                                            : '-';

                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFFDBEAFE,
                                          ),
                                          child: Text(
                                            (index + 1).toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF1E40AF),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Desc: $description • Status: ${payment['status'] ?? '-'}",
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${payment['amount_paid'] ?? 0}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                            Text(
                                              (payment['payment_date'] ?? '')
                                                  .toString()
                                                  .split('T')
                                                  .first,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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

  Widget _infoTile(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }
}
