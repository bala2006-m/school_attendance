import 'package:flutter/material.dart';

import '../../student/widget/student_attendance_cells_mobile.dart';
import '../components/attendance_cell_desktop.dart';

class AttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String title;
  final List<Map<String, dynamic>> holidayList;
  final List<Map<String, dynamic>> data;

  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.holidayList,
    required this.data,
    required this.title,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  final Map<String, Map<String, String?>> _attendanceDataMap = {};
  final Map<String, Map<String, String?>> _holidayDataMap = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.holidayList != widget.holidayList) {
      _attendanceDataMap.clear();
      _holidayDataMap.clear();
      _loadAttendanceData();
      setState(() {});
    }
  }

  void _loadAttendanceData() {
    for (var entry in widget.data) {
      final dateRaw = entry['date'];
      final fn = entry['fn_status'];
      final an = entry['an_status'];

      if (dateRaw != null) {
        final date = dateRaw is String ? DateTime.parse(dateRaw) : dateRaw;
        final formatted = _formatDate(date);
        _attendanceDataMap[formatted] = {'fn': fn, 'an': an};
      }
    }

    for (var holiday in widget.holidayList) {
      final date = holiday['date'];
      final fn = holiday['fn'];
      final an = holiday['an'];
      if (date != null) {
        final formatted = _formatDate(DateTime.parse(date));
        _holidayDataMap[formatted] = {'fn': fn, 'an': an};
      }
    }
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
        return Colors.black;
    }
  }

  String _getStatus(String time, String formattedSelected) {
    return _attendanceDataMap[formattedSelected]?[time] ??
        _holidayDataMap[formattedSelected]?[time] ??
        'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final formattedSelected =
        _selectedDay != null ? _formatDate(_selectedDay!) : '';

    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isDesktop
                ? AttendanceCellsDesktop(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  attendanceDataMap: _attendanceDataMap,
                  holidayDataMap: _holidayDataMap,
                  onDaySelectedCallback: (selected) {
                    setState(() {
                      _selectedDay = selected;
                    });
                  },
                  onPageChangedCallback: (focused) {
                    setState(() {
                      _focusedDay = focused;
                    });
                  },
                )
                : StudentAttendanceCellsMobile(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  attendanceDataMap: _attendanceDataMap,
                  holidayDataMap: _holidayDataMap,
                  onDaySelectedCallback: (selected) {
                    setState(() {
                      _selectedDay = selected;
                    });
                  },
                  onPageChangedCallback: (focused) {
                    setState(() {
                      _focusedDay = focused;
                    });
                  },
                ),
            const SizedBox(height: 20),
            if (_selectedDay != null &&
                (_getStatus('fn', formattedSelected) != 'N/A' ||
                    _getStatus('an', formattedSelected) != 'N/A'))
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FN: ${_getStatus('fn', formattedSelected)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getColor(_getStatus('fn', formattedSelected)),
                    ),
                  ),
                  Text(
                    'AN: ${_getStatus('an', formattedSelected)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getColor(_getStatus('an', formattedSelected)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
