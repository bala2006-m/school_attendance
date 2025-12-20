import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/rte_fees_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/build_classes.dart';
import '../../dashboard/admin_dashboard.dart';

class CollectRteFees extends StatefulWidget {
  const CollectRteFees({
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
  State<CollectRteFees> createState() => _CollectRteFeesState();
}

class _CollectRteFeesState extends State<CollectRteFees> {
  final RteFeesService _service = RteFeesService();
  // final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> rteStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  List<Map<String, dynamic>> feeStructures = [];
  Map<int, List<Map<String, dynamic>>> paymentsByFee = {};

  int? selectedIndex;
  String searchTerm = "";
  bool loadingStudents = false;
  bool loadingFees = false;

  final Map<int, TextEditingController> amountControllers = {};
  final Map<int, DateTime> pickedDates = {};

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => loadingStudents = true);
    final resp = await _service.getRteStudentsBySchool(
      widget.schoolId,
      classId: widget.classId,
    );
    rteStudents = resp?.cast<Map<String, dynamic>>() ?? [];
    filteredStudents = List.from(rteStudents);
    setState(() => loadingStudents = false);
  }

  Future<void> loadFeeData(String studentId) async {
    setState(() => loadingFees = true);

    final structures = await _service.getActiveStructuresBySchool(
      widget.schoolId,
      classId: widget.classId,
    );
    feeStructures = structures?.cast<Map<String, dynamic>>() ?? [];

    final paymentList = await _service.listPayments(
      widget.schoolId,
      studentId: studentId,
    );

    paymentsByFee.clear();
    if (paymentList != null) {
      for (final p in paymentList) {
        final feeId = p["rte_fee_structure_id"];
        paymentsByFee.putIfAbsent(feeId, () => []);
        paymentsByFee[feeId]!.add(p);
      }
    }

    // Clear previous controllers and dates
    amountControllers.clear();
    pickedDates.clear();

    setState(() => loadingFees = false);

    // Future.delayed(const Duration(milliseconds: 300), () {
    //   scrollController.animateTo(
    //     scrollController.position.maxScrollExtent,
    //     duration: const Duration(milliseconds: 600),
    //     curve: Curves.easeOut,
    //   );
    // });
  }

  void filterSearch(String term) {
    searchTerm = term;
    if (term.isEmpty) {
      filteredStudents = List.from(rteStudents);
    } else {
      filteredStudents =
          rteStudents.where((s) {
            final name = (s["name"] ?? "").toLowerCase();
            final id = s["username"].toString();
            return name.contains(term.toLowerCase()) || id.contains(term);
          }).toList();
    }
    setState(() {});
  }

  Future<void> sendWhatsAppMessage(String phone, String message) async {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) phone = "91$phone";

