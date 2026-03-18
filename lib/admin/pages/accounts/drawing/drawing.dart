import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../services/account_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/finance_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class Drawing extends StatefulWidget {
  const Drawing({super.key, required this.schoolId, required this.username});

  final String schoolId;
  final String username;

  @override
  State<Drawing> createState() => _DrawingState();
}

class _DrawingState extends State<Drawing> with SingleTickerProviderStateMixin {
  final FinanceService financeApi = FinanceService();
  late TabController _tabController;

  bool isLoading = true;

  String schoolName = '';
  String schoolAddress = '';
  Uint8List schoolPhotoBytes = Uint8List(0);

  List<dynamic> drawingIn = [];
  List<dynamic> drawingOut = [];
  List<dynamic> incomes = [];
  List<dynamic> expenses = [];
  Map<String, dynamic> allFees = {};
  int cashOnHand = 0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAll();
    _fetchSchoolInfo();
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
      drawingIn = await financeApi.getAllDrawingIN(schoolId: widget.schoolId);
      drawingOut = await financeApi.getAllDrawingOUT(schoolId: widget.schoolId);
      final fees = await AccountService.fetchAll(
        schoolId: int.parse(widget.schoolId),
      );
      final incomeList = List.from(
        await financeApi.getAllIncome(schoolId: widget.schoolId),
      );
      final expenseList = List.from(
        await financeApi.getAllExpense(schoolId: widget.schoolId),
      );
      final otherIncomeTotal = incomeList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      final expenseTotal = expenseList.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      final drawingInTotal = drawingIn.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      final drawingOutTotal = drawingOut.fold<double>(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );
      cashOnHand =
          fees['termCash'] +
          fees['busCash'] +
          fees['rteCash'] +
          otherIncomeTotal.toInt() +
          drawingInTotal.toInt() -
          drawingOutTotal.toInt() -
          expenseTotal.toInt();
    } catch (e) {
      drawingIn = [];
      drawingOut = [];
      incomes = [];
      expenses = [];
      allFees = {};
    }

    if (mounted) setState(() {});
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
                    title: 'Drawing',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Drawing',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card --------------------------------------------------------
          BuildProfileCard(
            schoolPhoto: Image.memory(schoolPhotoBytes),
            schoolAddress: schoolAddress,
            schoolName: schoolName,
          ),

          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cash ON Hand:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹$cashOnHand',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ADD BUTTON ----------------------------------------------------------
          Center(
            child: SizedBox(
              width: 180,
              height: 45,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 22, color: Colors.white),
                label: const Text(
                  "Add Drawing",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: _showAddDrawingDialog,
              ),
            ),
          ),

          const SizedBox(height: 25),
          Divider(),
          // SECTION TITLE -------------------------------------------------------
          Text(
            "All Drawings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),

          // CARD CONTAINER FOR LIST ---------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                drawingIn.isEmpty && drawingOut.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No drawings found.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (drawingIn.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 10,
                              bottom: 5,
                            ),
                            child: Text(
                              "Drawing In",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),

                        ...drawingIn.map((i) => drawingTile(i, Colors.green)),

                        if (drawingOut.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 20,
                              bottom: 5,
                            ),
                            child: Text(
                              "Drawing Out",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),

                        ...drawingOut.map((i) => drawingTile(i, Colors.red)),
                      ],
                    ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget drawingTile(Map<String, dynamic> item, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          "Amount: ₹${item['amount']}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Reason: ${item['reason']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showUpdateDrawingDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDrawing(item['id']),
            ),
          ],
        ),
      ),
    );
  }

  // ADD DRAWING DIALOG --------------------------------------------------------

  Future<void> _showAddDrawingDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String type = "DRAWING_IN";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Drawing"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: "Reason"),
              ),
              DropdownButtonFormField(
                initialValue: type,
                decoration: const InputDecoration(labelText: "Type"),
                items: const [
                  DropdownMenuItem(
                    value: "DRAWING_IN",
                    child: Text("Drawing In"),
                  ),
                  DropdownMenuItem(
                    value: "DRAWING_OUT",
                    child: Text("Drawing Out"),
                  ),
                ],
                onChanged: (v) => type = v!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) return;

                final amount = double.tryParse(amountText) ?? 0;

                // Block if Drawing Out > cashOnHand
                if (type == "DRAWING_OUT" && amount > cashOnHand) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Drawing Out cannot be more than Cash On Hand',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final data = {
                  'school_id': int.parse(widget.schoolId),
                  'amount': amount,
                  'reason': reasonController.text,
                  'type': type,
                  'created_by': widget.username,
                  'updated_by': widget.username,
                };

                await financeApi.createFinance(data);
                await _initAll();

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // UPDATE DRAWING -----------------------------------------------------------

  Future<void> _showUpdateDrawingDialog(Map<String, dynamic> item) async {
    final amountController = TextEditingController(
      text: item['amount'].toString(),
    );
    final reasonController = TextEditingController(
      text: item['reason'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Drawing"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: "Reason"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) return;

                final amount = double.tryParse(amountText) ?? 0;

                if (item['type'] == "DRAWING_OUT" && amount > cashOnHand) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Drawing Out cannot be more than Cash On Hand',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final data = {
                  'amount': amount,
                  'reason': reasonController.text,
                  'updated_by': widget.username,
                };

                await financeApi.updateFinance(item['id'], data);
                await _initAll();

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDrawing(int id) async {
    await financeApi.deleteFinance(id);
    await _initAll();
  }

  // ---------------------------------------------------------------------------
  // HOME TAB
  // ---------------------------------------------------------------------------

  Widget homeTab() {
    // TOTALS
    final totalDrawingIn = drawingIn.fold<double>(
      0.0,
      (s, i) => s + (double.tryParse(i['amount'].toString()) ?? 0),
    );

    final totalDrawingOut = drawingOut.fold<double>(
      0.0,
      (s, i) => s + (double.tryParse(i['amount'].toString()) ?? 0),
    );

    // final totalIncome = incomes.fold<double>(
    //   0.0,
    //   (s, i) => s + (double.tryParse(i['amount'].toString()) ?? 0),
    // );
    //
    // final totalExpense = expenses.fold<double>(
    //   0.0,
    //   (s, i) => s + (double.tryParse(i['amount'].toString()) ?? 0),
    // );

    // // FEES
    // final termFee =
    //     double.tryParse(allFees["termFeesTotal"]?.toString() ?? "0") ?? 0;
    // final busFee =
    //     double.tryParse(allFees["busFeeTotal"]?.toString() ?? "0") ?? 0;
    // final rteFee =
    //     double.tryParse(allFees["rteFeesTotal"]?.toString() ?? "0") ?? 0;

    // NET BALANCE
    // final netBalance =
    //     (totalDrawingIn + totalIncome + termFee + busFee + rteFee) -
    //     (totalDrawingOut + totalExpense);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          BuildProfileCard(
            schoolPhoto: Image.memory(schoolPhotoBytes),
            schoolAddress: schoolAddress,
            schoolName: schoolName,
          ),

          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cash ON Hand:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹$cashOnHand',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (drawingIn.isEmpty &&
              drawingOut.isEmpty &&
              incomes.isEmpty &&
              expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No financial records found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Column(
              children: [
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        totalRow(
                          "Total Drawing In",
                          totalDrawingIn,
                          Colors.black,
                        ),
                        totalRow(
                          "Total Drawing Out",
                          totalDrawingOut,
                          Colors.black,
                        ),

                        // totalRow("Total Income", totalIncome, Colors.blue),
                        // totalRow("Total Expense", totalExpense, Colors.orange),
                        //
                        // // FEES
                        // totalRow("Term Fees", termFee, Colors.purple),
                        // totalRow("Bus Fees", busFee, Colors.brown),
                        // totalRow("RTE Fees", rteFee, Colors.teal),
                        const Divider(),

                        totalRow(
                          "Cash in Drawing",
                          totalDrawingIn - totalDrawingOut,
                          Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...drawingIn.map((i) => drawingCard(i, Colors.green)),
                ...drawingOut.map((i) => drawingCard(i, Colors.red)),
                // ...incomes.map((i) => financeCard(i, Colors.blue, "Income")),
                // ...expenses.map(
                //   (i) => financeCard(i, Colors.orange, "Expense"),
                // ),

                // SUMMARY CARD
              ],
            ),
        ],
      ),
    );
  }

  Widget drawingCard(Map<String, dynamic> item, Color color) {
    final date =
        DateTime.tryParse(item['updated_at'] ?? "") != null
            ? DateFormat(
              "dd-MM-yyyy",
            ).format(DateTime.parse(item['updated_at']))
            : "N/A";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 6),
        title: Text(
          "₹ ${item['amount']}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Reason: ${item['reason']}\nDate: $date"),
      ),
    );
  }

  Widget financeCard(Map<String, dynamic> item, Color color, String label) {
    final date =
        DateTime.tryParse(item['updated_at'] ?? "") != null
            ? DateFormat(
              "dd-MM-yyyy",
            ).format(DateTime.parse(item['updated_at']))
            : "N/A";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 6),
        title: Text(
          "$label: ₹ ${item['amount']}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Reason: ${item['reason']}\nDate: $date"),
      ),
    );
  }

  Widget totalRow(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            "₹ $value",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
