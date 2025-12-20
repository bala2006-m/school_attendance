import 'package:flutter/material.dart';

class AttendanceList extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> attendance;
  final String session;
  final TextEditingController maxMarkController;
  final Function() onCalculateRanks;
  final Map<String, TextEditingController> markControllers;
  final Map<String, int> subjectRanks;

  const AttendanceList({
    super.key,
    required this.students,
    required this.attendance,
    required this.session,
    required this.maxMarkController,
    required this.onCalculateRanks,
    required this.markControllers,
    required this.subjectRanks,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics:
          const NeverScrollableScrollPhysics(), // To prevent scrolling inside scroll views
      shrinkWrap: true,
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final username = student['username'].toString();
        final name = student['name'] ?? 'Unnamed';
        final gender = student['gender'] ?? 'M';

        final att = attendance.firstWhere(
          (elem) => elem['username'].toString() == username,
          orElse: () => {},
        );
        bool attendanceExists = att.isNotEmpty;
        String? status;
        if (attendanceExists) {
          status =
              session == "FN"
                  ? (att['fn_status']?.toString() ?? '')
                  : (att['an_status']?.toString() ?? '');
          if (status == '') status = null;
        } else {
          status = null;
        }
        bool isAbsent = status == 'A';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
          color: gender == 'F' ? Colors.pink[50] : Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: name,
                        child: Text(
                          name.length > 13
                              ? '${name.substring(0, 13)}...'
                              : name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color:
                                gender == 'M'
                                    ? Colors.blue[900]
                                    : Colors.pink[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (attendanceExists && status != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: isAbsent ? Colors.red : Colors.green,
                    ),
                  ),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: markControllers[username],
                    keyboardType: TextInputType.text, // allow "AA" input
                    decoration: const InputDecoration(
                      labelText: 'Mark',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    enabled:
                        true, // always allow input, even for absent, we'll handle validation
                    onChanged: (val) {
                      final maxMark =
                          int.tryParse(maxMarkController.text.trim()) ?? 100;
                      if (val.isEmpty) {
                        onCalculateRanks();
                        return;
                      }

                      final upperVal = val.toUpperCase();
                      if (upperVal == 'AA') {
                        // mark as absent
                        subjectRanks[username] =
                            -1; // optional: set special rank
                        onCalculateRanks();
                        return;
                      }

                      final intVal = int.tryParse(val);
                      if (intVal == null || intVal < 0 || intVal > maxMark) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Marks must be between 0 and $maxMark or "AA".',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        onCalculateRanks();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(
                    (subjectRanks[username] == null ||
                            subjectRanks[username] == -1)
                        ? '-'
                        : subjectRanks[username].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
