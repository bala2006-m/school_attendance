import 'package:flutter/material.dart';

Widget buildTermFeeStats({
  required double screenWidth,
  required double screenHeight,
  required Map<String, dynamic> allPendingTermFees,
}) {
  return Container(
    width: screenWidth * 0.9,
    height: screenHeight * 0.28,
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments, color: Colors.blue, size: 30),
                const SizedBox(width: 10),
                Text(
                  'Term Fees (${allPendingTermFees['allFees']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Attendance Table
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 2,
              ),
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              // Header Row
              const TableRow(
                children: [
                  _TableCellHeader('TOTAL'),
                  _TableCellHeader('PAID', color: Colors.cyan),
                  _TableCellHeader('PENDING', color: Colors.red),
                ],
              ),

              TableRow(
                children: [
                  _TableCellText(
                    allPendingTermFees['totalClassStudent'] == 0
                        ? '-'
                        : '${allPendingTermFees['totalClassStudent'].toString()}(S)',
                  ),
                  _TableCellText(
                    allPendingTermFees['totalPaidStudent'] == 0
                        ? '-'
                        : allPendingTermFees['totalPaidStudent'].toString(),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingTermFees['totalPendingStudent'] == 0
                        ? '-'
                        : allPendingTermFees['totalPendingStudent'].toString(),

                    color: Colors.red,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _TableCellText(
                    allPendingTermFees['totalAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingTermFees['totalAmount'].toString(),
                          ),
                        ),
                  ),
                  _TableCellText(
                    allPendingTermFees['totalPaidAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingTermFees['totalPaidAmount'].toString(),
                          ),
                        ),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingTermFees['totalPendingAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingTermFees['totalPendingAmount'].toString(),
                          ),
                        ),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String formatAmount(double amount) {
  if (amount <= 1000) {
    return '₹${amount.toStringAsFixed(2)}';
  } else if (amount < 100000) {
    return '₹${(amount / 1000).toStringAsFixed(2)} K';
  } else {
    return '₹${(amount / 100000).toStringAsFixed(2)} L';
  }
}

Widget buildBusFeeStats({
  required double screenWidth,
  required double screenHeight,
  required Map<String, dynamic> allPendingBusFees,
}) {
  return Container(
    width: screenWidth * 0.9,
    height: screenHeight * 0.28,
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bus_alert, color: Colors.blue, size: 30),
                const SizedBox(width: 10),
                Text(
                  'Bus Fees (${allPendingBusFees['totalBusFees']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Attendance Table
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 2,
              ),
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              // Header Row
              const TableRow(
                children: [
                  _TableCellHeader('TOTAL'),
                  _TableCellHeader('PAID', color: Colors.cyan),
                  _TableCellHeader('PENDING', color: Colors.red),
                ],
              ),

              TableRow(
                children: [
                  _TableCellText(
                    allPendingBusFees['totalStudents'] == 0
                        ? '-'
                        : '${allPendingBusFees['totalStudents'].toString()}(S)',
                  ),
                  _TableCellText(
                    allPendingBusFees['totalPaidStudents'] == 0
                        ? '-'
                        : allPendingBusFees['totalPaidStudents'].toString(),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingBusFees['totalPendingStudents'] == 0
                        ? '-'
                        : allPendingBusFees['totalPendingStudents'].toString(),

                    color: Colors.red,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _TableCellText(
                    allPendingBusFees['totalAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingBusFees['totalAmount'].toString(),
                          ),
                        ),
                  ),
                  _TableCellText(
                    allPendingBusFees['totalPaidAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingBusFees['totalPaidAmount'].toString(),
                          ),
                        ),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingBusFees['totalPendingAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingBusFees['totalPendingAmount'].toString(),
                          ),
                        ),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildRteFeeStats({
  required double screenWidth,
  required double screenHeight,
  required Map<String, dynamic> allPendingRteFees,
}) {
  return Container(
    width: screenWidth * 0.9,
    height: screenHeight * 0.28,
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bus_alert, color: Colors.blue, size: 30),
                const SizedBox(width: 10),
                Text(
                  'RTE Fees (${allPendingRteFees['totalRteFees']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Attendance Table
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 2,
              ),
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              // Header Row
              const TableRow(
                children: [
                  _TableCellHeader('TOTAL'),
                  _TableCellHeader('PAID', color: Colors.cyan),
                  _TableCellHeader('PENDING', color: Colors.red),
                ],
              ),

              TableRow(
                children: [
                  _TableCellText(
                    allPendingRteFees['totalStudents'] == 0
                        ? '-'
                        : '${allPendingRteFees['totalStudents'].toString()}(S)',
                  ),
                  _TableCellText(
                    allPendingRteFees['totalPaidStudents'] == 0
                        ? '-'
                        : allPendingRteFees['totalPaidStudents'].toString(),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingRteFees['totalPendingStudents'] == 0
                        ? '-'
                        : allPendingRteFees['totalPendingStudents'].toString(),

                    color: Colors.red,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _TableCellText(
                    allPendingRteFees['totalAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingRteFees['totalAmount'].toString(),
                          ),
                        ),
                  ),
                  _TableCellText(
                    allPendingRteFees['totalPaidAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingRteFees['totalPaidAmount'].toString(),
                          ),
                        ),
                    color: Colors.cyan,
                  ),
                  _TableCellText(
                    allPendingRteFees['totalPendingAmount'] == 0
                        ? '-'
                        : formatAmount(
                          double.parse(
                            allPendingRteFees['totalPendingAmount'].toString(),
                          ),
                        ),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TableCellHeader extends StatelessWidget {
  final String text;
  final Color? color;

  const _TableCellHeader(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Colors.black,
          ),
        ),
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final Color? color;

  const _TableCellText(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Colors.black,
          ),
        ),
      ),
    );
  }
}
