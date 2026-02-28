import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/view_profiles/student/student_profile.dart';

import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class ViewStudentProfile extends StatefulWidget {
  const ViewStudentProfile({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<ViewStudentProfile> createState() => _ViewStudentProfileState();
}

class _ViewStudentProfileState extends State<ViewStudentProfile> {
  List<dynamic> classList = [];
  bool isLoading = true;
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final fetchedClassList = await TeacherApiServices.fetchClassData(
      widget.schoolId,
    );

    setState(() {
      classList = fetchedClassList;

      isLoading = false;
    });
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

  List<Map<String, dynamic>> getSortedClasses() {
    List<Map<String, dynamic>> sortedList = List<Map<String, dynamic>>.from(
      classList,
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
    return getSortedClasses()
        .where((item) => parseClassValue(item['class']) == null)
        .toList();
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    return getSortedClasses().where((item) {
      final value = parseClassValue(item['class']);
      return value != null && value >= min && value <= max;
    }).toList();
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    return getSortedClasses().where((item) {
      final value = parseClassValue(item['class']);
      return value != null && value >= min;
    }).toList();
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pop(context);
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
                    title: 'Student Profiles',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pop(context);
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student Profiles',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pop(context);
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
                : classList.isEmpty
                ? Center(
                  child: Text(
                    'No classes found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(10.0),
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
                              (_) => StudentProfile(
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
