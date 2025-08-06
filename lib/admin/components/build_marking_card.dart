import 'package:flutter/material.dart';

class BuildMarkingCard extends StatelessWidget {
  const BuildMarkingCard({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.attendanceStatusMapFn,
    required this.attendanceStatusMapAn,
  });

  final double screenWidth;
  final double screenHeight;
  final Map<String, bool> attendanceStatusMapFn;
  final Map<String, bool> attendanceStatusMapAn;

  @override
  Widget build(BuildContext context) {
    final nonMarkingFn = attendanceStatusMapFn.values.where((v) => v).length;
    final markingFn = attendanceStatusMapFn.values.where((v) => !v).length;
    final nonMarkingAn = attendanceStatusMapAn.values.where((v) => v).length;
    final markingAn = attendanceStatusMapAn.values.where((v) => !v).length;
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.25,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero, // Removes default padding inside button
        ),
        onPressed: () {},
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.toc, color: Colors.blue, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Sections(${attendanceStatusMapFn.length})',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Table(
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
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(1.0),
                          child: _TableCellText('SESSION', color: Colors.black),
                        ),
                        _TableCellText('M', color: Colors.cyan),
                        _TableCellText('NM', color: Colors.red),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: _TableCellText('FN', color: Colors.black),
                        ),
                        _TableCellText('$markingFn', color: Colors.cyan),
                        _TableCellText('$nonMarkingFn', color: Colors.red),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: _TableCellText('AN', color: Colors.black),
                        ),
                        _TableCellText('$markingAn', color: Colors.cyan),
                        _TableCellText('$nonMarkingAn', color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final Color color;

  const _TableCellText(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
