import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_desktop.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_mobile.dart';

import '../services/administrator_api_service.dart';
import 'first_page.dart';

class ViewTicket extends StatefulWidget {
  const ViewTicket({
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
  State<ViewTicket> createState() => _ViewTicketState();
}

class _ViewTicketState extends State<ViewTicket> {
  List<Map<String, dynamic>> feedbacks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final allTickets = await AdministratorApiService.fetchTicket(
        widget.schoolId,
      );

      feedbacks =
          allTickets
              .where(
                (ticket) =>
                    ticket['school_id'].toString() == widget.schoolId &&
                    (ticket['status']?.toString().toLowerCase() == 'pending'),
              )
              .toList();

      // ✅ Sort by modified_at (latest first)
      feedbacks.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['modified_at'] ?? '') ?? DateTime(1970);
        final bDate =
            DateTime.tryParse(b['modified_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      print("Filtered + sorted tickets: $feedbacks");
    } catch (e) {
      print("Error fetching tickets: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFeedbackCard(Map<String, dynamic> feedback) {
    final name1 = (feedback['name'] ?? '').toString().trim();
    final name = name1.length > 15 ? '${name1.substring(0, 15)}...' : name1;
    final email = (feedback['email'] ?? '').toString().trim();
    final message = feedback['tickets'] ?? 'No ticket provided';
    final createdAt = feedback['created_at'];
    final modifiedAt = feedback['modified_at'];
    final status = feedback['status'] ?? 'Unknown';

    final formattedCreatedAt =
        createdAt != null
            ? DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt))
            : 'Unknown created date';

    final formattedModifiedAt =
        modifiedAt != null
            ? DateFormat('MMM d, yyyy').format(DateTime.parse(modifiedAt))
            : 'Unknown modified date';

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
                  // Name + Created Date
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
                        formattedCreatedAt,
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

                  const SizedBox(height: 12),

                  // ✅ Status Button + Modified At
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              status == "Pending"
                                  ? Colors.orange
                                  : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          // Future: Add update status API call here
                        },
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        "Modified: $formattedModifiedAt",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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
                    title: 'View Ticket',
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
                  : const AdministratorAppbarDesktop(title: 'View Ticket'),
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
