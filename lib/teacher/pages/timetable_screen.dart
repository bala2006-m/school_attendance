import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../student/services/student_api_services.dart';
import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../services/teacher_api_service.dart';

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
  const TimetableScreen({super.key, required this.schoolId});
  final String schoolId;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Map<String, dynamic>> classList = [];
  Map<String, dynamic>? selectedClass;
  bool isLoading = true;
  String? error;
  Map<String, List<String>> originalTimetable = {};

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  final Map<String, List<TextEditingController>> timetableControllers = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final fetchedClassList = await TeacherApiServices.fetchClassData(
      widget.schoolId,
    );
    setState(() {
      classList = fetchedClassList ?? [];
      isLoading = false;
    });
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var day in days) {
      timetableControllers[day] = List.generate(
        8,
        (_) => TextEditingController(),
      );
    }
  }

  void _clearTimetableInputs() {
    for (var controllers in timetableControllers.values) {
      for (var controller in controllers) {
        controller.clear();
      }
    }
  }

  String _normalizeDay(String shortDay) {
    switch (shortDay.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      default:
        return shortDay;
    }
  }

  Future<void> loadTimetable() async {
    try {
      final classId = selectedClass!['id'];
      var response = await StudentApiServices.fetchTimetable(
        schoolId: widget.schoolId,
        classId: '$classId',
      );

      final Map<String, dynamic>? rawTimetable =
          response as Map<String, dynamic>?;

      if (rawTimetable != null) {
        for (var entry in rawTimetable.entries) {
          final fullDay = _normalizeDay(entry.key);
          final subjects = entry.value as List<dynamic>;
          final controllers = timetableControllers[fullDay];

          if (controllers != null) {
            for (var controller in controllers) {
              controller.clear();
            }
            for (
              int i = 0;
              i < subjects.length && i < controllers.length;
              i++
            ) {
              controllers[i].text = subjects[i]?.toString() ?? '';
            }
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _confirmAndSave() {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a class before saving")),
      );
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
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a class before saving")),
      );
      return;
    }

    final int? classId = selectedClass?['id'];
    final int? schoolId = int.tryParse(widget.schoolId);

    if (classId == null || schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid class or school ID")),
      );
      return;
    }

    List<Map<String, dynamic>> timetablePayload = [];

    for (var day in days) {
      final shortDay = day.substring(0, 3); // "Mon", "Tue", etc.
      final periodControllers = timetableControllers[day]!;

      for (int i = 0; i < periodControllers.length; i++) {
        final rawSubject = periodControllers[i].text.trim();
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

    final success = await TeacherApiServices.saveTimetable(timetablePayload);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timetable saved successfully")),
      );
      await loadTimetable();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save timetable")));
    }
  }

  @override
  void dispose() {
    for (var controllers in timetableControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Widget _buildPeriodInputsRow(String day) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(8, (index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: TextField(
              controller: timetableControllers[day]![index],
              decoration: InputDecoration(
                labelText: 'P${index + 1}',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [CapitalizeFirstLetterFormatter()],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimetableInput(String day) {
    return ExpansionTile(
      title: Text(day, style: Theme.of(context).textTheme.titleMedium),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildPeriodInputsRow(day),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopAppbar(title: 'Manage Timetable')
              : MobileAppbar(title: 'Manage Timetable'),
      body:
          isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    children: [
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: InputDecoration(
                          labelText: "Select Class",
                          prefixIcon: const Icon(Icons.class_),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        value: selectedClass,
                        items:
                            classList.map((cls) {
                              final label =
                                  'Class ${cls['class']} - ${cls['section']}';
                              return DropdownMenuItem(
                                value: cls,
                                child: Text(label),
                              );
                            }).toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedClass = val;
                            isLoading = true;
                            _clearTimetableInputs();
                          });
                          await loadTimetable();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedClass != null)
                        ...days.map(_buildTimetableInput).toList(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmAndSave,
        label: const Text("Save"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
