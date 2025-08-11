import 'package:flutter/material.dart';

import '../../student/services/student_api_services.dart';

class DesktopStats extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final String presentFN;
  final String total;
  final String name;
  final String presentAN;
  final bool isClassShown;
  final List<dynamic> classIds;
  final String schoolId;

  const DesktopStats({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.total,
    required this.name,
    required this.presentFN,
    required this.presentAN,
    required this.isClassShown,
    required this.classIds,
    required this.schoolId,
  });

  @override
  State<DesktopStats> createState() => _DesktopStatsState();
}

class _DesktopStatsState extends State<DesktopStats> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isClassShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        init();
      });
    }
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    final fetchedClasses = <Map<String, dynamic>>[];

    for (final id in widget.classIds) {
      final classData = await StudentApiServices.fetchClassDatas(
        widget.schoolId,
        '$id',
      );
      if (classData != null) {
        fetchedClasses.add(classData);
      }
    }

    setState(() {
      classes = fetchedClasses;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = int.tryParse(widget.total) ?? 0;
    final int presentFN = int.tryParse(widget.presentFN) ?? 0;
    final int presentAN = int.tryParse(widget.presentAN) ?? 0;

    return Container(
      width: widget.screenWidth * 0.9,
      height:
          widget.isClassShown
              ? widget.screenHeight * 0.40
              : widget.screenHeight * 0.25,
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
                  const Icon(Icons.people, color: Colors.blue, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.name} ($total)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Classes Section
            if (widget.isClassShown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child:
                    classes.isNotEmpty
                        ? Column(
                          children: [
                            const Text(
                              'Classes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 10,
                              runSpacing: 5,
                              children:
                                  classes
                                      .map(
                                        (c) => Chip(
                                          label: Text(
                                            '${c['class']}-${c['section']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          backgroundColor: Colors.blue.shade100,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        )
                        : const Text(
                          'No classes found',
                          style: TextStyle(color: Colors.grey),
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
                      presentFN == 0 ? '-' : '$presentFN',
                      color: Colors.cyan,
                    ),
                    _TableCellText(
                      presentFN == 0 ? '-' : '${total - presentFN}',
                      color: Colors.red,
                    ),
                  ],
                ),

                // AN Row
                TableRow(
                  children: [
                    const _TableCellText('AN'),
                    _TableCellText(
                      presentAN == 0 ? '-' : '$presentAN',
                      color: Colors.cyan,
                    ),
                    _TableCellText(
                      presentAN == 0 ? '-' : '${total - presentAN}',
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
