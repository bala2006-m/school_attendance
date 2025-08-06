import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../appbar/mobile_appbar.dart';
import '../color/teacher_custom_color.dart';
import '../widget/desktop_class_list.dart';
import '../widget/mobile_class_list.dart';

class ClassList extends StatefulWidget {
  final String schoolId;
  const ClassList({super.key, required this.schoolId});

  @override
  State<ClassList> createState() => _ClassListState();
}

class _ClassListState extends State<ClassList> {
  List<dynamic> classList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final fetchedClassList = await TeacherApiServices.fetchClassData(
      widget.schoolId,
    );
    setState(() {
      classList = fetchedClassList ?? [];

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopAppbar(title: 'Class List')
              : MobileAppbar(title: 'Class List'),
      backgroundColor: bdMid,
      body:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopClassList(
                classList: classList,
                schoolId: widget.schoolId,
                isLoading: isLoading,
              )
              : MobileClassList(
                classList: classList,
                schoolId: widget.schoolId,
                isLoading: isLoading,
              ),
    );
  }
}
