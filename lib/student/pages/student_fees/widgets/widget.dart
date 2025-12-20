import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../admin/widget/pdf_preview_custom_page.dart';
import '../build_student_fee_pdf.dart';

Widget buildFeesList(
  List<Map<String, dynamic>> fees, {
  required bool isCompleted,
  required double Function(int) totalPaidForFee,
  required List<dynamic>? Function(int) studentFeeRecordByFeeId,
  required String Function(List<dynamic>?) listToString,
  required BuildContext context,
  String? schoolName,
  String? schoolAddress,
  Uint8List? schoolPhotoBytes,
  required Map<String, dynamic> studentDetails,
}) {
  if (fees.isEmpty) {
    return Center(
      child: Text(
        isCompleted ? 'No completed fees found' : 'No pending fees found',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: ListView.builder(
      itemCount: fees.length,
      itemBuilder: (_, index) {
        final fee = fees[index];

        final title = fee['title'] ?? 'Title not available';
        final descriptions = listToString(
          (fee['descriptions'] ?? []) as List<dynamic>,
        );

        final totalAmount = (fee['total_amount'] ?? 0).toDouble();
        final paidAmount = totalPaidForFee(fee['id']);
        final remaining = totalAmount - paidAmount;

        final endDate =
            fee['end_date'] != null
                ? fee['end_date'].toString().split('T')[0]
                : '-';

        // Determine badge color
        Color statusColor;
        String badgeText;

        if (paidAmount == 0) {
          statusColor = Colors.red;
          badgeText = "UNPAID";
        } else if (paidAmount < totalAmount) {
          statusColor = Colors.orangeAccent;
          badgeText = "PARTIAL";
        } else {
          statusColor = Colors.green;
          badgeText = "PAID";
        }

        return Card(
          elevation: 3,
          color: Colors.white,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:
                () => showFeeDetailsDialog(
                  fee: fee,
                  paidAmount: paidAmount,
                  totalAmount: totalAmount,
                  studentFeeRecords: studentFeeRecordByFeeId(fee['id']),
                  context: context,
                  schoolName: schoolName,
                  schoolAddress: schoolAddress,
                  schoolPhotoBytes: schoolPhotoBytes,
                  studentDetails: studentDetails,
                ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      badgeText == "PAID"
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // TITLE + DESCRIPTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          descriptions,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // STATUS TEXT
                        Text(
                          paidAmount >= totalAmount
                              ? "Fully Paid"
                              : paidAmount == 0
                              ? "Due by: $endDate"
                              : "Paid: ₹$paidAmount  |  Due: ₹$remaining",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                badgeText == "PAID"
                                    ? Colors.green.shade700
                                    : badgeText == "PARTIAL"
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹$totalAmount",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

void showFeeDetailsDialog({
  required Map<String, dynamic> fee,
  required double paidAmount,
  required double totalAmount,
  required List<dynamic>? studentFeeRecords,
  required BuildContext context,
  String? schoolName,
  String? schoolAddress,
  Uint8List? schoolPhotoBytes,
  required Map<String, dynamic> studentDetails,
}) {
  final descriptions = (fee['descriptions'] ?? []) as List;
  final amounts = (fee['amounts'] ?? []) as List;

  final dateFormat = DateFormat("dd MMM yyyy");
  // final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  // Extract ALL payments from ALL records
  final List<Map<String, dynamic>> allPayments = [];

  if (studentFeeRecords != null) {
    for (var record in studentFeeRecords) {
      if (record['payments'] != null) {
        for (var pay in record['payments']) {
          allPayments.add(Map<String, dynamic>.from(pay));
        }
      }
    }
  }

  // Sort payments by date DESC
  allPayments.sort((a, b) {
    return DateTime.parse(
      b['payment_date'],
    ).compareTo(DateTime.parse(a['payment_date']));
  });

  String formatDate(String? date) {
    if (date == null) return '-';
    return dateFormat.format(DateTime.parse(date));
  }

  Future<void> downloadPdf() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => generatePdf(
                    fee: fee,
                    studentFees: studentFeeRecords,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                    studentDetails: studentDetails,
                  ),
              title: "Receipt",
              fileName: "receipt",
            ),
      ),
    );
  }

  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  fee['title'] ?? "Fee Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
                const SizedBox(height: 16),

                // DESCRIPTION SECTION
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                ...List.generate(descriptions.length, (i) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("- ${descriptions[i]}"),
                      Text("₹${amounts[i]}"),
                    ],
                  );
                }),

                Divider(height: 30),

                // TOTAL + PAID + REMAINING
                Text(
                  "Total Amount: ₹$totalAmount",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Paid Amount: ₹$paidAmount",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Remaining: ₹${totalAmount - paidAmount}",
                  style: const TextStyle(fontSize: 16),
                ),
                Divider(height: 30),

                // ALL PAYMENTS LIST
                Text(
                  "Payments",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.indigo.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                if (allPayments.isEmpty) const Text("No payments available"),

                ...allPayments.map((p) {
                  return Card(
                    color: Colors.indigo.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        Icons.receipt_long,
                        color: Colors.indigo.shade700,
                      ),
                      title: Text("₹${p['amount']}"),
                      subtitle: Text(
                        "${formatDate(p['payment_date'])} (${p['method'] ?? '-'})",
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Show PDF only if any payment exists
                    if (paidAmount > 0)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Generate Bill"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: downloadPdf,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
