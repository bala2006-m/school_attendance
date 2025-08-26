import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_desktop.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_mobile.dart';

import 'first_page.dart';

class ViewFeedback extends StatefulWidget {
  const ViewFeedback({
    super.key,
    required this.schoolId,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
  });
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;
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
    } catch (e) {
      // Optional: Handle fetch error
      print("Error fetching feedbacks: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFeedbackCard(Map<String, dynamic> feedback) {
    final name = (feedback['name'] ?? '').toString().trim();
    final email = (feedback['email'] ?? '').toString().trim();
    final message = feedback['feedback'] ?? 'No feedback provided';
    final createdAt = feedback['created_at'];
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
                  if (email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        email,
                        style: const TextStyle(color: Colors.grey),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return WillPopScope(
      onWillPop: () async {
        FirstPageState.selectedIndex = 1;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FirstPage(
                  username: widget.username,
                  schoolName: widget.schoolName,
                  schoolAddress: widget.schoolAddress,
                  schoolId: widget.schoolId,
                ),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdministratorAppbarMobile(
                    title: 'View Feedback',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      FirstPageState.selectedIndex = 1;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FirstPage(
                                username: widget.username,
                                schoolName: widget.schoolName,
                                schoolAddress: widget.schoolAddress,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdministratorAppbarDesktop(title: 'View Feedback'),
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
