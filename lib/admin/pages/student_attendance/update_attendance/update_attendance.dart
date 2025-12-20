import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/student_attendance/update_attendance/update_classes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/notification_dialog.dart';

class StudentAttendance extends StatefulWidget {
  final String classId;
  final String className;
  final String section;
  final String schoolId;
  final String date;
  final String username;
  const StudentAttendance({
    super.key,
    required this.classId,
    required this.className,
    required this.section,
    required this.schoolId,
    required this.date,
    required this.username,
  });

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

enum AttendanceSession { fN, aN }

class _StudentAttendanceState extends State<StudentAttendance> {
  bool? attendanceStatusMapFn;
  bool? attendanceStatusMapAn;
  bool isAllPresent = true;
  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.fN : AttendanceSession.aN;
  String get sessionKey =>
      session == AttendanceSession.fN ? 'fn_status' : 'an_status';
  List<Map<String, dynamic>> holidays = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> originalStudents = [];
  bool isLoading = true;
  // Add at the top
  bool isFnHoliday = false;
  bool isAnHoliday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchHolidays(); // wait for holiday check
      await _loadData();

      final hour = DateTime.now().hour;
      if (hour < 13) {
        // Before 1 PM - default FN session logic
        if (!isFnHoliday && attendanceStatusMapFn == false) {
          _showUnmarkedDialog();
        } else if (isFnHoliday) {
          _showHolidayDialog('FN');
        }
      } else {
        // After 1 PM
        if (!isAnHoliday && attendanceStatusMapAn == true) {
          // If AN is already marked, switch to AN
          setState(() => session = AttendanceSession.aN);
          _loadData();
        } else if (!isAnHoliday && attendanceStatusMapFn == true) {
          // Stay in FN if AN is not marked but FN is marked
          setState(() => session = AttendanceSession.fN);
          _loadData();
        } else if (!isAnHoliday && attendanceStatusMapAn == false) {
          // If AN not marked and FN also not marked, show dialog
          _showUnmarkedDialog();
        }

        if (isAnHoliday) {
          _showHolidayDialog('AN');
        }
      }
    });
  }

  Future<void> fetchHolidays() async {
    holidays = await StudentApiServices.fetchHolidaysClasses(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    final today = DateTime.parse(widget.date);
    final todayStr = today.toIso8601String().split("T")[0];

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

    final isMarked =
        type == AttendanceSession.fN
            ? attendanceStatusMapFn ?? false
            : attendanceStatusMapAn ?? false;

    final isHoliday = type == AttendanceSession.fN ? isFnHoliday : isAnHoliday;

    final currentHour = DateTime.now().hour;

    // Disable FN if time > 1PM and FN is unmarked
    final isFnLateUnmarked =
        type == AttendanceSession.fN &&
        currentHour >= 13 &&
        !(attendanceStatusMapFn ?? false);

    // Disable AN if time < 1PM and AN is unmarked
    final isAnEarlyUnmarked =
        type == AttendanceSession.aN &&
        currentHour < 13 &&
        !(attendanceStatusMapAn ?? false);

    final isDisabled =
        !isMarked || isHoliday || isFnLateUnmarked || isAnEarlyUnmarked;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
      ),
      onPressed:
          isDisabled
              ? null
              : () {
                setState(() => session = type);
                _loadData();
              },
      child: Text(
        label,
        style: TextStyle(
          color: isDisabled ? Colors.grey : Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }

  void _showUnmarkedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Attendance Not Marked"),
            content: const Text(
              "Attendance for this session has not been marked.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Classes(
                            schoolId: widget.schoolId,
                            date: widget.date,
                            username: widget.username,
                          ),
                    ),
                  );
                },
                child: const Text("OK"),
              ),
            ],
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
      attendanceStatusMapFn = await ApiService.checkAttendanceStatusSession(
        widget.schoolId,
        widget.classId,
        widget.date,
        'FN',
      );
      attendanceStatusMapAn = await ApiService.checkAttendanceStatusSession(
        widget.schoolId,
        widget.classId,
        widget.date,
        'AN',
      );
      final fetchedStudents = results[0];
      final attendance = results[1] as List<dynamic>;

      final Map<String, String> attendanceMap = {
        for (var entry in attendance)
          if (entry['username'] != null)
            entry['username']:
                (entry[sessionKey] == null
                        ? 'NM'
                        : entry[sessionKey] == 'P'
                        ? presentStatus
                        : absentStatus)
                    .toString(),
      };
      students =
          fetchedStudents.map((student) {
            final username = student['username'];
            final status = attendanceMap[username] ?? absentStatus;
            return {...student, sessionKey: status};
          }).toList();
      students.sort((a, b) {
        // Gender: Males ('M') first, then Females
        if (a['gender'] == b['gender']) {
          var aUsername = a['name'].toString();
          var bUsername = b['name'].toString();

          // Check if both usernames are numeric
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);

          if (numA != null && numB != null) {
            // Both numeric: compare numerically
            return numA.compareTo(numB);
          } else {
            // Otherwise: compare as strings
            return aUsername.compareTo(bUsername);
          }
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
    Navigator.push(
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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
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
                  onBack: () {
                    Navigator.push(
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
                  },
                )
                : AdminAppbarDesktop(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Attendance',

                  onBack: () {
                    Navigator.push(
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
                  },
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
                    _buildHeader(formattedDate),
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
                          isAllPresent ? 'All Absent' : 'All Present',
                          style: TextStyle(
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
                                    students[index][sessionKey] == presentStatus
                                        ? absentStatus
                                        : presentStatus;
                              });
                            },
                          ),
                    ),
                    SizedBox(height: 70),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            hasChanges
                ? () async {
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

                    // 🔑 reset original copy after successful save
                    originalStudents =
                        students
                            .map((s) => Map<String, dynamic>.from(s))
                            .toList();
                    setState(() {}); // refresh UI so FAB disables
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
                                    ? 'Attendance updated successfully'
                                    : 'Failed to update attendance',
                            isSuccess: success,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                    );
                  }
                }
                : null,

        label: const Text(
          "Update",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        backgroundColor:
            hasChanges ? Colors.teal : Colors.grey, // visual feedback
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

    final displayStatus = rawStatus ?? 'NM';
    final isPresent = displayStatus == presentStatus;

    Color backgroundColor;
    Color textColor;

    if (displayStatus == 'NM') {
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
