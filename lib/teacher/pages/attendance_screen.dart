import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../student/services/student_api_services.dart';
import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../pages/class_list.dart';

enum AttendanceSession { FN, AN }

class AttendanceConstants {
  static const String presentStatus = 'P';
  static const String absentStatus = 'A';
  static const String noMarkStatus = 'NM';
  static const String holidayStatus = 'H';
}

class AttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String className;
  final String section;
  final String username;

  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
    required this.username,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  bool isSubmitting = false;

  DateTime selectedDate = DateTime.now();
  bool isFnHoliday = false;
  bool isAnHoliday = false;
  List<Map<String, dynamic>> holidays = [];

  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.FN : AttendanceSession.AN;

  String get sessionKey =>
      session == AttendanceSession.FN ? 'fn_status' : 'an_status';

  bool get isAllPresent =>
      students.isNotEmpty &&
      students.every((s) => s[sessionKey] == AttendanceConstants.presentStatus);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchHolidays();

      // If both sessions are holiday
      if (isFnHoliday && isAnHoliday) {
        _showHolidayDialog("Both Sessions");
        setState(() {
          isLoading = false;
          students.clear(); // no list
        });
        return;
      }

      // FN holiday and currently FN
      if (session == AttendanceSession.FN && isFnHoliday) {
        _showHolidayDialog("FN");
        if (!isAnHoliday) {
          setState(() => session = AttendanceSession.AN);
        }
      }

      // AN holiday and currently AN
      if (session == AttendanceSession.AN && isAnHoliday) {
        _showHolidayDialog("AN");
        if (!isFnHoliday) {
          setState(() => session = AttendanceSession.FN);
        }
      }

      await init();
    });
  }

  Future<void> fetchHolidays() async {
    holidays = await StudentApiServices.fetchHolidaysClasses(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var holiday in holidays) {
      final holidayDate = holiday['date'].toString().split("T")[0];
      if (holidayDate == todayStr) {
        isFnHoliday =
            (holiday['fn'] ?? '').toString().toUpperCase() ==
            AttendanceConstants.holidayStatus;
        isAnHoliday =
            (holiday['an'] ?? '').toString().toUpperCase() ==
            AttendanceConstants.holidayStatus;
        break;
      }
    }
  }

  void _showHolidayDialog(String sessionLabel) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Holiday"),
            content: Text(
              sessionLabel == "Both Sessions"
                  ? "Attendance for both sessions is not allowed today due to a holiday."
                  : "Attendance for $sessionLabel session is not allowed today due to a holiday.",
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        sessionLabel == "Both Sessions"
                            ? Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ClassList(
                                      username: widget.username,
                                      schoolId: widget.schoolId,
                                    ),
                              ),
                            )
                            : Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
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

    final Map<String, String> fnMap = {
      for (var entry in attendance)
        if (entry['username'] != null)
          entry['username']:
              (entry['fn_status'] ?? AttendanceConstants.absentStatus)
                  .toString(),
    };

    final Map<String, String> anMap = {
      for (var entry in attendance)
        if (entry['username'] != null)
          entry['username']:
              (entry['an_status'] ?? AttendanceConstants.absentStatus)
                  .toString(),
    };
    students =
        studentJsonList
            .where((s) => s['username'] != null && s['name'] != null)
            .map<Map<String, dynamic>>((s) {
              String fnStatus =
                  fnMap[s['username']] ?? AttendanceConstants.presentStatus;
              String anStatus =
                  anMap[s['username']] ?? AttendanceConstants.presentStatus;

              if (fnStatus == AttendanceConstants.noMarkStatus) {
                fnStatus = AttendanceConstants.presentStatus;
              }
              if (anStatus == AttendanceConstants.noMarkStatus) {
                anStatus = AttendanceConstants.presentStatus;
              }

              return {...s, 'fn_status': fnStatus, 'an_status': anStatus};
            })
            .toList();

    setState(() {
      isLoading = false;
    });
  }

  bool _isForenoonAllowed() {
    final now = TimeOfDay.now();
    return now.hour >= 9 && now.hour < 13;
  }

  bool _isAfternoonAllowed() {
    final now = TimeOfDay.now();
    return now.hour >= 13 && now.hour <= 17;
  }

  Future<void> _submitAttendance() async {
    if (isFnHoliday && isAnHoliday) {
      _showSnack(
        "Attendance not allowed — today is a holiday for both sessions.",
      );
      return;
    }

    final isFNAllowed = _isForenoonAllowed();
    final isANAllowed = _isAfternoonAllowed();

    if (session == AttendanceSession.FN) {
      if (isFnHoliday) {
        _showHolidayDialog("FN");
        return;
      }
      if (!isFNAllowed) {
        _showSnack("FN attendance can only be marked between 9 AM and 1 PM.");
        return;
      }
    }

    if (session == AttendanceSession.AN) {
      if (isAnHoliday) {
        _showHolidayDialog("AN");
        return;
      }
      if (!isANAllowed) {
        _showSnack("AN attendance can only be marked between 1 PM and 5 PM.");
        return;
      }
    }

    setState(() => isSubmitting = true);

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<Future<bool>> requests = [];

    for (var student in students) {
      final id = student['username']?.toString();
      if (id == null || id.isEmpty) continue;

      if (session == AttendanceSession.FN && isFNAllowed) {
        requests.add(
          TeacherApiServices.postStudentAttendance(
            username: id,
            date: formattedDate,
            session: 'FN',
            status: student['fn_status'] ?? AttendanceConstants.absentStatus,
            schoolId: widget.schoolId,
            classId: widget.classId,
          ),
        );
      }

      if (session == AttendanceSession.AN && isANAllowed) {
        requests.add(
          TeacherApiServices.postStudentAttendance(
            username: id,
            date: formattedDate,
            session: 'AN',
            status: student['an_status'] ?? AttendanceConstants.absentStatus,
            schoolId: widget.schoolId,
            classId: widget.classId,
          ),
        );
      }
    }

    final results = await Future.wait(requests);
    final anySuccess = results.contains(true);

    setState(() => isSubmitting = false);

    _showSnack(
      anySuccess
          ? 'Attendance submitted successfully!'
          : 'Failed to submit attendance',
      success: anySuccess,
    );
  }

  void _markAll(bool present) {
    setState(() {
      for (var student in students) {
        student[sessionKey] =
            present
                ? AttendanceConstants.presentStatus
                : AttendanceConstants.absentStatus;
      }
    });
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green : Colors.red,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);
    final isMobile = MediaQuery.of(context).size.width < 500;
    bool isForenoonAllowed() {
      final now = TimeOfDay.now();
      return now.hour >= 9 && now.hour < 13;
    }

    bool isAfternoonAllowed() {
      final now = TimeOfDay.now();
      return now.hour >= 13 && now.hour <= 17;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Attendance',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ClassList(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Attendance'),
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Session : ",
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        _buildSessionButton('FN', AttendanceSession.FN),
                        const SizedBox(width: 8),
                        _buildSessionButton('AN', AttendanceSession.AN),
                      ],
                    ),
                    _buildHeader(formattedDate),
                    _buildStats(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _markAll(!isAllPresent),
                        icon: Icon(
                          isAllPresent ? Icons.check_circle : Icons.cancel,
                        ),
                        label: Text(
                          isAllPresent ? 'All Absent' : 'All Present',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAllPresent ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: students.length,
                      itemBuilder:
                          (context, index) => StudentCard(
                            student: students[index],
                            sessionKey: sessionKey,
                            onToggle: () {
                              setState(() {
                                students[index][sessionKey] =
                                    students[index][sessionKey] ==
                                            AttendanceConstants.presentStatus
                                        ? AttendanceConstants.absentStatus
                                        : AttendanceConstants.presentStatus;
                              });
                            },
                          ),
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),

      floatingActionButton:
          (isFnHoliday && isAnHoliday)
              ? null
              : FloatingActionButton.extended(
                onPressed: () {
                  if (isSubmitting) return;
                  if (session == AttendanceSession.FN && !isForenoonAllowed())
                    return;
                  if (session == AttendanceSession.AN && !isAfternoonAllowed())
                    return;
                  _submitAttendance();
                },
                label: Text(
                  "Submit",
                  style: TextStyle(
                    color:
                        (isSubmitting ||
                                (session == AttendanceSession.FN &&
                                    !isForenoonAllowed()) ||
                                (session == AttendanceSession.AN &&
                                    !isAfternoonAllowed()))
                            ? Colors.black
                            : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: Icon(
                  Icons.save,
                  color:
                      (isSubmitting ||
                              (session == AttendanceSession.FN &&
                                  !isForenoonAllowed()) ||
                              (session == AttendanceSession.AN &&
                                  !isAfternoonAllowed()))
                          ? Colors.black
                          : Colors.white,
                ),
                backgroundColor:
                    (isSubmitting ||
                            (session == AttendanceSession.FN &&
                                !isForenoonAllowed()) ||
                            (session == AttendanceSession.AN &&
                                !isAfternoonAllowed()))
                        ? Colors.grey
                        : Colors.teal,
              ),
    );
  }

  Widget _buildSessionButton(String label, AttendanceSession type) {
    final isSelected = session == type;
    final isHoliday = type == AttendanceSession.FN ? isFnHoliday : isAnHoliday;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
      ),
      onPressed:
          isHoliday
              ? null
              : () {
                setState(() => session = type);
              },
      child: Text(
        label,
        style: TextStyle(
          color: isHoliday ? Colors.grey : Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildHeader(String date) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Table(
      children: [
        const TableRow(
          children: [
            Text(
              "Class",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Section",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Date",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        TableRow(
          children: [
            Text(
              widget.className,
              style: const TextStyle(color: Colors.blue, fontSize: 18),
            ),
            Text(
              widget.section,
              style: const TextStyle(color: Colors.blue, fontSize: 18),
            ),
            Text(
              date,
              style: const TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStats() {
    int total = students.length;
    int present =
        students
            .where((s) => s[sessionKey] == AttendanceConstants.presentStatus)
            .length;
    int absent =
        students
            .where((s) => s[sessionKey] == AttendanceConstants.absentStatus)
            .length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        children: [
          const TableRow(
            children: [
              Text(
                "Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "Present",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "Absent",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          TableRow(
            children: [
              Text("$total", style: const TextStyle(fontSize: 18)),
              Text("$present", style: const TextStyle(fontSize: 18)),
              Text("$absent", style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onToggle;
  final String sessionKey;

  const StudentCard({
    super.key,
    required this.student,
    required this.sessionKey,
    required this.onToggle,
  });

  Icon getGenderIcon(String? gender) {
    switch (gender) {
      case 'M':
        return const Icon(Icons.male, color: Colors.blue, size: 42);
      case 'F':
        return const Icon(Icons.female, color: Colors.pink, size: 42);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 42);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = student[sessionKey];
    final displayStatus = rawStatus ?? AttendanceConstants.noMarkStatus;
    final isPresent = displayStatus == AttendanceConstants.presentStatus;

    Color backgroundColor;
    Color textColor;

    if (displayStatus == AttendanceConstants.noMarkStatus) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange;
    } else if (isPresent) {
      backgroundColor = Colors.teal[100]!;
      textColor = Colors.teal;
    } else {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          getGenderIcon(student['gender']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  student['mobile'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () async {
              final phone = student['mobile'];
              if (phone == null || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number not available')),
                );
                return;
              }

              if (kIsWeb ||
                  Platform.isWindows ||
                  Platform.isMacOS ||
                  Platform.isLinux) {
                final whatsappUrl = Uri.parse("https://wa.me/$phone");
                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(
                    whatsappUrl,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch WhatsApp')),
                  );
                }
              } else {
                final telUrl = Uri.parse("tel:$phone");
                if (await canLaunchUrl(telUrl)) {
                  await launchUrl(telUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not make a call')),
                  );
                }
              }
            },
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
