import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../appbar/mobile_appbar.dart';
import '../../services/teacher_api_service.dart';
import '../staff_dashboard.dart';
import 'homework_page.dart';

class HomeworkClassList extends StatefulWidget {
  const HomeworkClassList({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<HomeworkClassList> createState() => _HomeworkClassListState();
}

class _HomeworkClassListState extends State<HomeworkClassList> {
  List<dynamic> classList = [];
  bool isLoading = true;
  late Timer refreshTimer;
  @override
  void initState() {
    super.initState();

    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchClasses();
    });
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
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
        classList = filteredList;
        isLoading = false;
      });
    }
    // classes = List.from(cls);
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
    return classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value == null; // Nursery, LKG, UKG, PRE-KG etc.
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    return classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min && value <= max;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    return classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

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
            StaffDashboardState.selectedIndex = 2;
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                              (_) => HomeworkPage(
                                schoolId: widget.schoolId,
                                classId: classId,
                                className: className,
                                section: section,
                                username: widget.username,
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
                          Column(
                            children: [
                              Text(
                                isKinderGarden ? className : 'Class $className',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sec $section',
                                style: TextStyle(
                                  fontSize: 16,
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
