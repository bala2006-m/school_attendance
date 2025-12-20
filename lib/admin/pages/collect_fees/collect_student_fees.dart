import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/collect_fees/widgets/widget.dart';
import 'package:school_attendance/services/term_fee_structure_api.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import 'collect_fees_classes.dart';

class CollectStudentFees extends StatefulWidget {
  const CollectStudentFees({
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
  State<CollectStudentFees> createState() => CollectStudentFeesState();
}

class CollectStudentFeesState extends State<CollectStudentFees> {
  static List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  List<Map<String, dynamic>> feeStructures = [];
  Map<int, Map<String, dynamic>> studentPayments = {};
  bool isLoading = true;
  static int? selectedStudentIndex;
  String searchTerm = '';
  // final ScrollController _scrollController = ScrollController();

  // ✅ Added persistent controllers and selected dates
  Map<String, String> amountControllers = {};
  final Map<String, DateTime> selectedDates = {};
  Map<String, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    students = await TeacherApiServices.fetchNonRteStudentData(
      schoolId: widget.schoolId.toString(),
      classId: widget.classId.toString(),
    );
    feeStructures =
        (await AdminApiService.getFeeStructuresByClass(
              schoolId: widget.schoolId,
              classId: widget.classId,
            ))
            .where(
              (fee) =>
                  (fee['status'] ?? '').toString().toLowerCase() == 'active',
            )
            .toList();
    setState(() {
      students.sort((a, b) {
        final aUsername = a['username'];
        final bUsername = b['username'];

        final aNum = num.tryParse(aUsername.toString());
        final bNum = num.tryParse(bUsername.toString());

        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        } else {
          return aUsername.toString().compareTo(bUsername.toString());
        }
      });
    });
    filteredStudents = students;
    studentPayments.clear();
    selectedStudentIndex = null;

    // ✅ Clear controllers and dates on refresh
    amountControllers.clear();
    selectedDates.clear();

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => isLoading = false);
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CollectFeesClasses(
              schoolId: widget.schoolId.toString(),
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  void _filterStudents(String query) {
    setState(() {
      searchTerm = query;
      filteredStudents =
          students
              .where(
                (s) =>
                    (s['name'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    (s['username'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  Future<void> fetchStudentFees({required String username}) async {
    final data = await TermFeeStructureApi.getStudentFeeByUsername(
      username: username,
      schoolId: widget.schoolId,
      classId: widget.classId,
    );
    if (data.isNotEmpty) {
      setState(() {
        studentPayments.clear();

        for (var feeData in data) {
          final int feeId = feeData['id'];

          // If fee already exists in map, merge payments
          if (studentPayments.containsKey(feeId)) {
            final existing = studentPayments[feeId]!;

            // Merge payments list
            final existingPayments =
                (existing['payments'] as List<dynamic>?) ?? [];
            final newPayments = (feeData['payments'] as List<dynamic>?) ?? [];
            existingPayments.addAll(newPayments);

            // Update total paid_amount
            final int totalPaid = existingPayments.fold<int>(
              0,
              (sum, p) => sum + (int.parse(p['amount'].toString())),
            );

            existing['payments'] = existingPayments;
            existing['paid_amount'] = totalPaid;

            // Update status if fully paid
            final totalAmount =
                int.tryParse(existing['total_amount'].toString()) ?? 0;
            if (totalPaid >= totalAmount) {
              existing['status'] = 'PAID';
            } else if (totalPaid > 0) {
              existing['status'] = 'PARTIALLY_PAID';
            } else {
              existing['status'] = 'UNPAID';
            }

            studentPayments[feeId] = existing;
          } else {
            // No existing record — add fresh
            final payments = (feeData['payments'] as List<dynamic>?) ?? [];
            final int totalPaid = payments.fold<int>(
              0,
              (sum, p) => sum + (int.parse(p['amount'].toString())),
            );

            feeData['paid_amount'] = totalPaid;

            final totalAmount =
                int.tryParse(feeData['total_amount'].toString()) ?? 0;
            if (totalPaid >= totalAmount) {
              feeData['status'] = 'PAID';
            } else if (totalPaid > 0) {
              feeData['status'] = 'PARTIALLY_PAID';
            } else {
              feeData['status'] = 'UNPAID';
            }

            studentPayments[feeId] = feeData;
          }
        }
      });
    } else {
      setState(() {
        studentPayments.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Collect Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Collect Fees',
                    onBack: () => onWillPop(),
                  ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child:
              isLoading
                  ? Center(
                    key: const ValueKey('loading'),
                    child: SpinKitFadingCircle(
                      color: Colors.blueAccent,
                      size: 60.0,
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: init,
                    child: Container(
                      color: Colors.grey[100],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child:
                          feeStructures.isEmpty || feeStructures == []
                              ? Center(child: Text('No fee found'))
                              : isWide
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildStudentSection(
                                      students: students,
                                      filteredStudents: filteredStudents,
                                      selectedStudentIndex:
                                          selectedStudentIndex,
                                      searchTerm: searchTerm,
                                      filterStudents: _filterStudents,
                                      context: context,
                                      fetchStudentFees: fetchStudentFees,
                                      username: widget.username,
                                      schoolId: widget.schoolId,
                                      classId: widget.classId,
                                      feeStructures: feeStructures,
                                      studentPayments: studentPayments,
                                      amountControllers:
                                          amountControllers, // ✅ added
                                      selectedDates: selectedDates, // ✅ added
                                      textControllers:
                                          textControllers, // ✅ added
                                    ),
                                  ),
                                ],
                              )
                              : SingleChildScrollView(
                                child: SizedBox(
                                  child: Column(
                                    children: [
                                      buildStudentSection(
                                        students: students,
                                        filteredStudents: filteredStudents,
                                        selectedStudentIndex:
                                            selectedStudentIndex,
                                        searchTerm: searchTerm,
                                        filterStudents: _filterStudents,
                                        context: context,
                                        fetchStudentFees: fetchStudentFees,
                                        username: widget.username,
                                        schoolId: widget.schoolId,
                                        classId: widget.classId,
                                        feeStructures: feeStructures,
                                        studentPayments: studentPayments,
                                        amountControllers: amountControllers,
                                        selectedDates: selectedDates,
                                        textControllers: textControllers,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                    ),
                  ),
        ),
      ),
    );
  }
}
