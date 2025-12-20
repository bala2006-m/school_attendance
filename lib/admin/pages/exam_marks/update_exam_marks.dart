import 'package:flutter/material.dart';

import '../../../admin/services/admin_api_service.dart';
import '../../appbar/desktop_appbar.dart';
import '../../appbar/mobile_appbar.dart';
import 'exam_marks_classes.dart';

class UpdateExamMarks extends StatefulWidget {
  const UpdateExamMarks({
    super.key,
    required this.username,
    required this.classId,
    required this.schoolId,
    required this.title,
  });
  final String username;
  final String classId;
  final String schoolId;
  final String title;
  @override
  State<UpdateExamMarks> createState() => _UpdateExamMarksState();
}

class _UpdateExamMarksState extends State<UpdateExamMarks> {
  List<dynamic> examMarks = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchExamMarks();
  }

  Future<void> fetchExamMarks() async {
    examMarks = await AdminApiService.fetchExamMarkClassTitle(
      schoolId: widget.schoolId,
      classId: widget.classId,
      title: widget.title,
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? MobileAppbar(
                  title: widget.title,
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ExamMarksClasses(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : DesktopAppbar(title: widget.title),
      ),
    );
  }
}
