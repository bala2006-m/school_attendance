import 'package:flutter/material.dart';
import 'package:school_attendance/admin/pages/exam_marks/update_exam_marks.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import 'exam_mark_classes.dart';

class ExamMarks extends StatefulWidget {
  const ExamMarks({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
    required this.className,
    required this.section,
  });

  final String schoolId;
  final String classId;
  final String username;
  final String className;
  final String section;

  @override
  State<ExamMarks> createState() => _ExamMarksState();
}

class _ExamMarksState extends State<ExamMarks> {
  bool isLoading = true;
  List<dynamic> examMarks = [];
  @override
  void initState() {
    super.initState();
    fetchExamMarks();
  }

  Future<void> fetchExamMarks() async {
    examMarks = await AdminApiService.fetchExamMarkClassTitles(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> onWillPop() async {
    // If no form is showing, navigate back to ExamMarkClasses
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamMarkClasses(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false; // prevent default pop
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child:
                isMobile
                    ? AdminAppbarMobile(
                      schoolId: widget.schoolId,
                      username: widget.username,
                      title: 'Exam Marks',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: onWillPop,
                    )
                    : AdminAppbarDesktop(
                      schoolId: widget.schoolId,
                      username: widget.username,
                      title: 'Exam Marks',
                      onBack: onWillPop,
                    ),
          ),
        ),
        body:
            isLoading
                ? Stack(
                  children: [
                    Opacity(
                      opacity: 0.3,
                      child: const ModalBarrier(
                        dismissible: false,
                        color: Colors.black,
                      ),
                    ),
                    Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Class & Section Info with Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.class_, color: Colors.cyan[700]),
                                SizedBox(width: 8),
                                Text(
                                  'Class: ${widget.className} • Section: ${widget.section}',
                                  style: TextStyle(
                                    color: Colors.cyan[700],
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Exam Mark Buttons with icons and gradient
                        for (var mark in examMarks)
                          Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.edit, color: Colors.white),
                              label: Text(
                                mark['title'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UpdateExamMarks(
                                          username: widget.username,
                                          classId: widget.classId,
                                          schoolId: widget.schoolId,
                                          title: mark['title'],
                                          className: widget.className,
                                          section: widget.section,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
