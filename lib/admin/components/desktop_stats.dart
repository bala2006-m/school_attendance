import 'package:flutter/material.dart';

class DesktopStats extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final String presentFN;
  final String total;
  final String name;
  final String presentAN;

  const DesktopStats({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.total,
    required this.name,
    required this.presentFN,
    required this.presentAN,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.25, // slightly increased for better fit
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
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: Colors.blue, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    '$name ($total)',
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
                verticalInside: BorderSide(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
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
                    _TableCellHeader('SESSION'),
                    _TableCellHeader('P', color: Colors.cyan),
                    _TableCellHeader('A', color: Colors.red),
                  ],
                ),

                // FN Row
                TableRow(
                  children: [
                    const _TableCellText('FN'),
                    _TableCellText(
                      presentFN == '0' ? '-' : presentFN,
                      color: Colors.cyan,
                    ),
                    _TableCellText(
                      presentFN == '0'
                          ? '-'
                          : '${int.parse(total) - int.parse(presentFN)}',
                      color: Colors.red,
                    ),
                  ],
                ),

                // AN Row
                TableRow(
                  children: [
                    const _TableCellText('AN'),
                    _TableCellText(
                      presentAN == '0' ? '-' : presentAN,
                      color: Colors.cyan,
                    ),
                    _TableCellText(
                      presentAN == '0'
                          ? '-'
                          : '${int.parse(total) - int.parse(presentAN)}',
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
            fontSize: 18,
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
            fontSize: 18,
            color: color ?? Colors.black,
          ),
        ),
      ),
    );
  }
}
