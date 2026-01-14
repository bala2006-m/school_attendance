import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../../services/account_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/finance_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class Finance extends StatefulWidget {
  const Finance({super.key, required this.schoolId, required this.username});
  final String schoolId;
  final String username;
  @override
  State<Finance> createState() => _FinanceState();
}

enum IncomeFilter { all, day, month, year, term, bus, rte }

class _FinanceState extends State<Finance> {
  final FinanceService financeApi = FinanceService();
  bool isLoading = true;

  String schoolName = '';
  String schoolAddress = '';
  Uint8List schoolPhotoBytes = Uint8List(0);

  List<dynamic> finance = [];
  List<dynamic> incomeList = [];
  List<dynamic> expenseList = [];
  List<dynamic> drawingInList = [];
  List<dynamic> drawingOutList = [];
  List<dynamic> detailList = [];

  double termFeesTotal = 0;
  double termFeesCash = 0;
  double termFeesOnline = 0;
  double busFeeTotal = 0;
  double busFeeCash = 0;
  double busFeeOnline = 0;
  double rteFeesTotal = 0;
  double rteFeesCash = 0;
  double rteFeesOnline = 0;
  double otherIncomeTotal = 0;
  double expenseTotal = 0;
  double drawingInTotal = 0;
  double drawingOutTotal = 0;
  double grandTotal = 0;
  double cashTotal = 0;
  double onlineTotal = 0;
  IncomeFilter selectedFilter = IncomeFilter.all;

  DateTime? selectedDate;
  String dayLabel = 'Day';
  String monthLabel = 'Month';
  String yearLabel = 'Year';

  @override
  void initState() {
    super.initState();
    _initAll();
    _fetchSchoolInfo();
    fetchFilters(from: DateTime(2000), to: DateTime(2100));
  }

