import 'package:flutter/material.dart';

import '../components/build_profile_card_mobile.dart';
import '../components/message_box.dart';
import '../pages/timetable_page.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
    this.schoolPhoto,
    required this.schoolName,
    required this.schoolAddress,
    required this.message,
    required this.timetable,
  });

  final String schoolId;
  final String classId;
  final String username;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final String message;
  final List<String> timetable;

  Widget _buildPeriodTile(String subject) {
    if (subject.toLowerCase() == 'break' || subject.toLowerCase() == 'lunch') {
      final isBreak = subject.toLowerCase() == 'break';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isBreak ? Colors.blue.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subject[0].toUpperCase() + subject.substring(1).toLowerCase(),
              style: TextStyle(
                color: isBreak ? Colors.blue : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.book, color: Colors.black54),
        title: Text(
          subject,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int weekday = DateTime.now().weekday;

    List<String> weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    String day =
        (weekday >= 1 && weekday <= 7)
            ? weekdayNames[weekday - 1]
            : 'Unknown Day';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0F4FF), Color(0xFFE5ECFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: BuildProfileCard(
                schoolAddress: schoolAddress,
                schoolName: schoolName,
              ),
            ),

            const SizedBox(height: 12),

            // Message Box
            MessageBox(message: message),

            const SizedBox(height: 20),

            // Section: Timetable Heading
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Today's Timetable",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timetable Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Day Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 28,
                                color: Colors.deepPurple.shade700,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.deepPurple.shade300,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => TimeTablePage(
                                        schoolId: schoolId,
                                        classId: classId,
                                        username: username,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Timetable List
                      ...(timetable.isNotEmpty
                          ? timetable.map(_buildPeriodTile).toList()
                          : [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
                                child: Text(
                                  "No classes scheduled for today.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // View Full Timetable Button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TimeTablePage(
                            schoolId: schoolId,
                            classId: classId,
                            username: username,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text("View Full Timetable"),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
