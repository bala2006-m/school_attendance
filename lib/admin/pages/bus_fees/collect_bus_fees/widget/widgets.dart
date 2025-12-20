import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../services/bus_fee_payment_api.dart';

Future<void> sendWhatsAppMessage(String phone, String message) async {
  // Remove everything except digits
  phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

  // If mobile no. is 10 digits → add India country code
  if (phone.length == 10) {
    phone = "91$phone";
  }

  final whatsappUrl = Uri.parse(
    "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
  );

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

String formatAmount(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  } else {
    return value.toStringAsFixed(2);
  }
}

Future<void> collectFee({
  required String mode,
  required dynamic student,
  required dynamic fee,
  required double amount,
  required String controllerKey,
  required BuildContext context,
  required Map<String, TextEditingController> amountControllers,
  required String schoolId,
  required String classId,
  required String username,
  required DateTime date,
  required Function() init,
}) async {
  final busFeePaymentApi = BusFeePaymentApi();
  final scaffold = ScaffoldMessenger.of(context);

  final structureId = fee['id'];
  final studentId = student['username'];

  final className = student['class']?['class'] ?? "-";
  final section = student['class']?['section'] ?? "-";
  final phone = student['mobile'].toString();

  // Amount validation
  if (amount <= 0) {
    scaffold.showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Amount must be greater than zero'),
      ),
    );
    return;
  }

  final totalAmount =
      (fee['total_amount'] != null)
          ? double.tryParse(fee['total_amount'].toString()) ?? 0.0
          : 0.0;

  final amountAlreadyPaid = fee['amountPaid'] ?? 0.0;
  final remainingAmount = totalAmount - amountAlreadyPaid;

  if (amount > remainingAmount) {
    scaffold.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'Amount cannot exceed remaining balance: ₹${formatAmount(remainingAmount.toDouble())}',
        ),
      ),
    );
    return;
  }

  try {
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 12),
            Text("Processing payment..."),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    final referenceNumber =
        mode == "ONLINE" ? "TXN-${DateTime.now().millisecondsSinceEpoch}" : "";

    // FINAL PAYLOAD
    final payload = {
      "school_id": int.parse(schoolId),
      "class_id": int.parse(classId),
      "student_id": studentId.toString(),
      "bus_fee_structure_id": structureId,
      "amount_paid": amount,
      "payment_mode": mode,
      "reference_number": referenceNumber,
      "status": "PAID",
      "remarks": "$mode payment collected (partial)",
      "created_by": username,
      "updated_by": username,
      "payment_date": DateFormat('yyyy-MM-dd').format(date),
    };

    final result = await busFeePaymentApi.createPayment(payload);
    scaffold.hideCurrentSnackBar();

    if (result != null) {
      init(); // Refresh UI

      // WhatsApp Message Template

      String generateShareText() {
        final buffer = StringBuffer();

        buffer.writeln("  Payment Confirmation");
        buffer.writeln("----------------------------------------");
        buffer.writeln("");
        buffer.writeln("This is an official");
        buffer.writeln("fee payment confirmation message");
        buffer.writeln(
          "from ${student['school']['name']} , ${student['school']['address']}",
        );
        buffer.writeln("");

        buffer.writeln("    Student Details:");
        buffer.writeln("");
        buffer.writeln("Admin No    : $username");
        buffer.writeln("Name           : ${student['name']}");
        buffer.writeln("Class            : $className - $section");
        buffer.writeln("");

        buffer.writeln("     Payment Details");
        buffer.writeln("");
        buffer.writeln("Fee Type                  : Bus Fee");
        buffer.writeln(
          "Total Fee                 : ₹${double.parse(totalAmount.toString()).toStringAsFixed(1)}",
        );
        buffer.writeln(
          "Amount Received   : ₹${double.parse(amount.toString()).toStringAsFixed(1)}",
        );
        buffer.writeln(
          "Already Paid           : ₹${double.parse(amountAlreadyPaid.toString()).toStringAsFixed(1)}",
        );
        buffer.writeln(
          "Balance                   : ₹${double.parse((remainingAmount - amount).toString()).toStringAsFixed(1)}",
        );
        buffer.writeln(
          "Date                         : ${DateFormat('dd-MM-yyyy').format(date)}",
        );
        buffer.writeln("");

        buffer.writeln("Payment Mode       : ${mode.toUpperCase()}");
        buffer.writeln("");
        buffer.writeln("-----------------------------------------------------");
        buffer.writeln("    Thank you for your payment.");

        return buffer.toString();
      }

      final whatsappMessage = generateShareText();

      // Ask confirmation for WhatsApp
      bool? sendMessage;
      if (context.mounted) {
        sendMessage = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                "Send WhatsApp Message?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Do you want to send payment confirmation to ${student['name']} on WhatsApp?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("YES"),
                ),
              ],
            );
          },
        );
      }

      // If user pressed YES → send message
      if (sendMessage == true) {
        try {
          await sendWhatsAppMessage(phone, whatsappMessage);
        } catch (e) {
          debugPrint("WhatsApp send error: $e");
        }
      }

      // Success SnackBar
      scaffold.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "✅ $mode payment successful for ${student['name']} (₹${formatAmount(amount)})",
          ),
        ),
      );
    } else {
      scaffold.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("❌ Failed to record payment."),
        ),
      );
    }
  } catch (e) {
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text("⚠️ Error: $e")),
    );
  }
}

