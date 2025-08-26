import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentTimetableMobile extends StatelessWidget {
  const StudentTimetableMobile({
    super.key,
    required this.periodHeaders,
    required this.days,
    required this.timetable,
  });

  final List<String> periodHeaders;
  final List<String> days;
  final Map<String, List<String>> timetable;

  static const int periodsPerHalfDay = 4;
  static const double baseFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double columnWidth = screenWidth / (1 + periodsPerHalfDay) - 5;

    return SingleChildScrollView(
      //scrollDirection: Axis.horizontal,
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 5, right: 1),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Table(
                  defaultColumnWidth: FixedColumnWidth(columnWidth),
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey.shade300),
                  ),
                  children: [
                    _buildHeaderRow('Forenoon', 0),
                    ...days.map((day) => _buildDayRow(day, 0)),
                    TableRow(
                      children: List.generate(
                        1 + periodsPerHalfDay,
                        (_) => const SizedBox(height: 30),
                      ),
                    ),
                    _buildHeaderRow('Afternoon', periodsPerHalfDay),
                    ...days
                        .map((day) => _buildDayRow(day, periodsPerHalfDay))
                        .toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(String label, int startIndex) {
    final headers =
        (startIndex < periodHeaders.length)
            ? periodHeaders.skip(startIndex).take(periodsPerHalfDay).toList()
            : <String>[];

    while (headers.length < periodsPerHalfDay) {
      headers.add('');
    }

    return TableRow(
      children: [
        _styledCell(
          label,
          bold: true,
          align: Alignment.center,
          color: Colors.indigo,
          textColor: Colors.white,
        ),
        ...headers.map(
          (h) => _styledCell(
            h,
            bold: true,
            align: Alignment.center,
            color: Colors.indigo.shade100,
          ),
        ),
      ],
    );
  }

  TableRow _buildDayRow(String day, int startIndex) {
    final subjects = timetable[day] ?? [];
    final isToday = DateFormat('EEEE').format(DateTime.now()) == day;
    final periodSlice = List.generate(
      periodsPerHalfDay,
      (i) => startIndex + i < subjects.length ? subjects[startIndex + i] : '',
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
      ),
      children: [
        _styledCell(day, bold: true, align: Alignment.centerLeft, padding: 8),
        ...periodSlice.map((subj) => _buildSubjectCell(subj)).toList(),
      ],
    );
  }

  Widget _styledCell(
    String text, {
    bool bold = false,
    Alignment align = Alignment.center,
    double padding = 3,
    Color? color,
    Color textColor = Colors.black87,
  }) {
    return Container(
      alignment: align,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: baseFontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSubjectCell(String subject) {
    final trimmed = subject.trim();

    return Tooltip(
      message: trimmed.isNotEmpty ? trimmed : 'Free Period',
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Text(
          trimmed,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