  Future<void> fetchFilters({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final filteredData = await AccountService.fetchAllPeriodical(
        schoolId: int.parse(widget.schoolId),
        from: from,
        to: to,
      );
      // print(filteredData);
      if (true) {
        final data = filteredData;
        setState(() {
          termFeesTotal = (data['termFeesTotal'] ?? 0).toDouble();
          busFeeTotal = (data['busFeeTotal'] ?? 0).toDouble();
          rteFeesTotal = (data['rteFeesTotal'] ?? 0).toDouble();
          termFeesCash = (data['termCash'] ?? 0).toDouble();
          termFeesOnline = (data['termOnline'] ?? 0).toDouble();
          busFeeCash = (data['busCash'] ?? 0).toDouble();
          busFeeOnline = (data['busOnline'] ?? 0).toDouble();

          rteFeesCash = (data['rteCash'] ?? 0).toDouble();
          rteFeesOnline = (data['rteOnline'] ?? 0).toDouble();

          // final termCash = (data['termCash'] ?? 0).toDouble();
          // // final termOnline = (data['termOnline'] ?? 0).toDouble();
          // final busCash = (data['busCash'] ?? 0).toDouble();
          // // final busOnline = (data['busOnline'] ?? 0).toDouble();
          // final rteCash = (data['rteCash'] ?? 0).toDouble();
          // final rteOnline = (data['rteFeesOnline'] ?? 0).toDouble();

          // onlineTotal = termOnline + busOnline + rteOnline;
          onlineTotal = (data['beforeCashOnBank'] ?? 0).toDouble();

          grandTotal = (data['beforetotal'] ?? 0).toDouble();
          // grandTotal =
          //     cashTotal +
          //     onlineTotal +
          //     otherIncomeTotal +
          //     drawingInTotal -
          //     expenseTotal -
          //     drawingOutTotal;

          finance = List.from(data['finance'] ?? []);
          incomeList = List.from(
            finance.where((item) => item['type'] == 'INCOME'),
          );
          expenseList = List.from(
            finance.where((item) => item['type'] == 'EXPENSE'),
          );
          drawingInList = List.from(
            finance.where((item) => item['type'] == 'DRAWING_IN'),
          );
          drawingOutList = List.from(
            finance.where((item) => item['type'] == 'DRAWING_OUT'),
          );

          otherIncomeTotal = incomeList.fold<double>(
            0,
            (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
          );
          expenseTotal = expenseList.fold<double>(
            0,
            (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
          );
          drawingInTotal = drawingInList.fold<double>(
            0,
            (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
          );
          drawingOutTotal = drawingOutList.fold<double>(
            0,
            (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
          );
          cashTotal = (data['beforeCashOnHand'] ?? 0).toDouble();
          // cashTotal =
          //     termCash +
          //     busCash +
          //     rteCash +
          //     drawingInTotal -
          //     drawingOutTotal -
          //     expenseTotal;
        });
      }
    } catch (e) {
      // print('Error fetching filters: $e');
    }
  }

  Future<void> _fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'] ?? '';
        schoolAddress = schoolData[0]['address'] ?? '';
        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      // print('Error fetching school info: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _initAll() async {
    try {
      final fees = await AccountService.fetchAll(
        schoolId: int.parse(widget.schoolId),
      );
      termFeesTotal = (fees['termFeesTotal'] ?? 0).toDouble();
      busFeeTotal = (fees['busFeeTotal'] ?? 0).toDouble();
      rteFeesTotal = (fees['rteFeesTotal'] ?? 0).toDouble();
      termFeesCash = (fees['termCash'] ?? 0).toDouble();
      termFeesOnline = (fees['termOnline'] ?? 0).toDouble();
      busFeeCash = (fees['busCash'] ?? 0).toDouble();
      busFeeOnline = (fees['busOnline'] ?? 0).toDouble();

      rteFeesCash = (fees['rteCash'] ?? 0).toDouble();
      rteFeesOnline = (fees['rteOnline'] ?? 0).toDouble();

      final termCash = (fees['termCash'] ?? 0).toDouble();
      final termOnline = (fees['termOnline'] ?? 0).toDouble();
      final busCash = (fees['busCash'] ?? 0).toDouble();
      final busOnline = (fees['busOnline'] ?? 0).toDouble();
      final rteCash = (fees['rteCash'] ?? 0).toDouble();
      final rteOnline = (fees['rteFeesOnline'] ?? 0).toDouble();

      // cashTotal = termCash + busCash + rteCash;
      onlineTotal = termOnline + busOnline + rteOnline;

      incomeList = List.from(
        await financeApi.getAllIncome(schoolId: widget.schoolId),
      );
      expenseList = List.from(
        await financeApi.getAllExpense(schoolId: widget.schoolId),
      );
      drawingInList = List.from(
        await financeApi.getAllDrawingIN(schoolId: widget.schoolId),
      );
      drawingOutList = List.from(
        await financeApi.getAllDrawingOUT(schoolId: widget.schoolId),
      );

      otherIncomeTotal = incomeList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      expenseTotal = expenseList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      drawingInTotal = drawingInList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      drawingOutTotal = drawingOutList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );

      grandTotal =
          termCash +
          busCash +
          rteCash +
          onlineTotal +
          otherIncomeTotal +
          drawingInTotal -
          expenseTotal -
          drawingOutTotal;
      cashTotal =
          termCash +
          busCash +
          rteCash +
          otherIncomeTotal +
          drawingInTotal -
          drawingOutTotal -
          expenseTotal;
      finance = List.from(expenseList);
    } catch (e) {
      // print('Error initializing finance data: $e');
      finance = [];
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  void showTermDetails() {
    detailList = List.from(
      incomeList.where((item) => item['category'] == 'TERM'),
    );
    setState(() {});
  }

  void showBusDetails() {
    detailList = List.from(
      incomeList.where((item) => item['category'] == 'BUS'),
    );
    setState(() {});
  }

  void showRTEDetails() {
    detailList = List.from(
      incomeList.where((item) => item['category'] == 'RTE'),
    );
    setState(() {});
  }

  Widget _summaryTile({
    required String title,
    required String amount,
    Color? titleColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: titleColor ?? Colors.blue, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: titleColor, size: 22),
          if (icon != null) const SizedBox(height: 6),
          Text(
            overflow: TextOverflow.ellipsis,
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: (titleColor ?? Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            softWrap: true,
            "₹ $amount",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelPadding: EdgeInsets.zero,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.blue : Colors.grey.shade300,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.blue.withValues(alpha: 0.2),
    );
  }

  Widget _paymentTile({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Finance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Finance',
                    onBack: onWillPop,
                  ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                /// Profile
                BuildProfileCard(
                  schoolPhoto: Image.memory(schoolPhotoBytes),
                  schoolAddress: schoolAddress,
                  schoolName: schoolName,
                ),

                const SizedBox(height: 20),

                /// DATE FILTERS (UNCHANGED LOGIC)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChip(
                      icon: Icons.select_all,
                      label: 'All',
                      selected: selectedFilter == IncomeFilter.all,
                      onSelected: () {
                        dayLabel = 'Day';
                        monthLabel = 'Month';
                        yearLabel = 'Year';
                        setState(() {
                          selectedFilter = IncomeFilter.all;
                          detailList = [];
                        });
                        fetchFilters(from: DateTime(2000), to: DateTime(2100));
                      },
                    ),
                    _buildChip(
                      icon: Icons.date_range,
                      label: dayLabel,
                      selected: selectedFilter == IncomeFilter.day,
                      onSelected: () async {
                        monthLabel = 'Month';
                        yearLabel = 'Year';
                        setState(() {
                          selectedFilter = IncomeFilter.day;
                          detailList = [];
                        });
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          setState(() {
                            dayLabel = DateFormat('dd MMM').format(picked);
                          });
                          await fetchFilters(from: picked, to: picked);
                        }
                      },
                    ),
                    _buildChip(
                      icon: Icons.calendar_month,
                      label: monthLabel,
                      selected: selectedFilter == IncomeFilter.month,
                      onSelected: () async {
                        dayLabel = 'Day';
                        yearLabel = 'Year';
                        setState(() {
                          selectedFilter = IncomeFilter.month;
                          detailList = [];
                        });
                        final picked = await showMonthPicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          setState(() {
                            monthLabel = DateFormat.MMMM().format(picked);
                          });
                          final firstDay = DateTime(
                            picked.year,
                            picked.month,
                            1,
                          );
                          final lastDay = DateTime(
                            picked.year,
                            picked.month + 1,
                            0,
                          );
                          await fetchFilters(from: firstDay, to: lastDay);
                        }
                      },
                    ),
                    _buildChip(
                      icon: Icons.calendar_today,
                      label: yearLabel,
                      selected: selectedFilter == IncomeFilter.year,
                      onSelected: () async {
                        dayLabel = 'Day';
                        monthLabel = 'Month';
                        setState(() {
                          selectedFilter = IncomeFilter.year;
                          detailList = [];
                        });
                        final picked = await showYearPicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            yearLabel = picked.toString();
                          });
                          await fetchFilters(
                            from: DateTime(picked, 1, 1),
                            to: DateTime(picked, 12, 31),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// FEE TYPE FILTERS (UNCHANGED LOGIC)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChip(
                      icon: Icons.pie_chart,
                      label: 'Term',
                      selected: selectedFilter == IncomeFilter.term,
                      onSelected: () {
                        setState(() {
                          selectedFilter = IncomeFilter.term;
                        });
                        showTermDetails();
                      },
                    ),
                    _buildChip(
                      icon: Icons.bus_alert,
                      label: 'Bus',
                      selected: selectedFilter == IncomeFilter.bus,
                      onSelected: () {
                        setState(() {
                          selectedFilter = IncomeFilter.bus;
                        });
                        showBusDetails();
                      },
                    ),
                    _buildChip(
                      icon: Icons.rtt,
                      label: 'RTE',
                      selected: selectedFilter == IncomeFilter.rte,
                      onSelected: () {
                        setState(() {
                          selectedFilter = IncomeFilter.rte;
                        });
                        showRTEDetails();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// TOTAL COLLECTION (UNCHANGED DATA)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Collection",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹ ${grandTotal.toStringAsFixed(0)}.00",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// SUMMARY (LOGIC 100% PRESERVED)
                if (selectedFilter == IncomeFilter.all ||
                    selectedFilter == IncomeFilter.day ||
                    selectedFilter == IncomeFilter.month ||
                    selectedFilter == IncomeFilter.year)
                  Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _summaryTile(
                            title: "Cash on hand",
                            amount: cashTotal.toStringAsFixed(0),
                            titleColor: Colors.green,
                          ),
                          _summaryTile(
                            title: "Cash on bank",
                            amount: onlineTotal.toStringAsFixed(0),
                            titleColor: Colors.blue,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _summaryTile(
                            title: "Term Fees",
                            amount: termFeesTotal.toStringAsFixed(0),
                          ),
                          _summaryTile(
                            title: "Bus Fees",
                            amount: busFeeTotal.toStringAsFixed(0),
                          ),
                          _summaryTile(
                            title: "RTE Fees",
                            amount: rteFeesTotal.toStringAsFixed(0),
                          ),
                          _summaryTile(
                            title: "Other Income",
                            amount: otherIncomeTotal.toStringAsFixed(0),
                          ),
                          _summaryTile(
                            title: "Drawing in",
                            amount: drawingInTotal.toStringAsFixed(0),
                          ),
                          _summaryTile(
                            title: "Drawing-out",
                            amount: drawingOutTotal.toStringAsFixed(0),
                            titleColor: Colors.red,
                          ),
                          _summaryTile(
                            title: "Expenses",
                            amount: expenseTotal.toStringAsFixed(0),
                            titleColor: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                if (selectedFilter == IncomeFilter.term)
                  Card(
                    color: Colors.grey.shade50,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Term FEES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹ ${termFeesTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _paymentTile(
                                title: 'Cash',
                                amount: termFeesCash,
                                color: Colors.green,
                                icon: Icons.payments,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.shade300,
                              ),
                              _paymentTile(
                                title: 'Online',
                                amount: termFeesOnline,
                                color: Colors.blue,
                                icon: Icons.account_balance,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (selectedFilter == IncomeFilter.bus)
                  Card(
                    color: Colors.grey.shade50,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bus FEES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹ ${busFeeTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _paymentTile(
                                title: 'Cash',
                                amount: busFeeCash,
                                color: Colors.green,
                                icon: Icons.payments,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.shade300,
                              ),
                              _paymentTile(
                                title: 'Online',
                                amount: busFeeOnline,
                                color: Colors.blue,
                                icon: Icons.account_balance,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (selectedFilter == IncomeFilter.rte)
                  Card(
                    color: Colors.grey.shade50,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'RTE FEES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹ ${rteFeesTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _paymentTile(
                                title: 'Cash',
                                amount: rteFeesCash,
                                color: Colors.green,
                                icon: Icons.payments,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey.shade300,
                              ),
                              _paymentTile(
                                title: 'Online',
                                amount: rteFeesOnline,
                                color: Colors.blue,
                                icon: Icons.account_balance,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // /// DETAILS (UNCHANGED)
                // if (detailList.isNotEmpty)
                //   Container(
                //     margin: const EdgeInsets.symmetric(vertical: 16),
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(16),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const Text(
                //           "Details",
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const SizedBox(height: 12),
                //         ListView.builder(
                //           shrinkWrap: true,
                //           physics: const NeverScrollableScrollPhysics(),
                //           itemCount: detailList.length,
                //           itemBuilder: (context, index) {
                //             final item = detailList[index];
                //             return ListTile(
                //               title: Text(item['description'] ?? ''),
                //               trailing: Text("₹ ${item['amount']}"),
                //             );
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
