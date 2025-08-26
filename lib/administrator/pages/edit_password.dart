import 'package:flutter/material.dart';

class EditPassword extends StatefulWidget {
  const EditPassword({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final int schoolId;

  @override
  State<EditPassword> createState() => _EditPasswordState();
}

class _EditPasswordState extends State<EditPassword> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
