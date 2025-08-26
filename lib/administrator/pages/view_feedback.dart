import 'package:flutter/material.dart';

class ViewFeedback extends StatefulWidget {
  const ViewFeedback({super.key});

  @override
  State<ViewFeedback> createState() => _ViewFeedbackState();
}

class _ViewFeedbackState extends State<ViewFeedback> {
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {}
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
