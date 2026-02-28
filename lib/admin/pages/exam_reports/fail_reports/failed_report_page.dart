import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import 'build_pass_report_pdf.dart';
import 'pass_reports.dart';
import 'dart:convert';
import 'dart:typed_data';

class PassReportPage extends StatefulWidget {
  const PassReportPage({
    super.key,
    required this.username,
    required this.schoolId,
    required this.title,
  });
  final String username;
  final String schoolId;
  final String title;
  @override
  State<PassReportPage> createState() => _PassReportPageState();
}

class _PassReportPageState extends State<PassReportPage> {
  List<Map<String, dynamic>> classes = [];
  List<dynamic> schoolWiseMark = [];
  List<dynamic> classWiseMark = [];
  bool isLoading = true;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetch();
      fetchSchoolWise();
      fetchSchoolInfo();
    });
    super.initState();
  }

  Future<void> fetch() async {
    final classes1 = await AdminApiService.fetchExamMarkClasses(
      schoolId: widget.schoolId,
      title: widget.title,
    );

    classes = List<Map<String, dynamic>>.from(
      classes1.map((item) => item['class']),
    );

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSchoolWise() async {
    schoolWiseMark = await AdminApiService.fetchExamMarkSchoolTitle(
      schoolId: widget.schoolId,
      title: widget.title,
    );
    // print(schoolWiseMark);
    //I/flutter (32270): [{id: 177, school_id: 1, class_id: 29, username: 2025003, title: I TERM, min_max_marks: [35, 100], marks: [AA, 66, 79], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank: -1, created_by: 1, created_at: 2026-02-12T07:29:34.492Z, updated_by: 1, updated_at: 2026-02-12T11:55:14.603Z, status: active, date: [2026-02-13, 2026-02-14, 2026-02-14], session: [AN, FN, AN], name: SARAN, class_name: I, section: A}, {id: 178, school_id: 1, class_id: 29, username: 2025008, title: I TERM, min_max_marks: [35, 100], marks: [22, 35, 100], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank: -1, created_by: 1, created_at: 2026-02-12T07:29:35.108Z, updated_by: 1, updated_at: 2026-02-12T11:55:14.603Z, status: active, date: [2026-02-13, 2026-02-14, 2026-02-14], session: [AN, FN, AN], name: RAGU P, class_name: I, section: A}, {id: 179, school_id: 1, class_id: 29, username: 1001, title: I TERM, min_max_marks: [35, 100], marks: [30, 44, 66], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank:
  }

  Future<void> fetchClassWise(String classId) async {
    classWiseMark = await AdminApiService.fetchExamMarkClassTitle(
      schoolId: widget.schoolId,
      title: widget.title,

      classId: classId,
    );
    print(classWiseMark);
    //I/flutter (32270): [{id: 177, school_id: 1, class_id: 29, username: 2025003, title: I TERM, min_max_marks: [35, 100], marks: [AA, 66, 79], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank: -1, created_by: 1, created_at: 2026-02-12T07:29:34.492Z, updated_by: 1, updated_at: 2026-02-12T11:55:14.603Z, status: active, date: [2026-02-13, 2026-02-14, 2026-02-14], session: [AN, FN, AN], name: SARAN, class_name: I, section: A}, {id: 178, school_id: 1, class_id: 29, username: 2025008, title: I TERM, min_max_marks: [35, 100], marks: [22, 35, 100], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank: -1, created_by: 1, created_at: 2026-02-12T07:29:35.108Z, updated_by: 1, updated_at: 2026-02-12T11:55:14.603Z, status: active, date: [2026-02-13, 2026-02-14, 2026-02-14], session: [AN, FN, AN], name: RAGU P, class_name: I, section: A}, {id: 179, school_id: 1, class_id: 29, username: 1001, title: I TERM, min_max_marks: [35, 100], marks: [30, 44, 66], subjects: [TAMIL, ENGLISH, MATHS], subject_rank: [0, 0, 0], rank:
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (e) {
            return;
          }
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> handlePrintSchoolWise() async {
    if (schoolWiseMark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found to print")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPassReportPdf(
                    title: widget.title,
                    examMarks: schoolWiseMark,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                  ),
              title: '${widget.title} Pass Report (School Wise)',
              fileName: '${widget.title.toLowerCase()}_school_pass_report',
            ),
      ),
    );
  }

  Future<void> handlePrintClassWise({
    required String classId,
    required String className,
    required String section,
  }) async {
    setState(() => isLoading = true);
    await fetchClassWise(classId);
    setState(() => isLoading = false);

    if (classWiseMark.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No records found for this class")),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PdfPreviewCustomPage(
                buildPdf:
                    () => buildPassReportPdf(
                      title: widget.title,
                      examMarks: classWiseMark,
                      schoolName: schoolName,
                      schoolAddress: schoolAddress,
                      schoolPhotoBytes: schoolPhotoBytes,
                    ),
                title: '${widget.title} Pass Report ($className - $section)',
                fileName:
                    '${widget.title.toLowerCase()}_${className.toLowerCase()}_${section.toLowerCase()}_pass_report',
              ),
        ),
      );
    }
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
      return null;
    }
    return null;
  }

  int getSortOrder(String className) {
    final upper = className.toUpperCase().trim();
    if (kinderGrades.contains(upper)) return kinderGrades.indexOf(upper);
    final value = parseClassValue(className);
    if (value != null) return value + kinderGrades.length;
    return 999;
  }

  List<Map<String, dynamic>> getSortedClasses() {
    List<Map<String, dynamic>> sortedList = List.from(classes);

    sortedList.sort((a, b) {
      int classComparison = getSortOrder(
        a['class'],
      ).compareTo(getSortOrder(b['class']));
      if (classComparison != 0) return classComparison;

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PassReports(
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
                    title: widget.title,
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: widget.title,
                    onBack: () {
                      onWillPop();
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
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: handlePrintSchoolWise,
                        child: Text('Print School Wise PDF'),
                      ),
                      const SizedBox(height: 16),
                      classes.isEmpty
                          ? const Center(
                            child: Text(
                              "No Classes Found",
                              style: TextStyle(fontSize: 16),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isSmall = MediaQuery.of(context).size.width < 800;
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
            crossAxisCount:
                isMobile
                    ? 3
                    : isSmall
                    ? 5
                    : 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
            children:
                classes.map((classItem) {
                  final className = classItem['class'].toString();
                  final section = classItem['section'].toString();

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!mounted) return;
                      handlePrintClassWise(
                        classId: classItem['id'].toString(),
                        className: className,
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
