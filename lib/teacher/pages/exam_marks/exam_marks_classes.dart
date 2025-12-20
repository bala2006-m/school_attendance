import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../services/api_service.dart';
import '../../appbar/mobile_appbar.dart';
import '../../components/build_profile_card_mobile.dart';
import '../../services/teacher_api_service.dart';
import '../staff_dashboard.dart';
import 'add_exam_marks.dart';

class ExamMarksClasses extends StatefulWidget {
  const ExamMarksClasses({
    super.key,
    required this.schoolId,
    required this.username,
  });

  final String schoolId;
  final String username;

  @override
  State<ExamMarksClasses> createState() => _ExamMarksClassesState();
}

class _ExamMarksClassesState extends State<ExamMarksClasses> {
  List<dynamic> classList = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;

  final List<String> kinderGrades = ['PRE-KG', 'LKG', 'UKG', 'KG', 'NURSERY'];
  final Map<String, int> romanMap = const {
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

  @override
  void initState() {
    super.initState();
    fetchDatas();
  }

  Future<void> fetchDatas() async {
    try {
      await Future.wait([initClassData(), fetchSchoolInfo()]);
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> initClassData() async {
    final fetchedClassList = await TeacherApiServices.fetchClassData(
      widget.schoolId,
    );
    setState(() {
      classList = fetchedClassList;
    });
  }

  Future<void> fetchSchoolInfo() async {
    final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
    if (schoolData.isNotEmpty) {
      schoolName = schoolData[0]['name'];
      schoolAddress = schoolData[0]['address'];

      if (schoolData[0]['photo'] != null) {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        schoolPhoto = Image.memory(
          imageBytes,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    }
  }

  // ---------------- Sorting and Filtering Helpers ----------------

  String normalize(String val) => val.toUpperCase().trim();

  int? parseClassValue(dynamic val) {
    if (val is int) return val;
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;

      final upper = normalize(val);
      return romanMap[upper];
    }
    return null;
  }

  int getSortOrder(String className) {
    final upper = normalize(className);
    if (kinderGrades.contains(upper)) return kinderGrades.indexOf(upper);
    final value = parseClassValue(className);
    return value != null ? value + kinderGrades.length : 999;
  }

  List<Map<String, dynamic>> getSortedClasses() {
    final sortedList = List<Map<String, dynamic>>.from(classList);
    sortedList.sort((a, b) {
      int classComparison = getSortOrder(
        a['class'],
      ).compareTo(getSortOrder(b['class']));
      if (classComparison != 0) return classComparison;

      final sectionA = (a['section'] ?? '').toString();
      final sectionB = (b['section'] ?? '').toString();
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    // final isMobile = MediaQuery.of(context).size.width < 500;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(190),
        child: MobileAppbar(
          username: widget.username,
          schoolId: widget.schoolId.toString(),
          title: 'Class List',
          enableDrawer: false,
          enableBack: true,
          onBack: () {
            StaffDashboardState.selectedIndex = 0;
            Navigator.pushReplacement(
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
              : RefreshIndicator(
                onRefresh: fetchDatas,
                child:
                    classList.isEmpty
                        ? ListView(
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                'No classes found.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                        : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BuildProfileCard(
                                schoolPhoto: schoolPhoto,
                                schoolAddress: schoolAddress ?? '',
                                schoolName: schoolName ?? '',
                              ),
                              const SizedBox(height: 16),
                              _buildClassContainer(
                                title: "Nursery / KG",
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
                              (_) => AddExamMarks(
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
                                style: TextStyle(
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
