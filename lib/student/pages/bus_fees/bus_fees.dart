import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/bus_fee_structure_api.dart';

import '../../../admin/widget/pdf_preview_custom_page.dart';
import '../../../services/api_service.dart';
import '../../Appbar/student_appbar_desktop.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../../services/student_api_services.dart';
import '../student_dashboard.dart';
import 'widget/build_bus_fee_pdf.dart';

class BusFees extends StatefulWidget {
  const BusFees({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
  });

  final int schoolId;
  final int classId;
  final String username;

  @override
  State<BusFees> createState() => _BusFeesState();
}

class _BusFeesState extends State<BusFees> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> studentData = {};
  List<dynamic> allBusFees = [];
  List<dynamic> paidBusFees = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    init();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(
        widget.schoolId.toString(),
      );
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'] ?? '';
        schoolAddress = schoolData[0]['address'] ?? '';
        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
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

  Future<void> init() async {
    final details = await StudentApiServices.fetchStudentDataUsername(
      schoolId: widget.schoolId,
      username: widget.username,
    );

    if (!mounted) return;
    setState(() => studentData = details ?? {});

    if (studentData['route'] == null ||
        studentData['route'].toString().trim().isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    await Future.wait([fetchAllBusFees(), fetchPaidBusFees()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchAllBusFees() async {
    final allFees = await BusFeeStructureApi.getOnlyStructuresBySchoolAndRoute(
      widget.schoolId,
      studentData['route'],
    );
    setState(() => allBusFees = allFees);
  }

  Future<void> fetchPaidBusFees() async {
    final fees = await BusFeeStructureApi.getStructuresBySchoolAndRouteUsername(
      schoolId: widget.schoolId,
      route: studentData['route'],
      username: widget.username,
    );
    setState(() => paidBusFees = fees);
  }

  Future<bool> onWillPop() async {
    StudentDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  // ===========================
  // Fee Categorization
  // ===========================
  List<Map<String, dynamic>> get completedFees {
    return paidBusFees
        .where((fee) {
          final payments = fee['busFeePayment'] as List? ?? [];
          final totalPaid = payments.fold<double>(
            0,
            (sum, p) => sum + (p['amount_paid']?.toDouble() ?? 0),
          );
          return totalPaid >= (fee['total_amount']?.toDouble() ?? 0);
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> get partiallyPaidFees {
    return paidBusFees
        .where((fee) {
          final payments = fee['busFeePayment'] as List? ?? [];
          final totalPaid = payments.fold<double>(
            0,
            (sum, p) => sum + (p['amount_paid']?.toDouble() ?? 0),
          );
          final totalAmount = fee['total_amount']?.toDouble() ?? 0;
          return totalPaid > 0 && totalPaid < totalAmount;
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> get pendingFees {
    final paidIds = {
      ...completedFees.map((f) => f['id']),
      ...partiallyPaidFees.map((f) => f['id']),
    };
    return allBusFees
        .where((f) => !paidIds.contains(f['id']))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> handleDownload(Map<String, dynamic> fee) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => generateBusFeeReceiptPdf(
                    paidBusFees: [fee],
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                    studentData: studentData,
                    username: widget.username,
                  ),
              title: 'Receipt',
              fileName: 'receipt_${fee['term']}',
            ),
      ),
    );
  }

  // ===========================
  // UI Widgets
  // ===========================
  void showFeeDetails(BuildContext context, Map<String, dynamic> fee) {
    final payments = fee['busFeePayment'] as List? ?? [];
    final totalPaid = payments.fold<double>(
      0,
      (sum, p) => sum + (p['amount_paid']?.toDouble() ?? 0),
    );
    final remaining = (fee['total_amount']?.toDouble() ?? 0) - totalPaid;

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fee['term']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('- ${fee['term']}'),
                    const SizedBox(height: 12),
                    const Divider(thickness: 1.3),
                    const SizedBox(height: 5),
                    Text(
                      'Total Amount: ₹${fee['total_amount']}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      'Paid Amount: ₹$totalPaid',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      'Remaining: ₹$remaining',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Divider(thickness: 1.3),
                    const SizedBox(height: 6),
                    Text(
                      'Payments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...payments.map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue[900],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${p['amount_paid']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(DateTime.parse(p['payment_date']))} (${p['payment_mode']})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (remaining < fee['total_amount'])
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Generate Bill',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              handleDownload(fee);
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

  Widget buildFeeCard(Map<String, dynamic> fee) {
    final payments = fee['busFeePayment'] as List? ?? [];
    final totalPaid = payments.fold<double>(
      0,
      (sum, p) => sum + (p['amount_paid']?.toDouble() ?? 0),
    );
    final totalAmount = fee['total_amount']?.toDouble() ?? 0;

    String status;
    Color statusColor;
    IconData statusIcon;

    if (totalPaid >= totalAmount) {
      status = 'Paid';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (totalPaid > 0) {
      status = 'Partially Paid';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_bottom;
    } else {
      status = 'Pending';
      statusColor = Colors.red;
      statusIcon = Icons.pending;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => showFeeDetails(context, fee),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 5,
          shadowColor: statusColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.4),
                  statusColor.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusColor.withValues(alpha: 0.3),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee['term'] ?? 'Term',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Route: ${fee['route']}'),
                      Text('Total: ₹$totalAmount'),
                      Text('Paid: ₹$totalPaid'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder:
          (ctx, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 240 : 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isMobile
                    ? StudentAppbarMobile(
                      schoolId: widget.schoolId,
                      username: widget.username,
                      title: 'Bus Payments',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: () => onWillPop(),
                    )
                    : StudentAppbarDesktop(
                      title: 'Bus Payments',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: () => onWillPop(),
                    ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.orangeAccent,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [Tab(text: 'Pending'), Tab(text: 'Completed')],
                  ),
                ),
              ],
            ),
          ),
          body:
              isLoading
                  ? buildLoadingSkeleton()
                  : (studentData['route'] == null ||
                      studentData['route'].toString().trim().isEmpty)
                  ? buildEmptyState(
                    'No Bus Fee Found\nRoute not assigned.',
                    Icons.directions_bus_outlined,
                    Colors.grey,
                  )
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending + Partially Paid
                      (pendingFees + partiallyPaidFees).isEmpty
                          ? buildEmptyState(
                            'No Pending Fees 🎉',
                            Icons.done_all_rounded,
                            Colors.green,
                          )
                          : ListView.builder(
                            itemCount: (pendingFees + partiallyPaidFees).length,
                            itemBuilder:
                                (ctx, i) => buildFeeCard(
                                  (pendingFees + partiallyPaidFees)[i],
                                ),
                          ),
                      // Completed
                      completedFees.isEmpty
                          ? buildEmptyState(
                            'No Completed Payments Yet',
                            Icons.receipt_long,
                            Colors.orangeAccent,
                          )
                          : ListView.builder(
                            itemCount: completedFees.length,
                            itemBuilder:
                                (ctx, i) => buildFeeCard(completedFees[i]),
                          ),
                    ],
                  ),
        ),
      ),
    );
  }
}
