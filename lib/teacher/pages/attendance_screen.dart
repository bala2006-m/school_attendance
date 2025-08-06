import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String className;
  final String section;

  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  bool isSubmitting = false;
  DateTime selectedDate = DateTime.now();
  late TimeOfDay currentTime;

  @override
  void initState() {
    super.initState();
    currentTime = TimeOfDay.now();
    init();
  }

  Future<void> init() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final studentJsonList = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    final attendance = await ApiService.fetchStudentAttendance(
      date: formattedDate,
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    final Map<String, String> attendanceMap = {
      for (var entry in attendance)
        if (entry['username'] != null)
          entry['username']: (entry['fn_status'] ?? 'A').toString(),
    };

    final Map<String, String> fnMap = {
      for (var entry in attendance)
        if (entry['username'] != null)
          entry['username']: (entry['fn_status'] ?? 'A').toString(),
    };

    final Map<String, String> anMap = {
      for (var entry in attendance)
        if (entry['username'] != null)
          entry['username']: (entry['an_status'] ?? 'A').toString(),
    };

    students =
        studentJsonList
            .where((s) => s['username'] != null && s['name'] != null)
            .map<Map<String, dynamic>>(
              (s) => {
                ...s,
                'isForenoonPresent': fnMap[s['username']] == 'P',
                'isAfternoonPresent': anMap[s['username']] == 'P',
              },
            )
            .toList();

    setState(() {
      isLoading = false;
    });
  }

  bool _isForenoonAllowed() => currentTime.hour >= 9 && currentTime.hour < 13;
  bool _isAfternoonAllowed() =>
      currentTime.hour >= 13 && currentTime.hour <= 17;

  Future<void> _submitAttendance() async {
    setState(() {
      isSubmitting = true;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    bool anySuccess = false;

    for (var student in students) {
      final id = student['username']?.toString();
      if (id == null || id.isEmpty) continue;

      final fn = student['isForenoonPresent'];
      final an = student['isAfternoonPresent'];

      if (_isForenoonAllowed()) {
        final fnResult = await TeacherApiServices.postStudentAttendance(
          username: id,
          date: formattedDate,
          session: 'FN',
          status: fn == true ? 'P' : 'A',
          schoolId: widget.schoolId,
          classId: widget.classId,
        );
        anySuccess = anySuccess || fnResult;
      }

      if (_isAfternoonAllowed()) {
        final anResult = await TeacherApiServices.postStudentAttendance(
          username: id,
          date: formattedDate,
          session: 'AN',
          status: an == true ? 'P' : 'A',
          schoolId: widget.schoolId,
          classId: widget.classId,
        );
        anySuccess = anySuccess || anResult;
      }
    }

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: anySuccess ? Colors.green : Colors.red,
        content: Text(
          anySuccess
              ? 'Attendance submitted successfully!'
              : 'Failed to submit attendance',
        ),
      ),
    );
  }

  void _resetAttendance() {
    setState(() {
      for (var student in students) {
        student['isForenoonPresent'] = false;
        student['isAfternoonPresent'] = false;
      }
    });
  }

  void _markAll(bool present) {
    setState(() {
      for (var student in students) {
        if (_isForenoonAllowed()) {
          student['isForenoonPresent'] = present;
        }
        if (_isAfternoonAllowed()) {
          student['isAfternoonPresent'] = present;
        }
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFNAllowed = _isForenoonAllowed();
    final isANAllowed = _isAfternoonAllowed();
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body:
          isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : students.isEmpty
              ? const Center(child: Text("No students found."))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _selectDate,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 4),
                              Text("Date: $formattedDate"),
                            ],
                          ),
                        ),
                        Text("${widget.className}-${widget.section}"),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _markAll(true),
                        child: const Text("Mark All Present"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _markAll(false),
                        child: const Text("Mark All Absent"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final name = student['name'] ?? 'Unknown';
                        return ListTile(
                          title: Text(name),
                          subtitle: Row(
                            children: [
                              _buildAttendanceSwitch(
                                label: "Forenoon",
                                value: student['isForenoonPresent'],
                                enabled: isFNAllowed,
                                onChanged:
                                    (val) => setState(
                                      () => student['isForenoonPresent'] = val,
                                    ),
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                              ),
                              _buildAttendanceSwitch(
                                label: "Afternoon",
                                value: student['isAfternoonPresent'],
                                enabled: isANAllowed,
                                onChanged:
                                    (val) => setState(
                                      () => student['isAfternoonPresent'] = val,
                                    ),
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _resetAttendance,
                          child: const Text("Reset"),
                        ),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : _submitAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child:
                              isSubmitting
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: SpinKitFadingCircle(
                                      color: Colors.blueAccent,
                                      size: 60.0,
                                    ),
                                  )
                                  : const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAttendanceSwitch({
    required String label,
    required bool? value,
    required bool enabled,
    required Function(bool) onChanged,
    Color activeColor = Colors.blue,
    Color inactiveThumbColor = Colors.grey,
  }) {
    return Row(
      children: [
        Text(label),
        Switch(
          value: value ?? false,
          onChanged: enabled ? onChanged : null,
          activeColor: activeColor,
          inactiveThumbColor: inactiveThumbColor,
        ),
      ],
    );
  }
}
