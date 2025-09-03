import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../pages/studentAttendance/markAttendance/attendance_screen.dart';

class MobileClassList extends StatefulWidget {
  const MobileClassList({
    super.key,
    required this.isLoading,
    required this.classList,
    required this.schoolId,
    required this.username,
    required this.attendanceStatusMapFN,
    required this.attendanceStatusMapAN,
  });

  final bool isLoading;
  final List<dynamic> classList;
  final String schoolId;
  final String username;
  final Map<String, bool> attendanceStatusMapFN;
  final Map<String, bool> attendanceStatusMapAN;

  @override
  State<MobileClassList> createState() => _MobileClassListState();
}

class _MobileClassListState extends State<MobileClassList> {
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
    return widget.classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value == null; // Nursery, LKG, UKG, PRE-KG etc.
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClasses(int min, int max) {
    return widget.classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min && value <= max;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> filterClassesFrom(int min) {
    return widget.classList
        .where((item) {
          final value = parseClassValue(item['class']);
          return value != null && value >= min;
        })
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLoading
        ? const Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        )
        : widget.classList.isEmpty
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
                              (_) => AttendanceScreen(
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Split into FN + AN halves
                          Row(
                            children: [
                              // FN Half
                              Expanded(
                                child: Container(
                                  height: 50, // half height bar
                                  decoration: BoxDecoration(
                                    color:
                                        (widget.attendanceStatusMapFN[classId] ??
                                                false)
                                            ? Colors.teal
                                            : Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'FN',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),

                              // AN Half
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        (widget.attendanceStatusMapAN[classId] ??
                                                false)
                                            ? Colors.teal
                                            : Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'AN',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Class + Section Info
                          Column(
                            children: [
                              Text(
                                isKinderGarden ? className : 'Class $className',

                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Sec $section',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
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
