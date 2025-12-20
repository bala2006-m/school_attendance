import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/term_fee_structure_api.dart';
import '../collect_student_fees.dart';

Future<void> sendWhatsAppMessage(String phone, String message) async {
  // Remove everything except digits
  phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

  // If mobile no. is 10 digits → add India country code
  if (phone.length == 10) {
    phone = "91$phone";
  }

  final whatsappUrl = Uri.parse("https://wa.me/$phone?text=$message");

  try {
    final canLaunch = await canLaunchUrl(whatsappUrl);

    if (!canLaunch) {
      throw "WhatsApp not installed";
    }

    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint("WhatsApp Launch Error: $e");
    throw "Could not open WhatsApp";
  }
}

// Declare in main.dart or a global file
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

Future<void> payByCash(
  String username,
  int schoolId,
  int classId,
  double totalAmount,
  double paidAmount,
  double pendingAmount,
  String createdBy,
  String remarks, {
  required BuildContext context,
  required int feeId,
  required Function({required String username}) fetchStudentFees,
  required String name,
  required String mobile,
  required String className,
  required String section,
  required String schoolName,
  required String schoolAddress,
  required String date,
}) async {
  try {
    // 1️⃣ Create fee record
    final createdFee = await TermFeeStructureApi.createStudentFee({
      'school_id': schoolId,
      'class_id': classId,
      'username': username,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': paidAmount >= pendingAmount ? 'PAID' : 'PARTIALLY_PAID',
      'createdBy': createdBy,
      'remarks': remarks,
      'createdAt': date,
      'id': feeId,
    });

    final studentFeeId = createdFee['aId'];
    if (studentFeeId == null) throw Exception('Failed to get student fee id');

    // 2️⃣ Create payment entry
    await TermFeeStructureApi.createFeePayment({
      'student_fee_id': studentFeeId,
      'amount': paidAmount,
      'payment_date': date,
      'method': 'cash',
      'transaction_id': null,
      'status': 'PAID',
    });

    // 3️⃣ Refresh UI
    fetchStudentFees(username: username);

    // 4️⃣ Use safe context for SnackBar and Dialog
    final navigator = rootNavigatorKey.currentState;
    final safeContext = navigator?.overlay?.context ?? context;

    if (safeContext.mounted) {
      // ✅ SnackBar
      ScaffoldMessenger.of(safeContext).showSnackBar(
        SnackBar(
          content: Text('Cash payment of ₹$paidAmount processed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // 5️⃣ Ask for WhatsApp confirmation safely
      final shouldSend = await confirmWhatsAppSend(safeContext, mobile);

      if (shouldSend) {
        String generateShareText() {
          final buffer = StringBuffer();

          buffer.writeln("  Payment Confirmation");
          buffer.writeln("----------------------------------------");
          buffer.writeln("");
          buffer.writeln("This is an official");
          buffer.writeln("fee payment confirmation message");
          buffer.writeln("from $schoolName , $schoolAddress");
          buffer.writeln("");

          buffer.writeln("    Student Details:");
          buffer.writeln("");
          buffer.writeln("Admin No    : $username");
          buffer.writeln("Name           : $name");
          buffer.writeln("Class            : $className - $section");
          buffer.writeln("");

          buffer.writeln("    Payment Details:");
          buffer.writeln("");
          buffer.writeln("Fee Type                  : Term Fee");
          buffer.writeln("Total Fee                 : $totalAmount");
          buffer.writeln("Amount Received   : ₹$paidAmount");
          buffer.writeln(
            "Already Paid           : ₹${totalAmount - pendingAmount}",
          );
          buffer.writeln(
            "Balance                   : ₹${pendingAmount - paidAmount}",
          );
          buffer.writeln(
            "Date                         : ${DateFormat('dd-MM-yyyy').format(DateTime.parse(date))}",
          );
          buffer.writeln("");

          buffer.writeln("Payment Mode       : CASH");
          buffer.writeln("");
          buffer.writeln(
            "-----------------------------------------------------",
          );
          buffer.writeln("    Thank you for your payment.");

          return buffer.toString();
        }

        final whatsappMessage = Uri.encodeComponent(generateShareText());

        try {
          await sendWhatsAppMessage(mobile, whatsappMessage);
        } catch (e) {
          debugPrint("Failed to send WhatsApp message: $e");
        }
      }
    }
  } catch (e) {
    debugPrint(e.toString());

    final navigator = rootNavigatorKey.currentState;
    final safeContext = navigator?.overlay?.context ?? context;

    if (safeContext.mounted) {
      ScaffoldMessenger.of(safeContext).showSnackBar(
        SnackBar(
          content: Text('Failed to process cash payment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

Future<void> payOnline(
  String username,
  int schoolId,
  int classId,
  double totalAmount,
  double paidAmount,
  double pendingAmount,
  String createdBy,
  String remarks, {
  required BuildContext context,
  required int feeId,
  required Function({required String username}) fetchStudentFees,
  required String name,
  required String mobile,
  required String className,
  required String section,
  required String schoolName,
  required String schoolAddress,
  required String date,
}) async {
  try {
    // 1️⃣ Create or update student fee record
    final createdFee = await TermFeeStructureApi.createStudentFee({
      'school_id': schoolId,
      'class_id': classId,
      'username': username,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': paidAmount >= totalAmount ? 'PAID' : 'PARTIALLY_PAID',
      'createdBy': createdBy,
      'remarks': remarks,
      'createdAt': date,
      'id': feeId,
    });

    final studentFeeId = createdFee['aId'];
    if (studentFeeId == null) throw Exception('Failed to get student fee id');

    // 2️⃣ Create payment entry
    await TermFeeStructureApi.createFeePayment({
      'student_fee_id': studentFeeId,
      'amount': paidAmount,
      'payment_date': date,
      'method': 'online',
      'transaction_id': null,
      'status': 'PAID',
    });

    // 3️⃣ Refresh UI
    fetchStudentFees(username: username);

    // 4️⃣ Use safe context for SnackBar and Dialog
    final navigator = rootNavigatorKey.currentState;
    final safeContext = navigator?.overlay?.context ?? context;

    if (safeContext.mounted) {
      // ✅ SnackBar
      ScaffoldMessenger.of(safeContext).showSnackBar(
        SnackBar(
          content: Text('Online payment of ₹$paidAmount processed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // 5️⃣ Ask for WhatsApp confirmation safely
      final shouldSend = await confirmWhatsAppSend(safeContext, mobile);

      if (shouldSend) {
        String generateShareText() {
          final buffer = StringBuffer();

          buffer.writeln("  Payment Confirmation");
          buffer.writeln("----------------------------------------");
          buffer.writeln("");
          buffer.writeln("This is an official");
          buffer.writeln("fee payment confirmation message");
          buffer.writeln("from $schoolName , $schoolAddress");
          buffer.writeln("");

          buffer.writeln("    Student Details:");
          buffer.writeln("");
          buffer.writeln("Admin No    : $username");
          buffer.writeln("Name           : $name");
          buffer.writeln("Class            : $className - $section");
          buffer.writeln("");

          buffer.writeln("    Payment Details:");
          buffer.writeln("");
          buffer.writeln("Fee Type                  : Term Fee");
          buffer.writeln("Total Fee                 : $totalAmount");
          buffer.writeln("Amount Received   : ₹$paidAmount");
          buffer.writeln(
            "Already Paid           : ₹${totalAmount - pendingAmount}",
          );
          buffer.writeln(
            "Balance                   : ₹${pendingAmount - paidAmount}",
          );
          buffer.writeln(
            "Date                         : ${DateFormat('dd-MM-yyyy').format(DateTime.parse(date))}",
          );
          buffer.writeln("");

          buffer.writeln("Payment Mode       : ONLINE");
          buffer.writeln("");
          buffer.writeln(
            "-----------------------------------------------------",
          );
          buffer.writeln("    Thank you for your payment.");

          return buffer.toString();
        }

        final whatsappMessage = Uri.encodeComponent(generateShareText());

        try {
          await sendWhatsAppMessage(mobile, whatsappMessage);
        } catch (e) {
          debugPrint("Failed to send WhatsApp message: $e");
        }
      }
    }
  } catch (e) {
    debugPrint(e.toString());

    final navigator = rootNavigatorKey.currentState;
    final safeContext = navigator?.overlay?.context ?? context;

    if (safeContext.mounted) {
      ScaffoldMessenger.of(safeContext).showSnackBar(
        SnackBar(
          content: Text('Failed to process online payment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

Widget buildStudentSection({
  required List<Map<String, dynamic>> students,
  required List<Map<String, dynamic>> filteredStudents,
  required int? selectedStudentIndex,
  required String searchTerm,
  required Function(String) filterStudents,
  required BuildContext context,
  required Function({required String username}) fetchStudentFees,
  required List<Map<String, dynamic>> feeStructures,
  required Map<int, Map<String, dynamic>> studentPayments,
  required String username,
  required int schoolId,
  required int classId,
  required Map<String, DateTime> selectedDates,
  required Map<String, String> amountControllers,
  required Map<String, TextEditingController> textControllers,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Search bar
      Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search by name or admn.no",
            prefixIcon: const Icon(Icons.search, color: Colors.black),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon:
                searchTerm.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => filterStudents(''),
                    )
                    : null,
          ),
          onChanged: filterStudents,
        ),
      ),

      const SizedBox(height: 10),

      // Student list
      filteredStudents.isEmpty
          ? const Center(child: Text("No students found"))
          : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final origIndex = students.indexOf(student);
              final isSelected = selectedStudentIndex == origIndex;

              // Colors
              Color cardColor = Colors.white;
              Color stripColor = Colors.grey;
              if (isSelected) {
                cardColor = Colors.blue.shade50;
                stripColor = Colors.blue;
              }

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
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final tappedUsername = student["username"].toString();

                        // Clear this student's controllers so fee fields
                        // reinitialize with that student's remaining due
                        amountControllers.removeWhere(
                          (key, _) =>
                              key.startsWith("${tappedUsername}_amount_"),
                        );
                        textControllers.removeWhere(
                          (key, _) => key.startsWith("${tappedUsername}_txt_"),
                        );

                        CollectStudentFeesState.selectedStudentIndex =
                            origIndex;

                        await fetchStudentFees(username: tappedUsername);
                      },
                      child: Row(
                        children: [
                          // Left strip
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
                                      student["name"]
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
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
                                          student["name"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Adm: ${student["username"]}",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child:
                                        isSelected
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
                    ),

                    // Fees section
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 350),
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          bottom: 16,
                        ),
                        child: buildFeeSection(
                          feeStructures: feeStructures,
                          studentPayments: studentPayments,
                          username: username,
                          schoolId: schoolId,
                          classId: classId,
                          fetchStudentFees: fetchStudentFees,
                          students: students,
                          selectedDates: selectedDates,
                          amountControllers: amountControllers,
                          textControllers: textControllers,
                          studentUsername: student["username"],
                          context: context,
                        ),
                      ),
                      crossFadeState:
                          isSelected
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                    ),
                  ],
                ),
              );
            },
          ),
    ],
  );
}

Widget buildFeeSection({
  required List<Map<String, dynamic>> feeStructures,
  required Map<int, Map<String, dynamic>> studentPayments,
  required String username,
  required int schoolId,
  required int classId,
  required Function({required String username}) fetchStudentFees,
  required List<Map<String, dynamic>> students,
  required Map<String, DateTime> selectedDates,
  required Map<String, String> amountControllers,
  required Map<String, TextEditingController> textControllers,
  required String studentUsername,
  required BuildContext context,
}) {
  // Sort fees by end_date
  final sortedFees = List<Map<String, dynamic>>.from(feeStructures)
    ..sort((a, b) {
      final aDue = DateTime.tryParse(a["end_date"] ?? "") ?? DateTime.now();
      final bDue = DateTime.tryParse(b["end_date"] ?? "") ?? DateTime.now();
      return aDue.compareTo(bDue);
    });

  // final student = students.firstWhere((s) => s["username"] == studentUsername);

  return Column(
    children:
        sortedFees.map((fee) {
          final feeId = fee["id"];
          final feeAmount = int.tryParse(fee["total_amount"].toString()) ?? 0;

          final paymentInfo = studentPayments[feeId];
          final payments = paymentInfo?["payments"] as List<dynamic>?;

          int totalPaid = 0;
          if (payments != null) {
            totalPaid = payments.fold(
              0,
              (sum, p) => sum + int.parse(p["amount"].toString()),
            );
          }

          final dueLeft = (feeAmount - totalPaid).clamp(0, feeAmount);
          final bool isPaid = dueLeft <= 0;

          final dateKey = "${studentUsername}_date_$feeId";
          final amountKey = "${studentUsername}_amount_$feeId";
          final textControllerKey = "${studentUsername}_txt_$feeId";

          // Initialize date
          selectedDates.putIfAbsent(dateKey, () => DateTime.now());

          // Initialize controller if not exists
          if (!textControllers.containsKey(textControllerKey)) {
            final controller = TextEditingController(text: dueLeft.toString());
            controller.addListener(() {
              double entered = double.tryParse(controller.text) ?? 0;

              // Clamp to remaining due
              if (entered > dueLeft) {
                controller.text = dueLeft.toStringAsFixed(0);
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                entered = dueLeft.toDouble();
              }

              amountControllers[amountKey] = entered.toString();
            });
            textControllers[textControllerKey] = controller;
          }

          final amountController = textControllers[textControllerKey]!;

          // Ensure amountControllers has initial value
          amountControllers.putIfAbsent(amountKey, () => amountController.text);

          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPaid ? Colors.green : Colors.blueAccent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Term: ${fee["title"]}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Paid / unpaid info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total: ₹$feeAmount"),
                        Text(
                          "Paid: ₹$totalPaid",
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          "Remaining: ₹$dueLeft",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 10),
                        if (isPaid)
                          Chip(
                            backgroundColor: Colors.green,
                            label: const Text(
                              "✔ Fully Collected",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        else
                          Column(
                            children: [
                              // Date picker
                              GestureDetector(
                                onTap: () async {
                                  final newDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDates[dateKey]!,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (newDate != null) {
                                    selectedDates[dateKey] = newDate;
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                    ),
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
                                        "Date: ${selectedDates[dateKey]!.toString().split(" ")[0]}",
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

                              // Amount field
                              TextField(
                                controller: amountController,
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

                              // Buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      final value =
                                          double.tryParse(
                                            amountController.text,
                                          ) ??
                                          0;
                                      if (value <= 0 || value > dueLeft) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Enter valid amount up to ₹$dueLeft",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final s = students.firstWhere(
                                        (s) => s["username"] == studentUsername,
                                      );

                                      payByCash(
                                        studentUsername,
                                        schoolId,
                                        classId,
                                        feeAmount.toDouble(),
                                        value,
                                        dueLeft.toDouble(),
                                        username,
                                        "",
                                        context: context,
                                        feeId: feeId,
                                        fetchStudentFees: fetchStudentFees,
                                        name: s["name"],
                                        mobile: s["mobile"],
                                        schoolName: s["school"]["name"],
                                        schoolAddress: s["school"]["address"],
                                        className: s["class"]["class"],
                                        section: s["class"]["section"],
                                        date:
                                            selectedDates[dateKey]!
                                                .toString()
                                                .split(" ")[0],
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
                                          double.tryParse(
                                            amountController.text,
                                          ) ??
                                          0;
                                      if (value <= 0 || value > dueLeft) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Enter valid amount up to ₹$dueLeft",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final s = students.firstWhere(
                                        (s) => s["username"] == studentUsername,
                                      );

                                      payOnline(
                                        studentUsername,
                                        schoolId,
                                        classId,
                                        feeAmount.toDouble(),
                                        value,
                                        dueLeft.toDouble(),
                                        username,
                                        "",
                                        context: context,
                                        feeId: feeId,
                                        fetchStudentFees: fetchStudentFees,
                                        name: s["name"],
                                        mobile: s["mobile"],
                                        schoolName: s["school"]["name"],
                                        schoolAddress: s["school"]["address"],
                                        className: s["class"]["class"],
                                        section: s["class"]["section"],
                                        date:
                                            selectedDates[dateKey]!
                                                .toString()
                                                .split(" ")[0],
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
                  ],
                ),
              );
            },
          );
        }).toList(),
  );
}
