import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/components/build_profile_card_mobile.dart';

import '../../../../../services/api_service.dart';
import '../../../../../teacher/services/teacher_api_service.dart';
import '../../../../appbar/admin_appbar_desktop.dart';
import '../../../../appbar/admin_appbar_mobile.dart';
import '../../../../widget/pdf_preview_custom_page.dart';
import '../download_student_nomial_role.dart';
import 'build_student_list_class.dart';

class DownloadStudentNomialRoleClasses extends StatefulWidget {
  const DownloadStudentNomialRoleClasses({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<DownloadStudentNomialRoleClasses> createState() =>
      _DownloadStudentNomialRoleClassesState();
}

class _DownloadStudentNomialRoleClassesState
    extends State<DownloadStudentNomialRoleClasses> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes; // store raw bytes for PDF + UI

  @override
  void initState() {
    super.initState();
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
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          schoolPhotoBytes = imageBytes;
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> fetchClasses() async {
    final cls = await TeacherApiServices.fetchClassData(widget.schoolId);
    classes = List<Map<String, dynamic>>.from(cls);
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
      classes,
    );

    // Sort by class first (PRE-KG, LKG, 1-12, I-XII)
    sortedList.sort(
      (a, b) => getSortOrder(a['class']).compareTo(getSortOrder(b['class'])),
    );

    // Then sort by section if present
    sortedList.sort((a, b) {
      int classOrderA = getSortOrder(a['class']);
      int classOrderB = getSortOrder(b['class']);
      int classComparison = classOrderA.compareTo(classOrderB);

      if (classComparison != 0) return classComparison;

      String sectionA = (a['section'] ?? '').toString();
      String sectionB = (b['section'] ?? '').toString();
      if (sectionA.isEmpty && sectionB.isNotEmpty) return 1;
      if (sectionB.isEmpty && sectionA.isNotEmpty) return -1;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DownloadStudentNomialRole(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> handleDownload({
    required List<Map<String, dynamic>> students,
    required String cls,
    required String section,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    students: students,
                    cls: cls,
                    section: section,
                    schoolName: '$schoolName',
                    schoolAddress: '$schoolAddress',
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: 'Student List',
              fileName: 'student_list_${cls}_$section',
            ),
      ),
    );
  }

  Future<void> downloadPdf({
    required String classId,
    required String cls,
    required String section,
  }) async {
    final students = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: classId,
    );
    students.sort((a, b) {
      // Gender: Males ('M') first, then Females
      if (a['gender'] == b['gender']) {
        var aUsername = a['username'].toString();
        var bUsername = b['username'].toString();

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
    handleDownload(students: students, cls: cls, section: section);
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
                    title: 'Student List',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DownloadStudentNomialRole(
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
                    title: 'Student List',

                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DownloadStudentNomialRole(
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
                          schoolPhoto:
                              schoolPhotoBytes != null
                                  ? Image.memory(
                                    schoolPhotoBytes!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          schoolAddress: schoolAddress ?? '',
                          schoolName: schoolName ?? '',
                        ),
                        const SizedBox(height: 20),

                        classes.isEmpty
                            ? const Center(
                              child: Text(
                                "No Classes Found",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                            : Column(
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
      return Container();
    }

    return Container(
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
                      downloadPdf(
                        classId: classId,
                        cls: className,
                        section: section,
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
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
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
