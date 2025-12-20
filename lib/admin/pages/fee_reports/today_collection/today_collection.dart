import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../../services/api_service.dart';
import '../../../../services/bus_fee_payment_api.dart';
import '../../../../services/rte_fees_service.dart';
import '../../../../services/term_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/build_today_fee_collection_pdf.dart';

class TodayCollectionOptionB extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String username;
  final String className;
  final String section;

  const TodayCollectionOptionB({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<TodayCollectionOptionB> createState() => _TodayCollectionOptionBState();
}

class _TodayCollectionOptionBState extends State<TodayCollectionOptionB> {
  bool isLoading = false;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;

  DateTime selectedDate = DateTime.now();
  List<dynamic> students = [];
  List<dynamic> allPayments = []; // Bus
  List<dynamic> rtePayments = []; // RTE
  List<dynamic> paidFees = []; // Term fees

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
    fetchDailyCollection();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (_) {}
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> fetchDailyCollection() async {
    setState(() => isLoading = true);
    final rte = RteFeesService();

    try {
      final results = await Future.wait([
        ApiService.fetchStudentsRoutes(
          schoolId: int.parse(widget.schoolId),
          classId: int.parse(widget.classId),
        ),
        BusFeePaymentApi.getBySchoolIdClassAndDate(
          schoolId: int.parse(widget.schoolId),
          date: selectedDate.toIso8601String(),
          classId: int.parse(widget.classId),
        ),
        TermFeeStructureApi.getDailyStudentPaidFeeClass(
          schoolId: int.parse(widget.schoolId),
          date: selectedDate,
          classId: int.parse(widget.classId),
        ),
        rte.getBySchoolIdClassAndDate(
          schoolId: int.parse(widget.schoolId),
          date: selectedDate.toIso8601String(),
          classId: int.parse(widget.classId),
        ),
      ]);

      final studentResult = results[0];
      students =
          studentResult is Map ? studentResult['data'] ?? [] : studentResult;

      final busResult = results[1];
      allPayments =
          busResult is Map
              ? busResult['payments'] ?? busResult['data'] ?? []
              : busResult;

      final paidResult = results[2];
      paidFees = paidResult is List ? paidResult : [];

      final rteResult = results[3];
      rtePayments =
          rteResult is Map
              ? rteResult['payments'] ?? rteResult['data'] ?? []
              : rteResult;
    } catch (_) {
      students = [];
      allPayments = [];
      paidFees = [];
      rtePayments = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      await fetchDailyCollection();
    }
  }

  Map<String, List<dynamic>> classMap() {
    final Map<String, List<dynamic>> map = {};

    for (final fee in paidFees) {
      final classInfo = fee['class'];
      if (classInfo == null) continue;

      final c = classInfo['class'] ?? '';
      final s = classInfo['section'] ?? '';

      final key = "$c - $s";
      map.putIfAbsent(key, () => []).add(fee);
    }

    return map;
  }

  Future<void> handleBuildPdf() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              title: "Fee Collection",
              fileName:
                  "collection_${DateFormat("yyyy-MM-dd").format(selectedDate)}",
              buildPdf:
                  () => buildPdf(
                    title: "Fee Collection",
                    fees: paidFees,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                    students: students,
                    allPayments: allPayments,
                    rtePayments: rtePayments,
                  ),
            ),
      ),
    );
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
                return TodayCollectionOptionB(
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
    final cMap = classMap();
    final keys = cMap.keys.toList()..sort();

    final bool noCollection =
        paidFees.isEmpty && rtePayments.isEmpty && allPayments.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) onWillPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffe9faff),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 170 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: "Daily Fee Collection",
                    enableBack: true,
                    onBack: onWillPop,
                    enableDrawer: false,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: "Daily Fee Collection",
                    onBack: onWillPop,
                  ),
        ),

        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(color: Colors.teal, size: 60),
                )
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // HEADER
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff007e8c), Color(0xff00c2d4)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Selected Date",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    DateFormat(
                                      "yyyy-MM-dd",
                                    ).format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: pickDate,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            if (!noCollection)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal.shade700,
                                ),
                                onPressed: handleBuildPdf,
                                icon: const Icon(Icons.picture_as_pdf_rounded),
                                label: const Text("Generate PDF"),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // NO COLLECTION UI
                      if (noCollection)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.data_saver_off_rounded,
                                  size: 120,
                                  color: Colors.teal.shade300,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  "No collection found for this date",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      // COLLECTION LIST
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: keys.length,
                            itemBuilder: (context, index) {
                              final key = keys[index];
                              final list = cMap[key]!;

                              // Group term fees by term title
                              Map<String, List<dynamic>> termMap = {};
                              for (final f in list) {
                                final t =
                                    f['feeStructure']?['title'] ?? "Unknown";
                                termMap.putIfAbsent(t, () => []).add(f);
                              }

                              final classId = list.first['class']?['id'];

                              // Bus fees belonging to this class
                              final classBus =
                                  allPayments
                                      .where(
                                        (p) =>
                                            p['student']?['class_id'] ==
                                            classId,
                                      )
                                      .toList();

                              // RTE payments for this class
                              final classRTE =
                                  rtePayments
                                      .where(
                                        (p) =>
                                            p['class_id'] == classId ||
                                            p['classes']?['id'] == classId,
                                      )
                                      .toList();

                              // Totals
                              double classTermTotal = list.fold(
                                0.0,
                                (s, x) =>
                                    s +
                                    ((x['paid_amount'] ?? 0) as num).toDouble(),
                              );

                              double classBusTotal = classBus.fold(
                                0.0,
                                (s, x) =>
                                    s +
                                    ((x['amount_paid'] ?? 0) as num).toDouble(),
                              );

                              double classRteTotal = classRTE.fold(
                                0.0,
                                (s, x) =>
                                    s +
                                    ((x['amount_paid'] ?? 0) as num).toDouble(),
                              );

                              double classTotal =
                                  classTermTotal +
                                  classBusTotal +
                                  classRteTotal;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            key,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          Text(
                                            "₹${classTotal.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // TERM FEES SECTION
                                      ...termMap.entries.map((e) {
                                        final term = e.key;
                                        final rows = e.value;

                                        final termTotal = rows.fold<double>(
                                          0.0,
                                          (s, x) =>
                                              s +
                                              ((x['paid_amount'] ?? 0) as num)
                                                  .toDouble(),
                                        );

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              height: 2,
                                              color: Colors.teal.shade200,
                                            ),

                                            Text(
                                              term,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            Table(
                                              columnWidths: const {
                                                0: FixedColumnWidth(40),
                                                1: FlexColumnWidth(),
                                                2: FixedColumnWidth(100),
                                              },
                                              children: [
                                                TableRow(
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                  ),
                                                  children: [
                                                    headerCell("S.No"),
                                                    headerCell("Student"),
                                                    headerCell("Amount (₹)"),
                                                  ],
                                                ),
                                                ...List.generate(rows.length, (
                                                  i,
                                                ) {
                                                  final fee = rows[i];
                                                  final adm =
                                                      fee['username'] ?? "";
                                                  final name =
                                                      fee['user']?['name'] ??
                                                      fee['student_name'] ??
                                                      "Unknown";
                                                  final amt =
                                                      fee['paid_amount'] ?? 0;

                                                  return TableRow(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          i % 2 == 0
                                                              ? Colors
                                                                  .grey
                                                                  .shade100
                                                              : Colors.white,
                                                    ),
                                                    children: [
                                                      bodyCell("${i + 1}"),
                                                      bodyCell(
                                                        "$name\nAdm No: $adm",
                                                      ),
                                                      bodyCell(
                                                        "₹$amt",
                                                        alignRight: true,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                                TableRow(
                                                  children: [
                                                    const SizedBox(),
                                                    bodyCell(
                                                      "Term Total",
                                                      bold: true,
                                                    ),
                                                    bodyCell(
                                                      "₹${termTotal.toStringAsFixed(2)}",
                                                      alignRight: true,
                                                      bold: true,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }),

                                      // RTE COLLECTION BELOW TERM FEE
                                      if (classRTE.isNotEmpty) ...[
                                        const SizedBox(height: 16),

                                        Text(
                                          "RTE Fee Collection",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        ...classRTE.map((p) {
                                          final adm =
                                              p['student']?['username'] ?? "";
                                          final nm =
                                              p['student']?['name'] ??
                                              "Unknown";
                                          final amt = p['amount_paid'] ?? 0;

                                          return ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                ),
                                            title: Text("$nm (Adm No: $adm)"),
                                            trailing: Text(
                                              "₹$amt",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],

                                      // BUS COLLECTION
                                      if (classBus.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          "Bus Fee Collection",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...classBus.map((p) {
                                          final adm =
                                              p['student']?['username'] ?? "";
                                          final nm =
                                              p['student']?['name'] ??
                                              "Unknown";
                                          final amt = p['amount_paid'] ?? 0;

                                          return ListTile(
                                            dense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                ),
                                            title: Text("$nm (Adm No: $adm)"),
                                            trailing: Text(
                                              "₹$amt",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  Widget bodyCell(String text, {bool bold = false, bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