    final whatsappUrl = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    try {
      final canLaunch = await canLaunchUrl(whatsappUrl);
      if (!canLaunch) throw "WhatsApp not installed";
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("WhatsApp Launch Error: $e");
    }
  }

  Future<bool> confirmWhatsAppSend(BuildContext context, String mobile) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Send WhatsApp Message?"),
              content: Text(
                "Do you want to send payment confirmation to $mobile?",
              ),
              actions: [
                TextButton(
                  child: const Text("No"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                ElevatedButton(
                  child: const Text("Yes"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void payRteFee({
    required int structureId,
    required int amount,
    required String method,
    required String studentId,
    required String name,
    required String mobile,
    required String className,
    required String section,
    required String schoolName,
    required String schoolAddress,
    required DateTime date,
  }) async {
    final total =
        int.tryParse(
          feeStructures
              .firstWhere((f) => f["id"] == structureId)["total_amount"]
              .toString(),
        ) ??
        0;

    final payments = paymentsByFee[structureId] ?? [];
    final alreadyPaid = payments.fold(
      0,
      (sum, p) => sum + int.parse(p["amount_paid"].toString()),
    );

    final newTotal = alreadyPaid + amount;
    final status = newTotal >= total ? "PAID" : "PARTIALLY_PAID";
    final remaining = total - newTotal;

    final referenceNo =
        method.toUpperCase() == "ONLINE"
            ? "TXN-${DateTime.now().millisecondsSinceEpoch}"
            : "-";

    final payload = {
      "school_id": widget.schoolId,
      "class_id": widget.classId,
      "student_id": studentId,
      "rte_fee_structure_id": structureId,
      "amount_paid": amount,
      "payment_mode": method.toUpperCase(),
      "reference_number": referenceNo,
      "created_by": widget.username,
      "status": status,
      'payment_date': DateFormat('yyyy-MM-dd').format(date).toString(),
    };

    final resp = await _service.createPayment(payload);

    if (resp != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == "PAID"
                ? "Full payment completed!"
                : "Partial payment recorded.",
          ),
          backgroundColor: status == "PAID" ? Colors.green : Colors.orange,
        ),
      );

      loadFeeData(studentId);

      final shouldSend = await confirmWhatsAppSend(context, mobile);

      if (shouldSend) {
        final message =
            StringBuffer()
              ..writeln("  Payment Confirmation")
              ..writeln("----------------------------------------")
              ..writeln("")
              ..writeln(
                "This is an official fee payment confirmation message from $schoolName , $schoolAddress",
              )
              ..writeln("")
              ..writeln("    Student Details:")
              ..writeln("")
              ..writeln("Admin No    : $studentId")
              ..writeln("Name           : $name")
              ..writeln("Class            : $className - $section")
              ..writeln("")
              ..writeln("    Payment Details:")
              ..writeln("")
              ..writeln("Fee Type                  : RTE Fee")
              ..writeln(
                "Total Fee                 : ₹${total.toStringAsFixed(1)}",
              )
              ..writeln("Amount Received   : ₹${amount.toStringAsFixed(1)}")
              ..writeln(
                "Already Paid           : ₹${alreadyPaid.toStringAsFixed(1)}",
              )
              ..writeln(
                "Balance                   : ₹${remaining.toStringAsFixed(1)}",
              )
              ..writeln(
                "Date                         : ${DateFormat('dd-MM-yyyy').format(date)}",
              )
              ..writeln("")
              ..writeln("Payment Mode       : ${method.toUpperCase()}")
              ..writeln("")
              ..writeln("-----------------------------------------------------")
              ..writeln("    Thank you for your payment.");

        try {
          await sendWhatsAppMessage(mobile, message.toString());
        } catch (_) {}
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment failed!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BuildClasses(
              schoolId: widget.schoolId.toString(),
              username: widget.username,
              title: 'Class List',
              onTap: ({
                required String schoolId,
                required String username,
                required String className,
                required String section,
                required String classId,
              }) {
                return CollectRteFees(
                  schoolId: widget.schoolId,
                  username: username,
                  className: className,
                  section: section,
                  classId: int.parse(classId),
                );
              },
              onWillPop: AdminDashboard(
                schoolId: widget.schoolId.toString(),
                username: widget.username,
              ),
            ),
      ),
    );
    return false;
  }

  // ===================== STUDENT SECTION =====================
  Widget buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search name or Adm. No",
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon:
                  searchTerm.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => filterSearch(""),
                      )
                      : null,
            ),
            onChanged: filterSearch,
          ),
        ),
        const SizedBox(height: 14),
        loadingStudents
            ? const Center(child: CircularProgressIndicator())
            : filteredStudents.isEmpty
            ? const Center(
              child: Text(
                "No RTE Students found.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length,
              itemBuilder: (_, i) {
                final s = filteredStudents[i];
                final realIndex = rteStudents.indexOf(s);

                int totalPaid = 0;
                if (s.containsKey("payments")) {
                  for (final p in s["payments"]) {
                    totalPaid += int.tryParse(p["amount_paid"].toString()) ?? 0;
                  }
                }

                int totalFee = int.tryParse(s["total_fee"].toString()) ?? 0;
                bool fullyPaid = totalPaid >= totalFee && totalFee > 0;
                bool partiallyPaid = totalPaid > 0 && totalPaid < totalFee;
                bool isSelected = selectedIndex == realIndex;

                Color cardColor =
                    fullyPaid
                        ? Colors.green.shade100
                        : partiallyPaid
                        ? Colors.yellow.shade100
                        : Colors.white;
                if (isSelected) cardColor = Colors.blue.shade50;

                Color stripColor =
                    fullyPaid
                        ? Colors.green
                        : partiallyPaid
                        ? Colors.orange
                        : Colors.grey;
                if (isSelected) stripColor = Colors.blue;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        selectedIndex = isSelected ? null : realIndex;
                        if (selectedIndex != null) {
                          loadFeeData(s["username"].toString());
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 80,
                              decoration: BoxDecoration(
                                color: stripColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        s["name"].toString()[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s["name"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Adm: ${s["username"]}",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child:
                                          fullyPaid
                                              ? const Icon(
                                                Icons.verified,
                                                color: Colors.green,
                                                size: 30,
                                              )
                                              : partiallyPaid
                                              ? const Icon(
                                                Icons.timelapse,
                                                color: Colors.orange,
                                                size: 28,
                                              )
                                              : isSelected
                                              ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 28,
                                              )
                                              : const Icon(
                                                Icons.chevron_right,
                                                color: Colors.grey,
                                                size: 28,
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              bottom: 16,
                            ),
                            child: buildFeeSection(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }

  // ===================== FEE SECTION =====================
  Widget buildFeeSection() {
    if (selectedIndex == null) return const SizedBox();
    final student = rteStudents[selectedIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        loadingFees
            ? const Center(child: CircularProgressIndicator())
            : feeStructures.isEmpty
            ? const Text("No RTE Fee Structures found.")
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feeStructures.length,
              itemBuilder: (_, i) {
                final f = feeStructures[i];
                final structureId = f["id"];
                final total = int.tryParse(f["total_amount"].toString()) ?? 0;
                final payments = paymentsByFee[structureId] ?? [];
                final paid = payments.fold(
                  0,
                  (sum, p) => sum + int.parse(p["amount_paid"].toString()),
                );
                final due = total - paid;
                final fullyPaid = due <= 0;

                // Persistent controller & date
                amountControllers.putIfAbsent(
                  structureId,
                  () => TextEditingController(text: due.toString()),
                );
                pickedDates.putIfAbsent(structureId, () => DateTime.now());

                final controller = amountControllers[structureId]!;
                // final pickedDate = pickedDates[structureId]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        fullyPaid ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: fullyPaid ? Colors.green : Colors.blueAccent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RTE Fee",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text("Total: ₹$total"),
                      Text("Paid: ₹$paid"),
                      Text(
                        "Remaining: ₹$due",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (fullyPaid)
                        Center(
                          child: Chip(
                            backgroundColor: Colors.green,
                            label: const Text(
                              "✔ Fully Collected",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      if (!fullyPaid)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final newDate = await showDatePicker(
                                  context: context,
                                  initialDate: pickedDates[structureId]!,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (newDate != null) {
                                  setState(
                                    () => pickedDates[structureId] = newDate,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blueAccent),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Date: ${pickedDates[structureId]!.toLocal().toString().split(' ')[0]}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: "Enter Amount",
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    final value =
                                        double.tryParse(controller.text) ?? 0;
                                    if (value <= 0 || value > due) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Enter valid amount up to ₹$due",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    payRteFee(
                                      structureId: structureId,
                                      amount: value.toInt(),
                                      method: "cash",
                                      studentId: student['username'],
                                      name: student['name'],
                                      mobile: student['mobile'],
                                      className: widget.className,
                                      section: widget.section,
                                      schoolAddress:
                                          student['school']['address'],
                                      schoolName: student['school']['name'],
                                      date: pickedDates[structureId]!,
                                    );
                                  },
                                  child: const Text(
                                    "Cash",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () {
                                    final value =
                                        double.tryParse(controller.text) ?? 0;
                                    if (value <= 0 || value > due) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Enter valid amount up to ₹$due",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    payRteFee(
                                      structureId: structureId,
                                      amount: value.toInt(),
                                      method: "online",
                                      studentId: student['username'],
                                      name: student['name'],
                                      mobile: student['mobile'],
                                      className: widget.className,
                                      section: widget.section,
                                      schoolAddress:
                                          student['school']['address'],
                                      schoolName: student['school']['name'],
                                      date: pickedDates[structureId]!,
                                    );
                                  },
                                  child: const Text(
                                    "Online",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
      ],
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Collect RTE Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId.toString(),
                    username: widget.username,
                    title: 'Collect RTE Fees',
                    onBack: () => onWillPop(),
                  ),
        ),
        body: SingleChildScrollView(
          // controller: scrollController,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [buildStudentSection()],
          ),
        ),
      ),
    );
  }
}
