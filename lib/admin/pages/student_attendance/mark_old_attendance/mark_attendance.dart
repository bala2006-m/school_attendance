import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/notification_dialog.dart';
import 'classes.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({
    super.key,
    required this.classId,
    required this.className,
    required this.section,
    required this.schoolId,
    required this.date,
    required this.username,
  });

  final String classId;
  final String className;
  final String section;
  final String schoolId;
  final String date;
  final String username;

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

enum AttendanceSession { fN, aN }

class _MarkAttendanceState extends State<MarkAttendance> {
  // ✅ Define attendance status constants
  static const String presentStatus = 'P';
  static const String absentStatus = 'A';
  static const String notMarkedStatus = 'NM';

  bool isAllPresent = true;
  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.fN : AttendanceSession.aN;

  String get sessionKey =>
      session == AttendanceSession.fN ? 'fn_status' : 'an_status';

  List<Map<String, dynamic>> holidays = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> originalStudents = [];
  bool isLoading = true;

  bool isFnHoliday = false;
  bool isAnHoliday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchHolidays();
      await _loadData();
    });
  }

  Future<void> fetchHolidays() async {
    holidays = await StudentApiServices.fetchHolidaysClasses(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    final todayStr =
        DateTime.parse(widget.date).toIso8601String().split("T")[0];

    for (var holiday in holidays) {
      final holidayDate = holiday['date'].toString().split("T")[0];
      if (holidayDate == todayStr) {
        isFnHoliday = (holiday['fn'] ?? '').toString().toUpperCase() == 'H';
        isAnHoliday = (holiday['an'] ?? '').toString().toUpperCase() == 'H';
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
              "Attendance for $sessionLabel session is not allowed today due to a holiday.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget _buildSessionButton(String label, AttendanceSession type) {
    final isSelected = session == type;
    final isHoliday = type == AttendanceSession.fN ? isFnHoliday : isAnHoliday;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Colors.teal
                : (isHoliday ? Colors.red[200] : Colors.grey[300]),
      ),
      onPressed:
          isHoliday
              ? () => _showHolidayDialog(label)
              : () {
                setState(() => session = type);
                _loadData();
              },
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 20),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        TeacherApiServices.fetchStudentData(
          schoolId: widget.schoolId,
          classId: widget.classId,
        ),
        ApiService.fetchStudentAttendance(
          date: widget.date,
          schoolId: widget.schoolId,
          classId: widget.classId,
        ),
      ]);

      final fetchedStudents = results[0] as List<dynamic>;
      final attendance = results[1] as List<dynamic>;

      students =
          fetchedStudents.map<Map<String, dynamic>>((student) {
            final username = student['username'];
            final existing = attendance.firstWhere(
              (a) => a['username'] == username,
              orElse: () => <String, dynamic>{}, // ✅ typed empty map
            );

            return {
              ...student,
              sessionKey:
                  existing[sessionKey] ?? presentStatus, // ✅ Default to 'P'
            };
          }).toList();

      // ✅ Sort students
      students.sort((a, b) {
        if (a['gender'] == b['gender']) {
          var aUsername = a['name'].toString();
          var bUsername = b['name'].toString();
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);
          return (numA != null && numB != null)
              ? numA.compareTo(numB)
              : aUsername.compareTo(bUsername);
        } else if (a['gender'] == 'M') {
          return -1;
        } else {
          return 1;
        }
      });

      originalStudents =
          students.map((s) => Map<String, dynamic>.from(s)).toList();
    } catch (e) {
      setState(() => isLoading = false);
    }

    if (mounted) setState(() => isLoading = false);
  }

  bool get hasChanges {
    if (students.length != originalStudents.length) return true;
    for (int i = 0; i < students.length; i++) {
      if (students[i][sessionKey] != originalStudents[i][sessionKey]) {
        return true;
      }
    }
    return false;
  }

  Future<bool> onWillPop() async {
    if (hasChanges) {
      final result = await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Unsaved changes"),
              content: const Text(
                "You have unsaved attendance changes. Leave anyway?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Leave"),
                ),
              ],
            ),
      );
      if (result != true) return false;
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => Classes(
                schoolId: widget.schoolId,
                date: widget.date,
                username: widget.username,
              ),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Attendance',
                    onBack: onWillPop,
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : (isFnHoliday && isAnHoliday)
                ? const Center(
                  child: Text(
                    "Today is a holiday.\nAttendance cannot be marked.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                )
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
                          _buildSessionButton('FN', AttendanceSession.fN),
                          const SizedBox(width: 8),
                          _buildSessionButton('AN', AttendanceSession.aN),
                        ],
                      ),
                      _buildHeader(),
                      _buildStats(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              for (var i = 0; i < students.length; i++) {
                                students[i][sessionKey] =
                                    isAllPresent ? presentStatus : absentStatus;
                              }
                              isAllPresent = !isAllPresent;
                            });
                          },
                          icon: Icon(
                            isAllPresent ? Icons.check_circle : Icons.cancel,
                          ),
                          label: Text(
                            isAllPresent
                                ? 'Mark All Absent'
                                : 'Mark All Present',
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
                                              presentStatus
                                          ? absentStatus
                                          : presentStatus;
                                });
                              },
                            ),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            bool success = true;
            try {
              await Future.wait(
                students.map((student) async {
                  await AdminApiService.saveAttendance(
                    username: student['username'],
                    date: widget.date,
                    session: session.name.toUpperCase(),
                    status: student[sessionKey],
                    schoolId: widget.schoolId,
                    classId: widget.classId,
                  );
                }),
              );

              originalStudents =
                  students.map((s) => Map<String, dynamic>.from(s)).toList();
              setState(() {});
            } catch (_) {
              success = false;
            }

            if (!mounted) return;
            if (context.mounted) {
              showDialog(
                context: context,
                builder:
                    (_) => StatusDialog(
                      message1:
                          success
                              ? 'Attendance Submitted successfully'
                              : 'Failed to Submit attendance',
                      isSuccess: success,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onWillPop();
                      },
                    ),
              );
            }
          },
          label: const Text(
            "Submit",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.save, color: Colors.white),
          backgroundColor: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
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
              widget.date,
              style: const TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStats() {
    int total = students.length;
    int present = students.where((s) => s[sessionKey] == presentStatus).length;
    int absent = students.where((s) => s[sessionKey] == absentStatus).length;

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
        return const Icon(Icons.female, color: Colors.red, size: 42);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 42);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = student[sessionKey];
    final displayStatus = rawStatus ?? _MarkAttendanceState.notMarkedStatus;
    final isPresent = displayStatus == _MarkAttendanceState.presentStatus;

    Color backgroundColor;
    Color textColor;

    if (displayStatus == _MarkAttendanceState.notMarkedStatus) {
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color:
                        student['gender'] == 'M'
                            ? Colors.blue
                            : student['gender'] == 'F'
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                Text(
                  student['username'] ?? '',
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

              if (kIsWeb || isDesktopPlatform) {
                final whatsappUrl = Uri.parse("https://wa.me/$phone");
                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(
                    whatsappUrl,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch WhatsApp'),
                      ),
                    );
                  }
                }
              } else {
                final telUrl = Uri.parse("tel:$phone");
                if (await canLaunchUrl(telUrl)) {
                  await launchUrl(telUrl);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not make a call')),
                    );
                  }
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
