import 'package:flutter/material.dart';

import '../../colors/colors.dart';
import './admin_dashboard.dart';

class MarkingStatus extends StatefulWidget {
  final String schoolId;
  final String username;
  const MarkingStatus({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<MarkingStatus> createState() => _MarkingStatusState();
}

class _MarkingStatusState extends State<MarkingStatus> {
  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Marking Status'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: AppColors.appbarColor),
          ),
        ),
        body: Center(child: Column(children: [Text('Marking Status')])),
      ),
    );
  }
}
