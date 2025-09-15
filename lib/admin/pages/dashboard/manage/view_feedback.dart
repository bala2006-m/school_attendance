import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../admin_dashboard.dart';

class ViewFeedback extends StatefulWidget {
  final String schoolId;
  final String username;

  const ViewFeedback({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ViewFeedback> createState() => _ViewFeedbackState();
}

class _ViewFeedbackState extends State<ViewFeedback> {
  List<Map<String, dynamic>> feedbacks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      feedbacks = await AdminApiService.fetchFeedback(widget.schoolId);
      //    print('Feedbacks: $feedbacks');

      final updatedFeedbacks = await Future.wait(
        feedbacks.map((feedback) async {
          final classData = await AdminApiService.fetchClassInfo(
            classId: feedback['class_id'],
            schoolId: feedback['school_id'],
          );

          // Add class and section fields to the feedback map
          return {
            ...feedback, // Keep existing feedback fields
            'class': classData['class'], // Add class number
            'section': classData['section'], // Add section
          };
        }),
      );

      feedbacks = updatedFeedbacks; // Replace feedbacks with enriched data

      // print('Enriched Feedbacks: $feedbacks');
    } catch (e) {
      // print('Error during init: $e');
      // print(stacktrace);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFeedbackCard(Map<String, dynamic> feedback) {
    final username = (feedback['username'] ?? '').toString().trim();
    final name = (feedback['name'] ?? '').toString().trim();
    // final email = (feedback['email'] ?? '').toString().trim();
    final message = feedback['feedback'] ?? 'No feedback provided';
    final createdAt = feedback['created_at'];
    final className = (feedback['class'] ?? '').toString().trim();
    final section = (feedback['section'] ?? '').toString().trim();

    final formattedDateTime =
        createdAt != null
            ? DateFormat(
              'MMM d, yyyy', // • hh:mm a',
            ).format(DateTime.parse(createdAt))
            : 'Unknown time';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '👤',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Feedback details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and timestamp
                  Text(
                    username.isNotEmpty ? username : 'Anonymous',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Anonymous',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formattedDateTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Class: $className',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Section: $section',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(message, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Feedback',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Feedback',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  ),
        ),
        body:
            isLoading
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : feedbacks.isEmpty
                ? const Center(child: Text('No feedbacks available.'))
                : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    return buildFeedbackCard(feedbacks[index]);
                  },
                ),
      ),
    );
  }
}
