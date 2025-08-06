import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'diagonal_painter.dart';

class AttendanceCellsDesktop extends StatelessWidget {
  const AttendanceCellsDesktop({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.attendanceDataMap,
    required this.holidayDataMap,
    required this.onDaySelectedCallback,
    required this.onPageChangedCallback,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<String, Map<String, String?>> attendanceDataMap;
  final Map<String, Map<String, String?>> holidayDataMap;
  final Function(DateTime) onDaySelectedCallback;
  final Function(DateTime) onPageChangedCallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) {
              onDaySelectedCallback(selected);
              onPageChangedCallback(focused);
            },
            onPageChanged: (focused) {
              onPageChangedCallback(focused);
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildDayCell(day),
              todayBuilder:
                  (context, day, _) => _buildDayCell(day, isToday: true),
              selectedBuilder:
                  (context, day, _) => _buildDayCell(day, isSelected: true),
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final formatted = _formatDate(day);

    final fn =
        attendanceDataMap[formatted]?['fn'] ?? holidayDataMap[formatted]?['fn'];
    final an =
        attendanceDataMap[formatted]?['an'] ?? holidayDataMap[formatted]?['an'];

    final fnColor = _getColor(fn);
    final anColor = _getColor(an);

    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              isToday
                  ? Border.all(color: Colors.blueAccent, width: 2)
                  : isSelected
                  ? Border.all(color: Colors.indigo, width: 2)
                  : null,
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: DiagonalPainter(fnColor, anColor),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color:
                      (fnColor == Colors.white && anColor == Colors.white)
                          ? Colors.black
                          : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.green, 'Present'),
          _legendItem(Colors.red, 'Absent'),
          _legendItem(Colors.purple, 'Holiday'),
          _legendItem(Colors.grey, 'Working'),
          _legendItem(Colors.white, 'No Data'),
          _legendItem(Colors.blue, 'Today'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Color _getColor(String? status) {
    switch (status) {
      case 'P':
        return Colors.green;
      case 'A':
        return Colors.red;
      case 'H':
        return Colors.purple;
      case 'W':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }
}
