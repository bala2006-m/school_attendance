import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/appbar/admin_appbar_desktop.dart';
import 'package:school_attendance/admin/appbar/admin_appbar_mobile.dart';

import '../../../student/services/student_api_services.dart';
import '../../../teacher/services/teacher_api_service.dart';
import '../../services/admin_api_service.dart';
import 'timetable_class_list.dart';

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final capitalized =
        text[0].toUpperCase() + (text.length > 1 ? text.substring(1) : '');

    return newValue.copyWith(
      text: capitalized,
      selection: TextSelection.collapsed(offset: capitalized.length),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.className,
    required this.section,
  });
  final String schoolId;
  final String username;
  final String classId;
  final String className;
  final String section;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool isLoading = true;
  String? error;
  bool hasChanges = false;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Map<String, List<Map<String, dynamic>>> timetableEntries = {};
  final Map<String, List<TextEditingController>> timetableControllers = {};
  final Map<String, int> periodCountPerDay = {};

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    try {
      final classId = widget.classId;
      var response = await StudentApiServices.fetchTimetableAdmin(
        schoolId: widget.schoolId,
        classId: classId,
      );

      final timetableData = response['timetable'] ?? {};

      setState(() {
        for (var day in days) {
          final shortDay = day.substring(0, 3);
          final List dayEntriesRaw = timetableData[shortDay] ?? [];

          timetableEntries[day] = List<Map<String, dynamic>>.from(
            dayEntriesRaw,
          );

          timetableControllers[day] =
              dayEntriesRaw.isNotEmpty
                  ? dayEntriesRaw
                      .map(
                        (e) => TextEditingController(text: e['subject'] ?? ''),
                      )
                      .toList()
                  : [TextEditingController()];

          // Add listener for change detection
          for (var ctl in timetableControllers[day]!) {
            ctl.addListener(() {
              if (!hasChanges) {
                setState(() {
                  hasChanges = true;
                });
              }
            });
          }

          periodCountPerDay[day] = timetableControllers[day]!.length.clamp(
            1,
            8,
          );
        }
        isLoading = false;
        error = null;
        hasChanges = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _confirmAndSave() {
    if (!hasChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No changes to save")));
      return;
    }
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Save"),
            content: const Text("Are you sure you want to save the timetable?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveTimetable();
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _saveTimetable() async {
    final int classId = int.parse(widget.classId);
    final int? schoolId = int.tryParse(widget.schoolId);

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid class or school ID")),
      );
      return;
    }

    List<Map<String, dynamic>> timetablePayload = [];

    for (var day in days) {
      final shortDay = day.substring(0, 3);
      final controllers = timetableControllers[day]!;

      for (int i = 0; i < controllers.length; i++) {
        final rawSubject = controllers[i].text.trim();
        if (rawSubject.isEmpty) continue;

        final subject = rawSubject[0].toUpperCase() + rawSubject.substring(1);

        timetablePayload.add({
          "schoolId": schoolId,
          "classId": classId,
          "dayOfWeek": shortDay,
          "periodNumber": i + 1,
          "subject": subject,
        });
      }
    }

    if (timetablePayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No timetable data to save")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await TeacherApiServices.saveTimetable(timetablePayload);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Timetable saved successfully")),
        );
      }
      await loadTimetable();
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save timetable")),
        );
      }
    }
  }

  Future<bool> _confirmDeletePeriod() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this period?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Time Table',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TimetableClassList(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : AdminAppbarDesktop(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Time Table',

                  onBack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TimetableClassList(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                ),
      ),
      body:
          isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Error: $error",
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        loadTimetable();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Column(
                      children:
                          days.map((day) {
                            final controllers = timetableControllers[day]!;
                            final entries = timetableEntries[day]!;

                            return Card(
                              elevation: 6,
                              shadowColor: Colors.blueAccent.withValues(
                                alpha: 0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueAccent.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...List.generate(
                                      controllers.length,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: controllers[index],
                                                inputFormatters: [
                                                  CapitalizeFirstLetterFormatter(),
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'[a-zA-Z\s]'),
                                                  ),
                                                ],
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Period ${index + 1}',
                                                  hintText:
                                                      'Enter subject name',
                                                  prefixIcon: const Icon(
                                                    Icons.book,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.blueAccent,
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                  filled: true,
                                                  fillColor: Colors.blueAccent
                                                      .withValues(alpha: 0.05),
                                                ),
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Tooltip(
                                              message: 'Delete this period',
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  if (controllers.length > 1) {
                                                    final confirmed =
                                                        await _confirmDeletePeriod();
                                                    if (!confirmed) return;

                                                    final idToDelete =
                                                        entries[index]['id']
                                                            ?.toString();

                                                    bool success = true;
                                                    if (idToDelete != null) {
                                                      success =
                                                          await AdminApiService.deleteTimetableEntry(
                                                            idToDelete,
                                                          );
                                                    }
                                                    if (success) {
                                                      setState(() {
                                                        entries.removeAt(index);
                                                        controllers[index]
                                                            .dispose();
                                                        controllers.removeAt(
                                                          index,
                                                        );
                                                        periodCountPerDay[day] =
                                                            controllers.length;
                                                        hasChanges = true;
                                                      });
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Timetable period deleted successfully',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Failed to delete timetable period',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "At least one period is required.",
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (controllers.length < 8)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.add),
                                          label: const Text("Add Period"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              timetableControllers[day]!.add(
                                                TextEditingController(),
                                              );
                                              timetableEntries[day]!.add({
                                                'id': null,
                                                'period':
                                                    controllers.length + 1,
                                                'subject': '',
                                                'session': '',
                                              });
                                              periodCountPerDay[day] =
                                                  controllers.length + 1;
                                              hasChanges = true;
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (isLoading || !hasChanges) ? null : _confirmAndSave,
        label: Text(
          "Save Timetable",
          style: TextStyle(
            color: (isLoading || !hasChanges) ? Colors.black : Colors.white,
          ),
        ),
        icon: Icon(
          Icons.save,
          color: (isLoading || !hasChanges) ? Colors.black : Colors.white,
        ),
        backgroundColor:
            (isLoading || !hasChanges) ? Colors.grey : Colors.blueAccent,
      ),
    );
  }
}
