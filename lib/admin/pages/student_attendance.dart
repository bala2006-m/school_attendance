import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/build_profile_card_mobile.dart';
import '../widget/notification_dialog.dart';
import 'admin_dashboard.dart';

enum AttendanceSession { FN, AN }

const String presentStatus = 'P';
const String absentStatus = 'A';

class Student extends StatefulWidget {
  final String schoolId;
  final String username;

  const Student({super.key, required this.schoolId, required this.username});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;

  List<Map<String, dynamic>> classes = [];
  Map<String, bool> attendanceStatusMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo(), fetchClasses()]);
    await fetchAttendanceStatusForAll();
    setState(() => isLoading = false);
  }

  Future<void> fetchSchoolInfo() async {
    final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
    schoolName = schoolData[0]['name'];
    schoolAddress = schoolData[0]['address'];

    try {
      if (schoolData[0]['photo'] != null) {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        schoolPhoto = Image.memory(
          imageBytes,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Image decode error: $e');
    }
  }

  Future<void> fetchClasses() async {
    final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
    classes = List.from(cls);

    classes.sort((a, b) {
      int getClassValue(dynamic val) {
        // Convert roman numerals if needed
        const romanMap = {
          'I': 1,
          'II': 2,
          'III': 3,
          'IV': 4,
          'V': 5,
          'VI': 6,
          'VII': 7,
          'VIII': 8,
          'IX': 9,
          'X': 10,
          'XI': 11,
          'XII': 12,
          'XIII': 13,
        };

        if (val is int) return val;
        if (val is String) {
          // Try to parse to int
          final parsed = int.tryParse(val);
          if (parsed != null) return parsed;
          // Check if it's a Roman numeral
          return romanMap[val] ?? 999; // fallback for unknown
        }

        return 999; // fallback for null or unknown
      }

      int classCompare = getClassValue(
        a['class'],
      ).compareTo(getClassValue(b['class']));
      if (classCompare != 0) return classCompare;

      return a['section'].toString().compareTo(b['section'].toString());
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> fetchAttendanceStatusForAll() async {
    final today = DateTime.now();
    final currentDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await Future.wait(
      classes.map((cls) async {
        final classId = cls['id'].toString();
        final result = await ApiService.checkAttendanceStatus(
          widget.schoolId,
          classId,
          currentDate,
        );
        attendanceStatusMap[classId] = result == false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Class List',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    AdminDashboardState.selectedIndex = 0;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AdminDashboard(
                              schoolId: widget.schoolId,
                              username: widget.username,
                            ),
                      ),
                    );
                  },
                )
                : const AdminAppbarDesktop(title: 'Class List'),
      ),
      body:
          isLoading
              ? const SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0)
              : SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BuildProfileCard(
                      schoolPhoto: schoolPhoto,
                      schoolAddress: '$schoolAddress',
                      schoolName: '$schoolName',
                    ),
                    const SizedBox(height: 16),
                    classes.isEmpty
                        ? const Center(
                          child: Text(
                            "No Classes Found",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: classes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.2,
                              ),
                          itemBuilder: (context, index) {
                            final item = classes[index];
                            final classId = item['id'].toString();
                            final isMarked =
                                attendanceStatusMap[classId] ?? false;

                            return GestureDetector(
                              onTap:
                                  isMarked
                                      ? null
                                      : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => StudentAttendance(
                                                  classId: classId,
                                                  className: item['class'],
                                                  section: item['section'],
                                                  schoolId: widget.schoolId,
                                                  username: widget.username,
                                                ),
                                          ),
                                        );
                                      },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isMarked ? Colors.white : Colors.teal,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${item['class']} Std",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isMarked
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "${item['section']} Sec",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              isMarked
                                                  ? Colors.black54
                                                  : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }
}

class StudentAttendance extends StatefulWidget {
  final String classId;
  final String className;
  final String section;
  final String schoolId;
  final String username;
  const StudentAttendance({
    super.key,
    required this.classId,
    required this.className,
    required this.section,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends State<StudentAttendance> {
  bool isAllPresent = true;
  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.FN : AttendanceSession.AN;
  String get sessionKey =>
      session == AttendanceSession.FN ? 'fn_status' : 'an_status';

  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final results = await Future.wait([
        TeacherApiServices.fetchStudentData(
          schoolId: widget.schoolId,
          classId: widget.classId,
        ),
        ApiService.fetchStudentAttendance(
          date: formattedDate,
          schoolId: widget.schoolId,
          classId: widget.classId,
        ),
      ]);

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
    } catch (e) {
      debugPrint("Data loading error: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                Student(schoolId: widget.schoolId, username: widget.username),
      ),
    );
    return false;
  }

  Widget _buildSessionButton(String label, AttendanceSession type) {
    final isSelected = session == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
      ),
      onPressed: () {
        setState(() => session = type);
        _loadData();
      },
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Attendance',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => Student(
                              schoolId: widget.schoolId,
                              username: widget.username,
                            ),
                      ),
                    );
                  },
                )
                : const AdminAppbarDesktop(title: 'Attendance'),
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
                          isAllPresent ? 'All Present' : 'All Absent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAllPresent ? Colors.green : Colors.red,
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
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final today = DateTime.now();
          final formattedDate =
              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

          bool success = true;
          try {
            await Future.wait(
              students.map((student) async {
                await AdminApiService.saveAttendance(
                  username: student['username'],
                  date: formattedDate,
                  session: session.name.toUpperCase(),
                  status: student[sessionKey],
                  schoolId: widget.schoolId,
                  classId: widget.classId,
                );
              }),
            );
          } catch (_) {
            success = false;
          }

          if (!mounted) return;

          showDialog(
            context: context,
            builder:
                (_) => StatusDialog(
                  message1:
                      success
                          ? 'Attendance submitted successfully'
                          : 'Failed to submit attendance',
                  isSuccess: success,
                  onPressed: () => Navigator.of(context).pop(),
                ),
          );
        },
        label: const Text(
          "Attendance Submited",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        backgroundColor: Colors.teal,
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
        return const Icon(Icons.female, color: Colors.pink, size: 42);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 42);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = student[sessionKey];

    final displayStatus = rawStatus == null ? 'NM' : rawStatus;
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
