import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
  });
  final String username;
  final String schoolId;
  final String classId;
  final String className;
  final String section;
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
