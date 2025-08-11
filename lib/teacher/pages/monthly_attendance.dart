import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../components/build_profile_card_mobile.dart';
import 'monthly_student_list.dart';

class MonthlyAttendance extends StatefulWidget {
  final String schoolId;
  final String username;

  const MonthlyAttendance({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<MonthlyAttendance> createState() => _MonthlyAttendanceState();
}

class _MonthlyAttendanceState extends State<MonthlyAttendance> {
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StaffDashboard(username: widget.username),
      ),
    );
    return false;
  }

  void _showMonthYearPicker() {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Month and Year"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: tempMonth,
                      isExpanded: true,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            DateFormat.MMMM().format(DateTime(0, index + 1)),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => tempMonth = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: tempYear,
                      isExpanded: true,
                      items: List.generate(20, (index) {
                        final year = DateTime.now().year - 10 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => tempYear = value);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedMonth = tempMonth;
                  selectedYear = tempYear;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final String formattedMonth = DateFormat.yMMMM().format(
      DateTime(selectedYear, selectedMonth),
    );

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? MobileAppbar(
                    title: 'Monthly Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      StaffDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  StaffDashboard(username: widget.username),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'Monthly Attendance'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text("Selected Month: $formattedMonth"),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text("Change"),
                      onPressed: _showMonthYearPicker,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  child: ClassesMonth(
                    schoolId: widget.schoolId,
                    selectedMonth: selectedMonth,
                    selectedYear: selectedYear,
                    username: widget.username,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClassesMonth extends StatefulWidget {
  final String schoolId;
  final int selectedMonth;
  final int selectedYear;
  final String username;
  const ClassesMonth({
    super.key,
    required this.schoolId,
    required this.selectedMonth,
    required this.selectedYear,
    required this.username,
  });

  @override
  State<ClassesMonth> createState() => _ClassesMonthState();
}

class _ClassesMonthState extends State<ClassesMonth> {
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

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0)
        : SingleChildScrollView(
          //padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BuildProfileCard(),
              const SizedBox(height: 16),
              classes.isEmpty
                  ? const Text(
                    "No Classes Found",
                    style: TextStyle(fontSize: 16),
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => StudentList(
                                    schoolId: widget.schoolId,
                                    classId: item['id'].toString(),
                                    month: '${widget.selectedMonth}',
                                    year: '${widget.selectedYear}',
                                    username: widget.username,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${item['class']} Std",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${item['section']} Sec",
                                  style: const TextStyle(
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
        );
  }
}
