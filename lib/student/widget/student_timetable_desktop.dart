import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentTimetableDesktop extends StatelessWidget {
  const StudentTimetableDesktop({
    super.key,
    required this.periodHeaders,
    required this.days,
    required this.timetable,
  });

  final List<String> periodHeaders;
  final List<String> days;
  final Map<String, List<String>> timetable;

  static const double baseFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = periodHeaders.length + 1;
    final double columnWidth = (screenWidth / columnCount) - 5;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Table(
              defaultColumnWidth: FixedColumnWidth(columnWidth),
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300),
              ),
              children: [
                _buildHeaderRow(),
                ...days.map((day) => _buildDayRow(day)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        _styledCell(
          'Day',
          bold: true,
          align: Alignment.center,
          color: Colors.indigo,
          textColor: Colors.white,
        ),
        ...periodHeaders.map(
          (header) => _styledCell(
            header,
            bold: true,
            align: Alignment.center,
            color: Colors.indigo.shade100,
          ),
        ),
      ],
    );
  }

  TableRow _buildDayRow(String day) {
    final subjects = timetable[day] ?? [];
    final isToday = DateFormat('EEEE').format(DateTime.now()) == day;

    final cells = List.generate(
      periodHeaders.length,
      (index) => index < subjects.length ? subjects[index] : '',
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
      ),
      children: [
        _styledCell(day, bold: true, align: Alignment.centerLeft, padding: 8),
        ...cells.map((subject) => _buildSubjectCell(subject)).toList(),
      ],
    );
  }

  Widget _styledCell(
    String text, {
    bool bold = false,
    Alignment align = Alignment.center,
    double padding = 6,
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
