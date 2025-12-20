import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';
import '../../../../services/bus_fee_payment_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/build_paid_fee_report.dart';

class PaidFeeReport extends StatefulWidget {
  const PaidFeeReport({
    super.key,
    required this.username,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.classId,
  });
  final String username;
  final String schoolId;
  final String className;
  final String section;
  final String classId;
  @override
  State<PaidFeeReport> createState() => _PaidFeeReportState();
}

class _PaidFeeReportState extends State<PaidFeeReport> {
  bool isLoading = true;
  List<dynamic> students = [];
  Map<int, bool> expandedStudents = {};
  List<dynamic> allPayments = [];
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    super.initState();
    initAll();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      return;
    }
  }

  /// ✅ Initialization logic
  Future<void> initAll() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.fetchStudentsRoutes(
          schoolId: int.parse(widget.schoolId),
          classId: int.parse(widget.classId),
        ),
        BusFeePaymentApi.getBySchoolIdAndClassId(
          int.parse(widget.schoolId),
          int.parse(widget.classId),
        ),
      ]);

      final studentResult = results[0];
      final paymentResult = results[1];
      if (studentResult is Map<String, dynamic>) {
        students = (studentResult['data'] as List?) ?? [];
      } else if (studentResult is List) {
        students = studentResult;
      } else {
        students = [];
      }

      if (paymentResult is Map<String, dynamic>) {
        allPayments =
            (paymentResult['payments'] as List?) ??
            (paymentResult['data'] as List?) ??
            [];
      } else if (paymentResult is List) {
        allPayments = paymentResult;
      } else {
        allPayments = [];
      }
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
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
                    () => buildPdf(
                      students: students,
                      fees: allPayments,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                      className: widget.className,
                      section: widget.section,
                    ),
                title: 'Paid Fee Report',
                fileName: 'paid_fee_report',
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
              schoolId: widget.schoolId,
              username: widget.username,
              title: 'Class List',
              onTap: ({
                required String schoolId,
                required String username,
                required String className,
                required String section,
                required String classId,
              }) {
                return PaidFeeReport(
                  schoolId: schoolId,
                  username: username,
                  className: className,
                  section: section,
                  classId: classId,
                );
              },
              onWillPop: AdminDashboard(
                schoolId: widget.schoolId,
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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Paid Fee Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Paid Fee Report',
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
                        'Loading Paid Fee Report...',
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
                        // 📋 Summary Card
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
                                      students.length.toString(),
                                      Icons.people,
                                    ),
                                    _infoTile(
                                      "Payments Recorded",
                                      allPayments.length.toString(),
                                      Icons.receipt_long,
                                    ),
                                    _infoTile(
                                      "Total Collected",
                                      "₹${allPayments.fold<num>(0, (sum, f) => sum + (f['amount_paid'] ?? 0))}",
                                      Icons.account_balance_wallet,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 📤 Generate PDF Button
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
                          icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                          label: const Text(
                            'Generate Paid Fee PDF',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 🧾 Data Section
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
                                  'No paid fee records found.',
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
                                    final student = students.firstWhere(
                                      (s) =>
                                          s['username'].toString() ==
                                              payment['student_id']
                                                  .toString() ||
                                          s['id'].toString() ==
                                              payment['student_id'].toString(),
                                      orElse: () => {},
                                    );
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
                                          student['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Route: ${payment['busFeeStructure']?['route'] ?? '-'} • "
                                          "Term: ${payment['busFeeStructure']?['term'] ?? '-'}",
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
