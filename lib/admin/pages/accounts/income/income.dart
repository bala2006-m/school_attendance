import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:school_attendance/admin/pages/accounts/income/widgets.dart';

import '../../../../services/account_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/finance_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class Income extends StatefulWidget {
  const Income({super.key, required this.schoolId, required this.username});

  final String schoolId;
  final String username;

  @override
  State<Income> createState() => IncomeState();
}

enum IncomeFilter { day, month, year, periodical }

class IncomeState extends State<Income> with SingleTickerProviderStateMixin {
  final FinanceService financeApi = FinanceService();

  Map<String, dynamic> allAccounts = {
    'termFeesTotal': 0,
    'busFeeTotal': 0,
    'rteFeesTotal': 0,
    'grandTotal': 0,
    'finance': [],
  };

  Map<String, dynamic> periodicalAccounts = {};

  DateTime? from;
  DateTime? to;

  bool isLoading = true;
  bool isFetchingPeriodical = false;
  late TabController _tabController;
  String schoolName = '';
  String schoolAddress = '';
  Uint8List schoolPhotoBytes = Uint8List(0);
  List<dynamic> allIncomes = [];
  static IncomeFilter? selectedFilter;

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

  // 🔥 FIXED: ALWAYS REFRESHES UI AFTER ANY OPERATION
  Future<void> _initAll() async {
    try {
      final fetched = await AccountService.fetchAll(
        schoolId: int.parse(widget.schoolId),
      );
      final finance = await financeApi.getAllIncome(schoolId: widget.schoolId);

      setState(() {
        allIncomes = finance;

        allAccounts = {
          'termFeesTotal': fetched['termFeesTotal'] ?? 0,
          'busFeeTotal': fetched['busFeeTotal'] ?? 0,
          'rteFeesTotal': fetched['rteFeesTotal'] ?? 0,
          'grandTotal': fetched['grandTotal'] ?? 0,
          'finance': finance,
        };
      });
    } catch (_) {}
  }

  Future<void> _fetchPeriodical() async {
    if (from == null || to == null) return;

    setState(() => isFetchingPeriodical = true);

    try {
      periodicalAccounts = await AccountService.fetchAllPeriodical(
        schoolId: int.parse(widget.schoolId),
        from: from!,
        to: to!,
      );
    } catch (_) {
      periodicalAccounts = {
        'termFeesTotal': 0,
        'busFeeTotal': 0,
        'rteFeesTotal': 0,
        'grandTotal': 0,
        'finance': [],
      };
    } finally {
      if (mounted) setState(() => isFetchingPeriodical = false);
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
                    title: 'Total Income',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Total Income',
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

  // ------------------ ADD TAB ------------------

  Widget addTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Profile card
          BuildProfileCard(
            schoolPhoto: Image.memory(schoolPhotoBytes),
            schoolAddress: schoolAddress,
            schoolName: schoolName,
          ),

          const SizedBox(height: 20),

          // Add Income Button
          Align(
            alignment: Alignment.center,
            child: FilledButton.icon(
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
              onPressed: _showAddIncomeDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Income"),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          // Section Header
          const Text(
            "Incomes",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Income List
          if (allAccounts['finance'] != null &&
              allAccounts['finance'].isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allAccounts['finance'].length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final income = allAccounts['finance'][index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      "Amount: ₹${income["amount"]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Reason: ${income["reason"] ?? "N/A"}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUpdateIncomeDialog(income),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteIncome(income['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: const [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No incomes found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔥 FIXED: ADD WITH AUTO REFRESH
  Future<void> _showAddIncomeDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Income'),
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
                    'type': 'INCOME',
                    'created_by': widget.username,
                    'updated_by': widget.username,
                  };

                  await financeApi.createFinance(data);
                  await _initAll(); // <--- refresh

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

  // ---------------- UPDATE INCOME ----------------

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
          title: const Text('Update Income'),
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

  // ---------------- DELETE INCOME ----------------

  // 🔥 FIXED DELETE WITH REFRESH
  Future<void> _deleteIncome(int incomeId) async {
    try {
      await financeApi.deleteFinance(incomeId);
      await _initAll(); // <--- refresh
    } catch (e) {
      setState(() {});
    }
  }

  // ---------------- HOME TAB ----------------

  Widget homeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8),
            child: BuildProfileCard(
              schoolPhoto: Image.memory(schoolPhotoBytes),
              schoolAddress: schoolAddress,
              schoolName: schoolName,
            ),
          ),
          const SizedBox(height: 12),

          // buildFilterButtonsRow(
          //   onFilterTap: onFilterTap,
          //   selectedFilter: selectedFilter,
          //   from: from,
          //   to: to,
          // ),
          //
          // const SizedBox(height: 12),
          buildOverallIncomeCard(allAccounts: allAccounts),

          const SizedBox(height: 12),

          if (selectedFilter != null)
            isFetchingPeriodical
                ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )
                : (from != null && to != null)
                ? buildFilteredIncomeCard(
                  from: from!,
                  to: to!,
                  periodicalAccounts: periodicalAccounts,
                )
                : const SizedBox(),
        ],
      ),
    );
  }

  // ---------------- FILTERS ----------------

  static String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> onFilterTap(IncomeFilter filter) async {
    selectedFilter = filter;
    setState(() {});

    final now = DateTime.now();

    if (filter == IncomeFilter.day) {
      final picked = await showDatePicker(
        context: context,
        initialDate: from ?? now,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        from = DateTime(picked.year, picked.month, picked.day);
        to = DateTime(picked.year, picked.month, picked.day);
        await _fetchPeriodical();
      }
    } else if (filter == IncomeFilter.month) {
      final picked = await showMonthPicker(
        context: context,
        initialDate: from ?? now,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        from = DateTime(picked.year, picked.month, 1);
        to = DateTime(picked.year, picked.month + 1, 0);
        await _fetchPeriodical();
      }
    } else if (filter == IncomeFilter.year) {
      final pickedYear = await showDialog<int>(
        context: context,
        builder: (_) {
          int selectedYear = from?.year ?? now.year;
          return AlertDialog(
            title: const Text('Select Year'),
            content: SizedBox(
              height: 300,
              child: YearPicker(
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 10),
                selectedDate: DateTime(selectedYear),
                onChanged: (date) => Navigator.pop(context, date.year),
              ),
            ),
          );
        },
      );

      if (pickedYear != null) {
        from = DateTime(pickedYear, 1, 1);
        to = DateTime(pickedYear, 12, 31);
        await _fetchPeriodical();
      }
    } else if (filter == IncomeFilter.periodical) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 5),
      );

      if (range != null) {
        from = DateTime(range.start.year, range.start.month, range.start.day);
        to = DateTime(range.end.year, range.end.month, range.end.day);
        await _fetchPeriodical();
      }
    }

    if (mounted) setState(() {});
  }
}
