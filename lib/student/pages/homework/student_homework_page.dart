import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../Appbar/student_appbar_mobile.dart';
import '../student_dashboard.dart';

class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
  });

  final String username;
  final String schoolId;
  final String classId;

  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage> {
  List<dynamic> homework = [];
  List<dynamic> filteredHomework = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  String filter = "All"; // All, Upcoming, Overdue

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final data = await StudentApiServices.fetchHomeworkByClassId(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
      );
      setState(() {
        homework = data;
        filteredHomework = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching homework: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  bool isOverdue(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final due = DateTime.parse(dateStr);
      return due.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  void applyFilter(String selected) {
    setState(() {
      filter = selected;
      if (filter == "Upcoming") {
        filteredHomework =
            homework.where((item) => !isOverdue(item['due_date'])).toList();
      } else if (filter == "Overdue") {
        filteredHomework =
            homework.where((item) => isOverdue(item['due_date'])).toList();
      } else {
        filteredHomework = homework;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'View Homework',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 2;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : AppBar(
                  title: const Text("View Homework"),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: applyFilter,
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: "All",
                              child: Text("All"),
                            ),
                            const PopupMenuItem(
                              value: "Upcoming",
                              child: Text("Upcoming"),
                            ),
                            const PopupMenuItem(
                              value: "Overdue",
                              child: Text("Overdue"),
                            ),
                          ],
                    ),
                  ],
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
              : filteredHomework.isEmpty
              ? const Center(
                child: Text(
                  "🎉 No homework available",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredHomework.length,
                itemBuilder: (context, index) {
                  final item = filteredHomework[index];
                  final overdue = isOverdue(item['due_date']);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          overdue
                              ? const BorderSide(color: Colors.red, width: 1.5)
                              : BorderSide.none,
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Subject
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item['subject'] ?? "Unknown",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['description'] ?? "No description",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Assigned Date
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Assigned: ${formatDate(item['assigned_date'])}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Due Date
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Due: ${formatDate(item['due_date'])}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: overdue ? Colors.red : Colors.black87,
                                  fontWeight: overdue ? FontWeight.bold : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Teacher
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Teacher: ${item['assigned_by'] ?? "Unknown"}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            applyFilter("All");
          } else if (index == 1) {
            applyFilter("Upcoming");
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Upcoming',
          ),
        ],
      ),
    );
  }
}
