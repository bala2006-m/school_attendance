import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';

import '../../../../services/api_service.dart';
import '../../../components/build_profile_card_mobile.dart';
import '../../../services/teacher_api_service.dart';
import 'reports.dart';

class StudentReportBetweenDays extends StatefulWidget {
  final String schoolId;
  final String username;
  const StudentReportBetweenDays({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentReportBetweenDays> createState() =>
      _StudentReportBetweenDaysState();
}

class _StudentReportBetweenDaysState extends State<StudentReportBetweenDays> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool showClasses = false;
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
      //print('Image decode error: $e');
    }
  }

  Future<void> fetchClasses() async {
    final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
    classes = List.from(cls);

    classes.sort((a, b) {
      int getClassValue(dynamic val) {
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
          final parsed = int.tryParse(val);
          if (parsed != null) return parsed;
          return romanMap[val] ?? 999;
        }

        return 999;
      }

      int classCompare = getClassValue(
        a['class'],
      ).compareTo(getClassValue(b['class']));
      if (classCompare != 0) return classCompare;
      return a['section'].toString().compareTo(b['section'].toString());
    });
  }

  int? parseClassValue(dynamic val) {
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
    };

    if (val is int) return val;
    if (val is String) {
      // Try to parse integer
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;

      // Try Roman numeral
      final upper = val.toUpperCase().trim();
      if (romanMap.containsKey(upper)) return romanMap[upper];

      return null; // KG, PRE-KG, etc.
    }
    return null;
  }

  List<Map<String, dynamic>> filterKinderGarden() {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value == null; // Nursery, LKG, UKG, PRE-KG etc.
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min && value <= max;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    return classes
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    bool isFromDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextButton(
          onPressed: () => _selectDate(context, isFromDate),
          child: Text(
            selectedDate == null
                ? 'Select Date'
                : DateFormat('yyyy-MM-dd').format(selectedDate),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? MobileAppbar(
                    title: 'Report Between Days',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      StaffDashboardState.selectedIndex = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StaffDashboard(
                                username: widget.username,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'Report Between Days'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BuildProfileCard(
                  schoolName: '$schoolName',
                  schoolAddress: '$schoolAddress',
                  schoolPhoto: schoolPhoto,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDatePicker('From', _fromDate, true),
                    _buildDatePicker('To', _toDate, false),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showClasses = true;
                    });
                  },
                  child: const Text('Generate Report'),
                ),
                const SizedBox(height: 16),

                if (showClasses)
                  classes.isEmpty
                      ? const Text(
                        "No Classes Found",
                        style: TextStyle(fontSize: 16),
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
                              (_) => Reports(
                                schoolId: widget.schoolId,
                                classId: classId,
                                username: widget.username,
                                className: className,
                                section: section,
                                from: _fromDate,
                                to: _toDate,
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
