import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
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
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d-MM-yy').format(date);
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
    // final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(190),
        child: StudentAppbarMobile(
          schoolId: int.parse(widget.schoolId),
          username: widget.username,
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

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => HomeworkDetailsPage(homework: item),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shadowColor: Colors.blue.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side:
                            overdue
                                ? const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.8,
                                )
                                : BorderSide.none,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.blue.shade50.withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Title + Subject Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade200,
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    item['subject'] ?? "Unknown",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300, thickness: 1),

                            // 🔹 Description
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['description'] ??
                                        "No description provided.",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300, thickness: 1),

                            // 🔹 Info Section
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Teacher Info
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Teacher:\n${item['assigned_by'].toString().toUpperCase()}',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Dates
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Issued: ${formatDate(item['assigned_date'])}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // ✅ Due Date — Highlighted
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.alarm,
                                            size: 18,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Due: ${formatDate(item['due_date'])}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  overdue
                                                      ? Colors.redAccent
                                                      : Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),
                          ],
                        ),
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

class HomeworkDetailsPage extends StatefulWidget {
  final dynamic homework;

  const HomeworkDetailsPage({super.key, required this.homework});

  @override
  State<HomeworkDetailsPage> createState() => _HomeworkDetailsPageState();
}

class _HomeworkDetailsPageState extends State<HomeworkDetailsPage> {
  String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    final date = DateTime.parse(dateStr);
    return '${date.day}-${date.month}-${date.year}';
  }

  @override
  void initState() {
    super.initState();
    // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void dispose() {
    // FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homework['title'] ?? 'Homework Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2B7CA8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.homework['subject'] ?? 'Subject',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.homework['description'] ??
                            'No description provided.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Teacher: ${widget.homework['assigned_by'] ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Issued: ${formatDate(widget.homework['assigned_date'])}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.alarm, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${formatDate(widget.homework['due_date'])}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.homework['attachments'] != null &&
                  widget.homework['attachments'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: widget.homework['attachments'].length,
                      itemBuilder: (context, index) {
                        final attachment =
                            widget.homework['attachments'][index];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => Dialog(
                                    insetPadding: EdgeInsets.zero,
                                    backgroundColor: Colors.black,
                                    child: PhotoView(
                                      imageProvider: NetworkImage(attachment),
                                      backgroundDecoration: const BoxDecoration(
                                        color: Colors.black,
                                      ),
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 3,
                                    ),
                                  ),
                            );
                          },
                          child: Image.network(
                            attachment,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Text('Image failed to load'),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget _buildDueDate(String? dateStr, bool isOverdue) {
//   return Row(
//     children: [
//       Icon(
//         Icons.access_time,
//         size: 18,
//         color: isOverdue ? Colors.red.shade700 : Colors.black54,
//       ),
//       const SizedBox(width: 8),
//       Text(
//         "Due: ${formatDate(dateStr)}",
//         style: TextStyle(
//           fontSize: 14,
//           color: isOverdue ? Colors.red.shade700 : Colors.black87,
//           fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     ],
//   );
// }
