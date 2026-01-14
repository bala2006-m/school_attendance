import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../services/api_service.dart';
import '../../../../services/finance_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class Expense extends StatefulWidget {
  const Expense({super.key, required this.schoolId, required this.username});
  final String schoolId;
  final String username;
  @override
  State<Expense> createState() => _ExpenseState();
}

enum IncomeFilter { day, month, year, periodical }

class _ExpenseState extends State<Expense> with SingleTickerProviderStateMixin {
  final FinanceService financeApi = FinanceService();
  late TabController _tabController;
  bool isLoading = true;
  String schoolName = '';
  String schoolAddress = '';
  Uint8List schoolPhotoBytes = Uint8List(0);
  List<dynamic> finance = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAll();
    _fetchSchoolInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _initAll() async {
    try {
      final fetched = await financeApi.getAllExpense(schoolId: widget.schoolId);
      finance = fetched;
    } catch (_) {
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
                    title: 'Total Expense',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Total Expense',
                    onBack: onWillPop,
                  ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Home'), Tab(text: 'Add')],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [homeTab(), addTab()],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget addTab() {
    // final int totalExpense = finance.fold<int>(
    //   0,
    //   (sum, item) => sum + (item['amount'] as int? ?? 0),
    // );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ---------- PROFILE CARD ----------
            BuildProfileCard(
              schoolPhoto: Image.memory(schoolPhotoBytes),
              schoolAddress: schoolAddress,
              schoolName: schoolName,
            ),

            const SizedBox(height: 20),

            // ---------- ADD EXPENSE BUTTON ----------
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddIncomeDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Expense',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- TOTAL EXPENSE CARD ----------
            // if (finance.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 12),
            //     child: Container(
            //       padding: const EdgeInsets.all(16),
            //       decoration: BoxDecoration(
            //         color: Colors.blue.shade50,
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Text(
            //             "Total Expense",
            //             style: TextStyle(
            //               fontSize: 18,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //           Text(
            //             "₹$totalExpense",
            //             style: const TextStyle(
            //               fontSize: 20,
            //               fontWeight: FontWeight.bold,
            //               color: Colors.blue,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            const SizedBox(height: 20),
            Divider(),
            // ---------- SECTION TITLE ----------
            const Text(
              "Expenses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // ---------- EXPENSE LIST ----------
            finance.isNotEmpty
                ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: finance.length,
                  itemBuilder: (context, index) {
                    final income = finance[index];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Card(
                        // margin: const EdgeInsets.symmetric(
                        //   vertical: 6,
                        //   horizontal: 12,
                        // ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),

                          // AMOUNT
                          title: Text(
                            "Amount: ₹${income['amount']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // REASON
                          subtitle: Text(
                            "Reason: ${income["reason"]}",
                            style: const TextStyle(fontSize: 14),
                          ),

                          // EDIT + DELETE BUTTONS
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed:
                                    () => _showUpdateIncomeDialog(income),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteIncome(income['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
                // ---------- EMPTY STATE ----------
                : Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: const [
                      Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No expenses found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddIncomeDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = {
                    'school_id': int.parse(widget.schoolId),
                    'amount': double.parse(amountController.text),
                    'reason': reasonController.text,
                    'type': 'EXPENSE',
                    'created_by': widget.username,
                    'updated_by': widget.username,
                  };
                  await financeApi.createFinance(data);
                  await _initAll();

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() {});
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateIncomeDialog(Map<String, dynamic> income) async {
    final amountController = TextEditingController(
      text: income['amount'].toString(),
    );
    final reasonController = TextEditingController(
      text: income['reason'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = {
                    'amount': double.parse(amountController.text),
                    'reason': reasonController.text,
                    'updated_by': widget.username,
                  };

                  await financeApi.updateFinance(income['id'], data);

                  await _initAll(); // <--- refresh

                  if (context.mounted) Navigator.pop(context);
                } catch (_) {}
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteIncome(int incomeId) async {
    try {
      await financeApi.deleteFinance(incomeId);
      await _initAll(); // <--- refresh
    } catch (e) {
      setState(() {});
    }
  }

  Widget homeTab() {
    // Calculate total amount
    final totalAmount = finance.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            /// School Card
            BuildProfileCard(
              schoolPhoto: Image.memory(schoolPhotoBytes),
              schoolAddress: schoolAddress,
              schoolName: schoolName,
            ),

            const SizedBox(height: 20),

            if (finance.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No expenses found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Center(
                        child: Text(
                          "Overall Expense",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of incomes
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: finance.length,
                        separatorBuilder:
                            (_, __) => const SizedBox(height: 6), // small gap
                        itemBuilder: (context, index) {
                          final item = finance[index];
                          final d =
                              item['updated_at'] != null
                                  ? DateTime.parse(
                                    item['updated_at'].toString(),
                                  ).toLocal()
                                  : null;
                          final date =
                              d != null
                                  ? DateFormat('d/M/yyyy').format(d)
                                  : null;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left text (reason + optional date on next line)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['reason']?.toString() ?? 'N/A',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (date != null)
                                      Text(
                                        "($date)",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Right text (amount)
                              Text(
                                item['amount'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(),

                      // Grand total row
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Grand Total",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              totalAmount.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
