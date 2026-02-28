import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../../components/build_profile_card_mobile.dart';
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
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];
  late Timer refreshTimer;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    init();
    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchClasses();
    });
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo()]);
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
      return;
    }
  }

  Future<void> fetchClasses() async {
    final classes1 = await TeacherApiServices.fetchClassData(widget.schoolId);
    final data = await TeacherApiServices.fetchStaffDataUsername(
      username: widget.username,
      schoolId: int.tryParse(widget.schoolId) ?? 0,
    );
    final ids = data?['class_ids'];

    if (ids != null) {
      final classIds = jsonDecode(ids.toString());

      // Filter classes based on stored class_ids
      final filteredList =
          classes1.where((cls) {
            return classIds.contains(cls['id']);
          }).toList();

      setState(() {
        classes = filteredList;
        isLoading = false;
      });
    }
    // classes = List.from(cls);
  }

  final List<String> kinderGrades = ['PRE-KG', 'LKG', 'UKG', 'KG', 'NURSERY'];
  final Map<String, int> romanMap = {
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
  };

  int? parseClassValue(dynamic val) {
    if (val is int) return val;
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;

      final upper = val.toUpperCase().trim();
      if (romanMap.containsKey(upper)) return romanMap[upper];
      return null; // PRE-KG, LKG, UKG, etc.
    }
    return null;
  }

  int getSortOrder(String className) {
    final upper = className.toUpperCase().trim();
    if (kinderGrades.contains(upper)) return kinderGrades.indexOf(upper);
    final value = parseClassValue(className);
    if (value != null) return value + kinderGrades.length; // After KG classes
    return 999; // Unknown class
  }

  List<Map<String, dynamic>> sortByClassAndSection(
    List<Map<String, dynamic>> classList,
  ) {
    classList.sort((a, b) {
      int classComparison = getSortOrder(
        a['class'],
      ).compareTo(getSortOrder(b['class']));
      if (classComparison != 0) return classComparison;

      String sectionA = (a['section'] ?? '').toString().toUpperCase().trim();
      String sectionB = (b['section'] ?? '').toString().toUpperCase().trim();
      return sectionA.compareTo(sectionB);
    });
    return classList;
  }

  List<Map<String, dynamic>> getSortedClasses() {
    List<Map<String, dynamic>> sortedList = List<Map<String, dynamic>>.from(
      classes,
    );

    // Sort by class first (PRE-KG, LKG, 1-12, I-XII)
    sortedList.sort(
      (a, b) => getSortOrder(a['class']).compareTo(getSortOrder(b['class'])),
    );

    // Then sort by section if present
    sortedList.sort((a, b) {
      int classComparison = getSortOrder(
        a['class'],
      ).compareTo(getSortOrder(b['class']));
      if (classComparison != 0) return classComparison;

      // Sort by section alphabetically (nulls last)
      String sectionA = (a['section'] ?? '').toString();
      String sectionB = (b['section'] ?? '').toString();
      return sectionA.compareTo(sectionB);
    });

    return sortedList;
  }

  List<Map<String, dynamic>> filterKinderGarden() {
    var filtered =
        classes
            .where((item) => parseClassValue(item['class']) == null)
            .toList();
    return sortByClassAndSection(filtered);
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    var filtered =
        classes.where((item) {
          final val = parseClassValue(item['class']);
          return val != null && val >= min && val <= max;
        }).toList();
    return sortByClassAndSection(filtered);
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    var filtered =
        classes.where((item) {
          final val = parseClassValue(item['class']);
          return val != null && val >= min;
        }).toList();
    return sortByClassAndSection(filtered);
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StaffDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
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
                        if (value != null) setState(() => tempMonth = value);
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
                        if (value != null) setState(() => tempYear = value);
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
    // final isMobile = MediaQuery.of(context).size.width < 600;
    final String formattedMonth = DateFormat.MMM().format(
      DateTime(selectedYear, selectedMonth),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: MobileAppbar(
            username: widget.username,
            schoolId: widget.schoolId.toString(),
            title: 'Monthly Attendance',
            enableDrawer: false,
            enableBack: true,
            onBack: () {
              StaffDashboardState.selectedIndex = 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => StaffDashboard(
                        username: widget.username,
                        schoolId: widget.schoolId,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BuildProfileCard(
                        schoolName: schoolName ?? '',
                        schoolAddress: schoolAddress ?? '',
                        schoolPhoto: schoolPhoto,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(
                            "Month: $formattedMonth",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          trailing: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text("Change"),
                            onPressed: _showMonthYearPicker,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      classes.isEmpty
                          ? const Center(
                            child: Text(
                              "No Classes Found",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                          : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClassContainer(
                                  title: "Nursery",
                                  classes: filterKinderGarden(),
                                  context: context,
                                  isKinderGarden: true,
                                ),
                                const SizedBox(height: 20),

                                _buildClassContainer(
                                  title: "Classes 1 to 5",
                                  classes: filterClasses(1, 5),
                                  context: context,
                                  isKinderGarden: false,
                                ),
                                const SizedBox(height: 20),
                                _buildClassContainer(
                                  title: "Classes 6 and above",
                                  classes: filterClassesFrom(6),
                                  context: context,
                                  isKinderGarden: false,
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildClassContainer({
    required String title,
    required List<Map<String, dynamic>> classes,
    required BuildContext context,
    required bool isKinderGarden,
  }) {
    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      //height: MediaQuery.sizeOf(context).height / 5,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
            children:
                classes.map((classItem) {
                  final classId = classItem['id'].toString();
                  final className = classItem['class'] ?? 'Unnamed';
                  final section = classItem['section'] ?? '';

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudentList(
                                schoolId: widget.schoolId,
                                classId: classId,
                                username: widget.username,
                                className: className,
                                section: section,
                                month: '$selectedMonth',
                                year: '$selectedYear',
                              ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.teal,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Split into FN + AN halves
                          Column(
                            children: [
                              Text(
                                isKinderGarden ? className : 'Class $className',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sec $section',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
