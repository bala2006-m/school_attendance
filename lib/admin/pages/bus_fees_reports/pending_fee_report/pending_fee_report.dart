import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';
import '../../../../services/bus_fee_payment_api.dart';
import '../../../../services/bus_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/build_pending_fee_report.dart';

class PendingFeeReport extends StatefulWidget {
  const PendingFeeReport({
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
  State<PendingFeeReport> createState() => _PendingFeeReportState();
}

class _PendingFeeReportState extends State<PendingFeeReport> {
  bool isLoading = true;
  List<dynamic> students = [];
  List<dynamic> allPayments = [];
  List<dynamic> pendingStudents = [];
  List<dynamic> paidStudents = [];
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  List<dynamic> allFees = [];

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
    initAll();
    fetchAllFees();
  }

  Future<void> fetchAllFees() async {
    try {
      allFees = await BusFeeStructureApi.getStructuresBySchoolActive(
        int.parse(widget.schoolId),
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
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> initAll() async {
    setState(() => isLoading = true);
    try {
      // Fetch all in parallel
      final results = await Future.wait([
        ApiService.fetchStudentsRoutes(
          schoolId: int.parse(widget.schoolId),
          classId: int.parse(widget.classId),
        ),
        BusFeePaymentApi.getBySchoolIdAndClassId(
          int.parse(widget.schoolId),
          int.parse(widget.classId),
        ),
        BusFeeStructureApi.getStructuresBySchoolActive(
          int.parse(widget.schoolId),
        ),
      ]);

      final studentResult = results[0];
      final paymentResult = results[1];
      final feeStructureResult = results[2];

      // 🧮 Parse students
      if (studentResult is List) {
        students = List<Map<String, dynamic>>.from(studentResult);
      } else if (studentResult is Map<String, dynamic> &&
          studentResult['data'] is List) {
        students = List<Map<String, dynamic>>.from(studentResult['data']);
      } else {
        students = [];
      }

      // 💰 Parse payments
      allPayments =
          (paymentResult is Map && paymentResult['payments'] is List)
              ? List<Map<String, dynamic>>.from(paymentResult['payments'])
              : [];

      // 🧾 Parse fee structures
      if (feeStructureResult is List) {
        allFees = List<Map<String, dynamic>>.from(feeStructureResult);
      } else if (feeStructureResult is Map<String, dynamic> &&
          feeStructureResult['data'] is List) {
        allFees = List<Map<String, dynamic>>.from(feeStructureResult['data']);
      } else {
        allFees = [];
      }

      // Merge nested payments inside structures
      for (var f in allFees) {
        if (f['busFeePayment'] is List) {
          for (var p in f['busFeePayment']) {
            if (!allPayments.any((x) => x['id'] == p['id'])) {
              allPayments.add(Map<String, dynamic>.from(p));
            }
          }
        }
      }

      // Build helper map by route
      final Map<String, List<Map<String, dynamic>>> structuresByRoute = {};
      for (var f in allFees) {
        final routeKey = f['route']?.toString().trim().toLowerCase() ?? '';
        structuresByRoute
            .putIfAbsent(routeKey, () => [])
            .add(Map<String, dynamic>.from(f));
      }

      final List<Map<String, dynamic>> paidFully = [];
      final List<Map<String, dynamic>> paidPartial = [];
      final List<Map<String, dynamic>> pendingList = [];

      // Loop through students
      for (var student in students) {
        final route = student['route']?.toString().trim();
        if (route == null || route.isEmpty) continue;

        final routeKey = route.toLowerCase();
        final studentId = (student['username'] ?? student['id']).toString();

        final routeStructures = structuresByRoute[routeKey] ?? [];

        // ❌ Skip students with no structure
        if (routeStructures.isEmpty) continue;

        final paidStructureIds = <dynamic>{};
        var anyStructurePaid = false;

        // Check every structure for this route
        for (var structure in routeStructures) {
          final structureId = structure['id'];
          final term = structure['term']?.toString().trim() ?? '';
          final totalAmount =
              double.tryParse(structure['total_amount'].toString()) ?? 0.0;

          final studentPayments =
              allPayments.where((p) {
                return p['student_id']?.toString() == studentId &&
                    p['bus_fee_structure_id'] == structureId;
              }).toList();

          final paidAmount = studentPayments.fold<double>(
            0.0,
            (sum, p) => sum + (p['amount_paid'] ?? 0),
          );

          final isFullyPaid = paidAmount >= totalAmount - 0.01;

          if (isFullyPaid) {
            anyStructurePaid = true;
            paidStructureIds.add(structureId);
          } else {
            final pendingAmount = (totalAmount - paidAmount).clamp(
              0,
              double.infinity,
            );
            final pendingStudent = Map<String, dynamic>.from(student);
            pendingStudent['term'] = term;
            pendingStudent['pending_amount'] = pendingAmount;
            pendingStudent['structure_id'] = structureId;
            pendingList.add(pendingStudent);
          }
        }

        if (anyStructurePaid) {
          paidPartial.add(Map<String, dynamic>.from(student));
        }

        final allIdsForRoute = routeStructures.map((s) => s['id']).toSet();
        if (paidStructureIds.length == allIdsForRoute.length &&
            allIdsForRoute.isNotEmpty) {
          paidFully.add(Map<String, dynamic>.from(student));
        }
      }

      // Update state
      setState(() {
        paidStudents = paidFully;
        pendingStudents = pendingList;
      });
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => BuildClasses(
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
                return PendingFeeReport(
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

  Future<void> handleDownload() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildPdf(
                      students: pendingStudents,
                      fees: allPayments,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                      className: widget.className,
                      section: widget.section,
                    ),
                title: 'Pending Fee Report',
                fileName: 'pending_fee_report',
              ),
        ),
      );
    } catch (e) {
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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Pending Fee Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Pending Fee Report',
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
                      /// Header Summary
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

                      /// Pending List
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
                                        'All students have paid their bus fees!',
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
                                            'Adm No: ${student['username']}  |  Route: ${student['route']}',
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

                      /// Download Button
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
