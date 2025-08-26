import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/build_profile_card_mobile.dart';
import 'admin_dashboard.dart';

class StudentAbsent extends StatefulWidget {
  final String schoolId;
  final String username;
  const StudentAbsent({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentAbsent> createState() => _StudentAbsentState();
}

class _StudentAbsentState extends State<StudentAbsent> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;

  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo(), fetchClasses()]);
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
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
                ? const SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                )
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

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => StudentAbsentees(
                                            classId: classId,
                                            className: item['class'],
                                            section: item['section'],
                                            username: widget.username,
                                            schoolId: widget.schoolId,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${item['class']} Std",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "${item['section']} Sec",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
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
      ),
    );
  }
}

class StudentAbsentees extends StatefulWidget {
  final String schoolId;
  final String username;
  final String classId;
  final String className;
  final String section;

  const StudentAbsentees({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<StudentAbsentees> createState() => _StudentAbsenteesState();
}

class _StudentAbsenteesState extends State<StudentAbsentees> {
  DateTime pickedDate = DateTime.now();
  List<Map<String, dynamic>> attendance = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentAbsent(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> init() async {
    final formattedDate =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

    final allAttendance = await ApiService.fetchStudentAttendance(
      date: formattedDate,
      schoolId: widget.schoolId,
      classId: widget.classId,
    );
    setState(() {
      attendance = allAttendance;
    });
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null && selected != pickedDate) {
      setState(() => pickedDate = selected);
      await init();
    }
  }

  List<DataRow> buildAbsentRows(String type) {
    return attendance.where((student) => student['${type}_status'] == 'A').map((
      student,
    ) {
      return DataRow(
        cells: [
          DataCell(Text(student['username'])),
          DataCell(Text(student['name'])),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student Absentees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StudentAbsent(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Student Absentees'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          maximumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 2,
                          shadowColor: Colors.black,

                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => pickDate(context),
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.black,
                          size: 24,
                        ),
                        label: Text(
                          "Pick Date: ${pickedDate.day}/${pickedDate.month}/${pickedDate.year}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: Wrap(
                          // Wrap handles responsive layout automatically
                          alignment: WrapAlignment.center,
                          spacing: 30,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              'Class',
                              widget.className,
                              Colors.teal,
                            ),
                            _buildInfoChip(
                              'Section',
                              widget.section,
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Center(
                      child: Text(
                        "🕘 Forenoon Absentees",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    attendance.any((e) => e['fn_status'] == 'A')
                        ? DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[200],
                          ),
                          columns: const [
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Name')),
                          ],
                          rows: buildAbsentRows('fn'),
                        )
                        : Center(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "No absentees in the forenoon.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        "🌞 Afternoon Absentees",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    attendance.any((e) => e['an_status'] == 'A')
                        ? DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[200],
                          ),
                          columns: const [
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Name')),
                          ],
                          rows: buildAbsentRows('an'),
                        )
                        : Center(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "No absentees in the afternoon.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable UI builder
  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
