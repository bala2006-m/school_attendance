import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/periodically_attendance_report.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/student_certificates.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';

class PrintStudentCertificates extends StatefulWidget {
  const PrintStudentCertificates({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<PrintStudentCertificates> createState() =>
      _PrintStudentCertificatesState();
}

class _PrintStudentCertificatesState extends State<PrintStudentCertificates> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    fetchClasses();
    super.initState();
  }

  Future<void> fetchClasses() async {
    classes = await AdminApiService.fetchAllClasses(widget.schoolId);
    // print(classes);
    setState(() {
      isLoading = false;
    });
    if (classes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No Classes Found")));
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PeriodicallyAttendanceReport(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  /// Keep order of classes as given by API
  List<String> sortedClassKeys(
    Map<String, List<Map<String, dynamic>>> grouped,
  ) {
    List<String> keys = grouped.keys.toList();

    List<String> orderedKeys =
        classes
            .map((c) => "${c['class']} - ${c['section']}")
            .where((k) => keys.contains(k))
            .toList();

    return orderedKeys;
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
                    title: 'Periodical Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PeriodicallyAttendanceReport(
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
                    title: 'Periodical Report',

                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PeriodicallyAttendanceReport(
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
                : classes.isEmpty
                ? const Center(
                  child: Text(
                    "No Classes Found",
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                              (_) => StudentCertificates(
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
