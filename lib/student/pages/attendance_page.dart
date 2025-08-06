import 'package:flutter/material.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../widget/student_attendance_cells_desktop.dart';
import '../widget/student_attendance_cells_mobile.dart';

class AttendancePage extends StatefulWidget {
  final String name;
  final String username;
  final String schoolId;
  final String classId;
  final String gender;
  final String email;

  const AttendancePage({
    super.key,
    required this.name,
    required this.username,
    required this.schoolId,
    required this.classId,
    required this.gender,
    required this.email,
  });

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
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

  Future<void> _loadAttendanceData() async {
    final data = await StudentApiServices.fetchStudentAttendanceByClassid(
      username: widget.username,
      schoolId: widget.schoolId,
      classId: widget.classId,
    );
    final holidayList = await StudentApiServices.fetchHolidaysClasses(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    setState(() {
      for (var entry in data) {
        final dateRaw = entry['date'];
        final fn = entry['fn_status'];
        final an = entry['an_status'];

        if (dateRaw != null) {
          final date = dateRaw is String ? DateTime.parse(dateRaw) : dateRaw;
          final formatted = _formatDate(date);
          _attendanceDataMap[formatted] = {'fn': fn, 'an': an};
        }
      }

      for (var holiday in holidayList) {
        final date = holiday['date'];
        final fn = holiday['fn'];
        final an = holiday['an'];
        if (date != null) {
          final formatted = _formatDate(DateTime.parse(date));
          _holidayDataMap[formatted] = {'fn': fn, 'an': an};
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final formattedSelected =
        _selectedDay != null ? _formatDate(_selectedDay!) : '';

    return Scaffold(
      appBar:
          MediaQuery.of(context).size.width > 600
              ? StudentAppbarDesktop(title: 'Attendance')
              : StudentAppbarMobile(title: 'Attendance'),
      body:
          MediaQuery.of(context).size.width > 600
              ? StudentAttendanceCellsDesktop(
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
      bottomNavigationBar:
          _selectedDay != null
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FN: ${_attendanceDataMap[formattedSelected]?['fn'] ?? _holidayDataMap[formattedSelected]?['fn'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getColor(
                          _attendanceDataMap[formattedSelected]?['fn'] ??
                              _holidayDataMap[formattedSelected]?['fn'],
                        ),
                      ),
                    ),
                    Text(
                      'AN: ${_attendanceDataMap[formattedSelected]?['an'] ?? _holidayDataMap[formattedSelected]?['an'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getColor(
                          _attendanceDataMap[formattedSelected]?['an'] ??
                              _holidayDataMap[formattedSelected]?['an'],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
