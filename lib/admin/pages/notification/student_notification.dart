import 'package:flutter/material.dart';

import '../../../student/services/student_api_services.dart';
import 'notifications.dart';

class StudentNotification extends StatefulWidget {
  const StudentNotification({
    super.key,
    required this.leaveRequests,
    required this.feedbacks,
  });
  final List<dynamic> leaveRequests;
  final List<dynamic> feedbacks;

  @override
  State<StudentNotification> createState() => _StudentNotificationState();
}

class _StudentNotificationState extends State<StudentNotification> {
  List<dynamic> studentLeaveRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final filteredRequests =
        widget.leaveRequests
            .where((leave) => leave['role'] == 'student')
            .toList();

    for (int i = 0; i < filteredRequests.length; i++) {
      final studentData = await StudentApiServices.fetchStudentDataUsername(
        username: filteredRequests[i]['username'],
        schoolId: filteredRequests[i]['school_id'],
      );

      if (studentData != null) {
        filteredRequests[i]['name'] = studentData['name'];
      }
    }

    setState(() {
      studentLeaveRequests = filteredRequests;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Leave Requests",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (studentLeaveRequests.isNotEmpty)
            ...studentLeaveRequests.map(
              (leave) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    "Name : ${leave['name']}\nUsername : ${leave['username']}",
                  ),
                  subtitle: Text(
                    "Reason: ${leave['reason']}\nFrom: ${NotificationsState.formatDate(
                      leave['from_date'],
                      format: 'MMM d, yyyy', //• hh:mm a',
                    )} To: ${NotificationsState.formatDate(
                      leave['to_date'],
                      format: 'MMM d, yyyy', //• hh:mm a',
                    )}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((leave['status'] ?? 'pending')
                              .toString()
                              .toLowerCase() ==
                          'pending') ...[
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed:
                              () => NotificationsState.updateLeaveStatus(
                                'approved',
                                leave['id'],
                                context,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed:
                              () => NotificationsState.updateLeaveStatus(
                                'rejected',
                                leave['id'],
                                context,
                              ),
                        ),
                      ] else
                        GestureDetector(
                          onTap:
                              () => NotificationsState.markLeaveSeen(
                                leave['id'],
                              ), // ✅ tap marks seen
                          child: Text(
                            leave['status'].toString().toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  leave['status'] == "approved"
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.feedbacks.isNotEmpty) const Divider(),
          if (widget.feedbacks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "Feedbacks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ...widget.feedbacks.map(
            (fb) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fb['username'] ?? "Unknown"),
                    Text(fb['name'] ?? "Unknown"),
                    Divider(),
                  ],
                ),
                subtitle: Text(fb['feedback']),
                trailing: Text(fb['created_at'].toString().split("T")[0]),
                onTap: () => NotificationsState.markFeedbackSeen(fb['id']),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
