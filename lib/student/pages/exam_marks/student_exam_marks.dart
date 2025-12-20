import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/Appbar/student_appbar_desktop.dart';

import '../../../admin/services/admin_api_service.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../../services/student_api_services.dart';
import '../student_dashboard.dart';
import 'build_student_mark_sheet.dart';

class StudentExamMarks extends StatefulWidget {
  const StudentExamMarks({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
  });

  final String schoolId;
  final String username;
  final String classId;

  @override
  State<StudentExamMarks> createState() => _StudentExamMarksState();
}

class _StudentExamMarksState extends State<StudentExamMarks> {
  Map<String, dynamic> studentData = {};
  List<dynamic> studentMarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      studentData =
          (await StudentApiServices.fetchStudentDataUsername(
            username: widget.username,
            schoolId: int.parse(widget.schoolId),
          ))!;

      studentMarks = await AdminApiService.fetchExamMarkStudent(
        schoolId: widget.schoolId,
        classId: widget.classId,
        username: widget.username,
      );
      // Filter studentMarks to include only those with status 'active'
      studentMarks =
          studentMarks.where((mark) => mark['status'] == 'active').toList();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    if (studentData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Exam Reports")),
        body: const Center(
          child: Text(
            'No student data found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final name = studentData['name'] ?? 'No Name';
    final email = studentData['email'] ?? 'No Email';
    String gender = studentData['gender'] ?? 'Unknown';
    gender = gender == 'M' ? 'Male' : 'Female';
    final phone = studentData['mobile'] ?? 'Unknown';

    String dob = 'Unknown';
    if (studentData['DOB'] != null &&
        studentData['DOB'].toString().isNotEmpty) {
      DateTime parsedDate = DateTime.parse(studentData['DOB']);
      dob = DateFormat.yMMMd().format(parsedDate);
    }

    final examTitles =
        studentMarks
            .map<String>(
              (mark) => (mark['title'] ?? 'Untitled').toString().trim(),
            )
            .toSet()
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  schoolId: int.parse(widget.schoolId),
                  username: widget.username,
                  title: 'Exam Reports',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 2;
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
                : StudentAppbarDesktop(
                  title: 'Mark Sheet',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 2;
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
                ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🪪 Student Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              name.isNotEmpty ? name[0] : "?",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.username,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const Divider(height: 30),
                          _infoRow(Icons.person, "Gender", gender),
                          _infoRow(Icons.cake, "Date of Birth", dob),
                          _infoRow(Icons.phone, "Phone", phone),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🧪 Exam Titles Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Available Exam Reports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (examTitles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No exam marks available.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          examTitles.map((title) {
                            return ChoiceChip(
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              label: Text(
                                title,
                                style: const TextStyle(fontSize: 16),
                              ),
                              selected: false,
                              backgroundColor: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (_) {
                                final filteredMarks =
                                    studentMarks
                                        .where(
                                          (item) =>
                                              (item['title'] ?? '')
                                                  .toString()
                                                  .trim()
                                                  .toLowerCase() ==
                                              title.toLowerCase(),
                                        )
                                        .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BuildStudentMarkSheet(
                                          studentMarks: filteredMarks,
                                          classId: widget.classId,
                                          schoolId: widget.schoolId,
                                          username: widget.username,
                                          name: name,
                                          email: email,
                                          gender: gender,
                                          dob: dob,
                                          phone: phone,
                                        ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
