import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/services/bus_fee_payment_api.dart';
import 'package:school_attendance/services/bus_fee_structure_api.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../dashboard/admin_dashboard.dart';
import 'widget/widgets.dart';

class CollectBusFees extends StatefulWidget {
  const CollectBusFees({
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
  State<CollectBusFees> createState() => _CollectBusFeesState();
}

class _CollectBusFeesState extends State<CollectBusFees> {
  bool isLoading = true;
  bool isPrefetching = false;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  List<dynamic> allPayments = [];
  Map<int, bool> expandedStudents = {};
  Map<int, List<dynamic>> studentFees = {};
  Map<String, List<dynamic>> routeCache = {};
  Map<String, TextEditingController> amountControllers = {};
  Map<String, DateTime> selectedDates = {};
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initAll();
  }

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

      students.sort((a, b) {
        final aUsername = a['username'];
        final bUsername = b['username'];
        final aNum = num.tryParse(aUsername.toString());
        final bNum = num.tryParse(bUsername.toString());
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        return aUsername.toString().compareTo(bUsername.toString());
      });

      filteredStudents = List.from(students);

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

      await prefetchAllFees();
    } catch (e) {
      debugPrint("Error in initAll: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> prefetchAllFees() async {
    if (students.isEmpty) return;
    setState(() => isPrefetching = true);

    for (final student in students) {
      final route = student['route'];
      final studentId = student['id'];
      final username = student['username'];

      if (route == null || route.toString().trim().isEmpty) continue;

      try {
        List<dynamic> rawFees;
        if (routeCache.containsKey(route)) {
          rawFees = List.from(routeCache[route]!);
        } else {
          rawFees = await BusFeeStructureApi.getStructuresBySchoolAndRoute(
            int.parse(widget.schoolId),
            route,
          );
          routeCache[route] = List.from(rawFees);
        }

        final fees = rawFees.map((f) => Map<String, dynamic>.from(f)).toList();

        for (int i = 0; i < fees.length; i++) {
          final fee = fees[i];
          final controllerKey = '${studentId}_$i';

          // Calculate paid amount
          final paymentsForFee =
              allPayments.where((p) {
                return p['student_id'].toString() == username.toString() &&
                    p['bus_fee_structure_id'] == fee['id'] &&
                    (p['status'] == 'PAID' || p['status'] == 'PARTIALLY_PAID');
              }).toList();

          final totalPaid = paymentsForFee.fold<double>(
            0,
            (sum, p) =>
                sum +
                (p['amount_paid'] != null
                    ? double.tryParse(p['amount_paid'].toString()) ?? 0
                    : 0),
          );

          fee['amountPaid'] = totalPaid;
          final totalAmount =
              double.tryParse(fee['total_amount'].toString()) ?? 0;
          final isPaid = totalPaid >= totalAmount;
          fee['isPaid'] = isPaid;

          if (isPaid) {
            final admin =
                paymentsForFee.isNotEmpty ? paymentsForFee.last['admin'] : null;
            fee['paidBy'] =
                admin != null ? (admin['name'] ?? 'Admin') : 'Admin';
          } else {
            fee['paidBy'] = null;
          }

          final remaining =
              (totalAmount - totalPaid).clamp(0, totalAmount).toDouble();

          if (!amountControllers.containsKey(controllerKey)) {
            amountControllers[controllerKey] = TextEditingController(
              text: formatAmount(remaining),
            );
          }

          selectedDates.putIfAbsent(controllerKey, () => DateTime.now());
        }

        studentFees[studentId] = fees;
      } catch (e) {
        studentFees[studentId] = [];
      }
    }

    setState(() => isPrefetching = false);
  }

  void filterStudents(String query) {
    setState(() {
      final lower = query.toLowerCase();
      filteredStudents =
          students.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final admn = (s['username'] ?? '').toString().toLowerCase();
            final route = (s['route'] ?? '').toString().toLowerCase();
            return name.contains(lower) ||
                admn.contains(lower) ||
                route.contains(lower);
          }).toList();
    });
  }

  Future<void> toggleStudent(int studentId) async {
    setState(() {
      // Collapse everyone
      expandedStudents.updateAll((key, value) => false);

      // Expand only tapped student
      expandedStudents[studentId] = !(expandedStudents[studentId] ?? false);
    });
  }

  Future<void> refreshData() async {
    routeCache.clear();
    studentFees.clear();
    expandedStudents.clear();
    amountControllers.forEach((key, controller) => controller.dispose());
    amountControllers.clear();
    selectedDates.clear();
    await initAll();
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
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
                return CollectBusFees(
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
  void dispose() {
    searchController.dispose();
    amountControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
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
                    title: 'Collect Bus Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Collect Bus Fees',
                    onBack: onWillPop,
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
                : RefreshIndicator(
                  onRefresh: refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (isPrefetching)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: SpinKitThreeBounce(
                              color: Colors.blueAccent,
                              size: 25.0,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          searchController.clear();
                                          filterStudents('');
                                        },
                                      )
                                      : null,
                              hintText: 'Search by name, admn. no, or route...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            controller: searchController,
                            onChanged: filterStudents,
                          ),
                        ),
                        studentList(
                          filteredStudents: filteredStudents,
                          expandedStudents: expandedStudents,
                          studentFees: studentFees,
                          toggleStudent: toggleStudent,
                          refreshData: refreshData,
                          schoolId: widget.schoolId,
                          classId: widget.classId,
                          username: widget.username,
                          context: context,
                          amountControllers: amountControllers,
                          selectedDates: selectedDates,
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
