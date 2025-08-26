import 'package:flutter/material.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
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
  final Image? schoolPhoto;
  final String schoolName;
  final String? schoolAddress;
  final String? message;

  const AttendancePage({
    super.key,
    required this.name,
    required this.username,
    required this.schoolId,
    required this.classId,
    required this.gender,
    required this.email,
    this.schoolPhoto,
    required this.schoolName,
    required this.schoolAddress,
    required this.message,
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

  Map<String, dynamic> _getMonthlyAttendanceStats(DateTime month) {
    int present = 0;
    int total = 0;

    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Loop through attendance data
    _attendanceDataMap.forEach((date, statusMap) {
      if (date.startsWith(monthKey)) {
        final fn = statusMap['fn'];
        final an = statusMap['an'];

        // count FN
        if (fn == 'P') present++;
        if (fn == 'P' || fn == 'A') total++;

        // count AN
        if (an == 'P') present++;
        if (an == 'P' || an == 'A') total++;
      }
    });

    // Loop through holidays (only if you want them in total count, otherwise skip)
    _holidayDataMap.forEach((date, statusMap) {
      if (date.startsWith(monthKey)) {
        // do not add to total (holidays shouldn't affect percentage)
      }
    });

    final percentage = total > 0 ? (present / total * 100) : 0;

    return {
      'present': present,
      'total': total,
      'percentage': percentage.toStringAsFixed(1),
    };
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
        return Colors.black;
    }
  }

  // 👶 Convert codes to child-friendly labels
  String _getStatusLabel(String? code) {
    switch (code) {
      case 'P':
        return '✅ Present';
      case 'A':
        return '❌ Absent';
      case 'H':
        return '🏖️ Holiday';
      case 'W':
        return '🛌 Weekend';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedSelected =
        _selectedDay != null ? _formatDate(_selectedDay!) : '';
    final isMobile = MediaQuery.of(context).size.width < 500;
    final stats = _getMonthlyAttendanceStats(_focusedDay);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Student Attendance',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 0;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : const StudentAppbarDesktop(title: 'Student Attendance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
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
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedDay != null) ...[
            Text(
              'Morning (FN): ${_getStatusLabel(_attendanceDataMap[formattedSelected]?['fn'] ?? _holidayDataMap[formattedSelected]?['fn'])}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _getColor(
                  _attendanceDataMap[formattedSelected]?['fn'] ??
                      _holidayDataMap[formattedSelected]?['fn'],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Afternoon (AN): ${_getStatusLabel(_attendanceDataMap[formattedSelected]?['an'] ?? _holidayDataMap[formattedSelected]?['an'])}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _getColor(
                  _attendanceDataMap[formattedSelected]?['an'] ??
                      _holidayDataMap[formattedSelected]?['an'],
                ),
              ),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Monthly Attendance: ${stats['percentage']}% '
              '(${stats['present']}/${stats['total']} sessions)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
