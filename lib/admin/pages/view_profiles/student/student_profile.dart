import 'package:flutter/material.dart';
class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key, required this.schoolId, required this.classId, required this.username});
final String schoolId;
final String classId;
final String username;
  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