Widget studentList({
  required List<dynamic> filteredStudents,
  required Map<int, bool> expandedStudents,
  required Map<int, List<dynamic>> studentFees,
  required Future<void> Function(int studentId) toggleStudent,
  required BuildContext context,
  required Function() refreshData,
  required String schoolId,
  required String classId,
  required String username,
  required Map<String, TextEditingController> amountControllers,
  required Map<String, DateTime> selectedDates,
}) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: filteredStudents.length,
    itemBuilder: (context, index) {
      final student = filteredStudents[index];
      final studentId = student["id"];
      final fees = studentFees[studentId] ?? [];
      final isExpanded = expandedStudents[studentId] ?? false;

      // ------------------------------
      // PAYMENT STATUS LOGIC
      // ------------------------------
      int totalPaid = 0;
      for (final f in fees) {
        if (f["isPaid"] == true) {
          totalPaid += int.tryParse(f["amount"].toString()) ?? 0;
        }
      }

      int totalFee = 0;
      for (final f in fees) {
        totalFee += int.tryParse(f["amount"].toString()) ?? 0;
      }

      bool fullyPaid = totalPaid >= totalFee && totalFee > 0;
      bool partiallyPaid = totalPaid > 0 && totalPaid < totalFee;

      // ------------------------------
      // CARD COLOR
      // ------------------------------
      Color cardColor = Colors.white;
      if (fullyPaid) {
        cardColor = Colors.green.shade100;
      } else if (partiallyPaid) {
        cardColor = Colors.yellow.shade100;
      }
      if (isExpanded) {
        cardColor = Colors.blue.shade50;
      }

      // ------------------------------
      // LEFT STRIP COLOR
      // ------------------------------
      Color stripColor = Colors.grey;
      if (fullyPaid) stripColor = Colors.green;
      if (partiallyPaid) stripColor = Colors.orange;
      if (!fullyPaid && !partiallyPaid) stripColor = Colors.grey;
      if (isExpanded) stripColor = Colors.blue;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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

        // ------------------------------
        // MAIN CARD
        // ------------------------------
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),

              // ⭐ FIXED — parent controls expand/collapse
              onTap: () => toggleStudent(studentId),

              child: Row(
                children: [
                  // LEFT STRIP
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
                          // AVATAR
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

                          // NAME + USERNAME
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),

                          // STATUS ICON
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
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
                                    : isExpanded
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

            // ------------------------------
            // EXPANDED CONTENT (FEES)
            // ------------------------------
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
                child: buildFeeList(
                  fees: fees,
                  student: student,
                  amountControllers: amountControllers,
                  selectedDates: selectedDates,
                  context: context,
                  refreshData: refreshData,
                  schoolId: schoolId,
                  classId: classId,
                  username: username,
                ),
              ),
              crossFadeState:
                  isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
            ),
          ],
        ),
      );
    },
  );
}

Widget buildFeeList({
  required List<dynamic> fees,
  dynamic student,
  required Map<String, TextEditingController> amountControllers,
  required Map<String, DateTime> selectedDates, // ✅ ADDED
  required BuildContext context,
  required Function() refreshData,
  required String schoolId,
  required String classId,
  required String username,
}) {
  if (fees.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Text(
          "No bus fee details found.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  final studentId = student['id'];

  String formatAmount(double value) =>
      (value % 1 == 0) ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children:
          fees.asMap().entries.map((entry) {
            final feeIndex = entry.key;
            final fee = entry.value;
            final isPaid = fee['isPaid'] == true;

            final controllerKey = "${studentId}_$feeIndex";

            // 🎯 Persist date between rebuilds
            selectedDates.putIfAbsent(controllerKey, () => DateTime.now());

            final total =
                double.tryParse(fee['total_amount'].toString()) ?? 0.0;
            final paid = double.tryParse(fee['amountPaid'].toString()) ?? 0.0;
            final remaining = (total - paid).clamp(0, total);

            // 🎯 Persist amount controller
            amountControllers.putIfAbsent(
              controllerKey,
              () => TextEditingController(
                text: formatAmount(remaining.toDouble()),
              ),
            );

            final amountController = amountControllers[controllerKey]!;

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
                        "Term: ${fee['term']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text("Total: ₹${formatAmount(total)}"),
                      Text("Paid: ₹${formatAmount(paid)}"),
                      Text(
                        "Remaining: ₹${formatAmount(remaining.toDouble())}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (!isPaid) ...[
                        const SizedBox(height: 16),

                        // 📅 DATE PICKER
                        GestureDetector(
                          onTap: () async {
                            final newDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDates[controllerKey]!,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (newDate != null) {
                              selectedDates[controllerKey] = newDate; // persist
                              setState(() {});
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
                                  "Date: ${selectedDates[controllerKey]!.toLocal().toString().split(' ')[0]}",
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
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
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
                                    double.tryParse(amountController.text) ?? 0;
                                if (value <= 0 || value > remaining) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Enter valid amount up to ₹$remaining",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                collectFee(
                                  mode: "CASH",
                                  student: student,
                                  fee: fee,
                                  amount: value,
                                  controllerKey: controllerKey,
                                  context: context,
                                  amountControllers: amountControllers,
                                  schoolId: schoolId,
                                  classId: classId,
                                  username: username,
                                  date: selectedDates[controllerKey]!,

                                  init: refreshData,
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
                                    double.tryParse(amountController.text) ?? 0;
                                if (value <= 0 || value > remaining) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Enter valid amount up to ₹$remaining",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                collectFee(
                                  mode: "ONLINE",
                                  student: student,
                                  fee: fee,
                                  amount: value,
                                  controllerKey: controllerKey,
                                  context: context,
                                  amountControllers: amountControllers,
                                  schoolId: schoolId,
                                  classId: classId,
                                  username: username,
                                  date: selectedDates[controllerKey]!,
                                  init: refreshData,
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

                      if (isPaid)
                        Center(
                          child: Chip(
                            backgroundColor: Colors.green,
                            label: Text(
                              "✔ Fully Collected by ${fee['paidBy'] ?? 'Admin'}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
    ),
  );
}
