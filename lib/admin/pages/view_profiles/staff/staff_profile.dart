import 'package:flutter/material.dart';

class StaffProfile extends StatefulWidget {
  const StaffProfile({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<StaffProfile> createState() => _StaffProfileState();
}

class _StaffProfileState extends State<StaffProfile> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
