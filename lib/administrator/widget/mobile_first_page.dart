import 'package:flutter/material.dart';

import './home_page.dart';

class MobileFirstPage extends StatelessWidget {
  const MobileFirstPage({
    super.key,
    required this.selectedIndex,
    required this.classes,
    required this.staffs,
    required this.students,
    required this.admins,
  });
  final int selectedIndex;
  final List<dynamic> classes;
  final List<dynamic> staffs;
  final List<dynamic> students;
  final List<dynamic> admins;
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        // AdminStudent(
        //   school_id: widget.schoolId,
        //   adminUsername: widget.username,
        //   adminName: widget.adminName,
        //   adminDesignation: widget.adminDesignation,
        //   adminPhoto: widget.adminPhoto,
        //   schoolName: widget.schoolName,
        //   schoolAddress: widget.schoolAddress,
        // ),
        HomePage(
          classes: classes,
          admins: admins,
          staffs: staffs,
          students: students,
        ),
        // AdminManagement(
        //   adminUsername: widget.username,
        //   schoolId: widget.schoolId,
        //   schoolName: widget.schoolName,
        //   schoolAddress: widget.schoolAddress,
        // ),
      ],
    );
  }
}
