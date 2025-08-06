import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../pages/attendance_screen.dart';

class DesktopClassList extends StatelessWidget {
  const DesktopClassList({
    super.key,
    required this.isLoading,
    required this.classList,
    required this.schoolId,
  });
  final bool isLoading;
  final List<dynamic> classList;
  final String schoolId;
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        )
        : classList.isEmpty
        ? Center(
          child: Text(
            'No classes found.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        )
        : Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: classList.length,
                itemBuilder: (context, index) {
                  final classItem = classList[index];
                  final className = classItem['class'] ?? 'Unnamed Class';
                  final section = classItem['section'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      // Added InkWell for better tap feedback
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Match card's border radius
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AttendanceScreen(
                                  schoolId: schoolId,
                                  classId: '${classItem['id']}',
                                  className: className,
                                  section: section,
                                ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.class_outlined,
                          color: Colors.blueAccent,
                          size: 30,
                        ),
                        title: Text(
                          'Class: $className',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Section: $section',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
  }
}
