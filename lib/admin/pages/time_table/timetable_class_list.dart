import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../services/api_service.dart';
import '../../../teacher/services/teacher_api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../components/build_profile_card_mobile.dart';
import '../dashboard/admin_dashboard.dart';
import 'time_table.dart';

class TimetableClassList extends StatefulWidget {
  const TimetableClassList({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<TimetableClassList> createState() => _TimetableClassListState();
}

class _TimetableClassListState extends State<TimetableClassList> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // final now = DateTime.now();

    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo(), fetchClasses()]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);

      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
            schoolPhoto = Image.memory(
              imageBytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            );
          } catch (e) {
            debugPrint('Image decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
    }
  }

  Future<void> fetchClasses() async {
    try {
      final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
      classes = List<Map<String, dynamic>>.from(cls);

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
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
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
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
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
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Class List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
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
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Class List',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
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
                  ),
        ),
        body:
            isLoading
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BuildProfileCard(
                          schoolPhoto: schoolPhoto,
                          schoolAddress: schoolAddress ?? '',
                          schoolName: schoolName ?? '',
                        ),

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
      return SizedBox();
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
                              (_) => TimetableScreen(
                                schoolId: widget.schoolId,
                                classId: classId,
                                username: widget.username,
                                className: className,
                                section: section,
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
