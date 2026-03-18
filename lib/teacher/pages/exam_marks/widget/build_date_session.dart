import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateSessionPicker extends StatefulWidget {
  final TextEditingController dateController;
  final TextEditingController sessionController;
  final List<dynamic> fetchedHolidays; // List of holiday maps
  final String classId;
  final Future<void> Function(DateTime, String) fetchAttendance;
  final VoidCallback? onDateChanged;
  final VoidCallback? onSessionChanged;
  final Set<String> usedDateSessions; // Set of "yyyy-MM-dd|FN/AN"

  const CustomDateSessionPicker({
    super.key,
    required this.dateController,
    required this.sessionController,
    required this.fetchedHolidays,
    required this.classId,
    required this.fetchAttendance,
    this.onDateChanged,
    this.onSessionChanged,
    required this.usedDateSessions,
  });

  @override
  State<CustomDateSessionPicker> createState() =>
      _CustomDateSessionPickerState();
}

class _CustomDateSessionPickerState extends State<CustomDateSessionPicker> {
  bool isSessionFixed = false;
  String forcedSession = '';
  bool isHolidayForSelectedDate = false;

  late Set<String> disabledDates;

  @override
  void initState() {
    super.initState();
    _buildDisabledDates();
  }

  void _buildDisabledDates() {
    disabledDates = {};

    // Add holiday dates for this class
    for (var h in widget.fetchedHolidays) {
      final holidayDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(h['date']));
      List<String> holidayClasses =
          (h['class_ids'] as List).map((e) => e.toString()).toList();
      if (holidayClasses.contains(widget.classId)) {
        disabledDates.add(holidayDate);
      }
    }

    // Add dates with both sessions used (FN and AN both used)
    final Map<String, int> sessionCount = {};
    for (var ds in widget.usedDateSessions) {
      final parts = ds.split('|'); // "yyyy-MM-dd|FN"
      if (parts.length == 2) {
        sessionCount[parts[0]] = (sessionCount[parts[0]] ?? 0) + 1;
      }
    }
    sessionCount.forEach((date, count) {
      if (count >= 2) {
        disabledDates.add(date);
      }
    });
  }

  bool _isDateEnabledSync(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return !disabledDates.contains(dateStr);
  }

  Future<DateTime> _findFirstEnabledDate(DateTime startDate) async {
    for (int i = 0; i < 30; i++) {
      final checkDate = startDate.add(Duration(days: i));
      if (_isDateEnabledSync(checkDate)) return checkDate;
    }
    return startDate;
  }

  Future<void> _pickDate() async {
    DateTime initialDate =
        DateTime.tryParse(widget.dateController.text) ?? DateTime.now();

    if (!_isDateEnabledSync(initialDate)) {
      initialDate = await _findFirstEnabledDate(initialDate);
    }

    DateTime? pickedDate;
    if (mounted) {
      pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        selectableDayPredicate: (date) {
          return _isDateEnabledSync(date);
        },
      );
    }

    if (pickedDate != null) {
      final pickedDateStr = DateFormat('yyyy-MM-dd').format(pickedDate);

      // Check holiday sessions for the picked date
      bool fnHoliday = false;
      bool anHoliday = false;
      for (var h in widget.fetchedHolidays) {
        final holidayDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(h['date']));
        List<String> holidayClasses =
            (h['class_ids'] as List).map((e) => e.toString()).toList();
        if (holidayDate == pickedDateStr &&
            holidayClasses.contains(widget.classId)) {
          if (h['fn'] == 'H') fnHoliday = true;
          if (h['an'] == 'H') anHoliday = true;
        }
      }

      setState(() {
        widget.dateController.text = pickedDateStr;

        if (fnHoliday && !anHoliday) {
          widget.sessionController.text = 'AN';
          isSessionFixed = true;
          forcedSession = 'AN';
        } else if (!fnHoliday && anHoliday) {
          widget.sessionController.text = 'FN';
          isSessionFixed = true;
          forcedSession = 'FN';
        } else {
          isSessionFixed = false;
          forcedSession = '';
        }

        isHolidayForSelectedDate = fnHoliday && anHoliday;

        if (widget.onDateChanged != null) widget.onDateChanged!();

        if (!isHolidayForSelectedDate) {
          widget.fetchAttendance(pickedDate!, widget.sessionController.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.dateController.text;

    // Build available session items dynamically
    final sessionItems = <DropdownMenuItem<String>>[];
    if (!widget.usedDateSessions.contains('$dateStr|FN')) {
      sessionItems.add(const DropdownMenuItem(value: 'FN', child: Text('FN')));
    }
    if (!widget.usedDateSessions.contains('$dateStr|AN')) {
      sessionItems.add(const DropdownMenuItem(value: 'AN', child: Text('AN')));
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.dateController,
            decoration: const InputDecoration(
              labelText: 'Exam Date',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue:
                widget.sessionController.text.isNotEmpty
                    ? widget.sessionController.text
                    : null,
            decoration: const InputDecoration(
              labelText: 'Session',
              border: OutlineInputBorder(),
            ),
            items: sessionItems,
            onChanged:
                isSessionFixed
                    ? null
                    : (value) async {
                      if (value != null) {
                        setState(() {
                          widget.sessionController.text = value;
                        });
                        final date = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(widget.dateController.text);
                        await widget.fetchAttendance(date, value);
                        if (widget.onSessionChanged != null) {
                          widget.onSessionChanged!();
                        }
                      }
                    },
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class CustomDateSessionPicker extends StatefulWidget {
//   const CustomDateSessionPicker({
//     super.key,
//     required this.dateController,
//     required this.sessionController,
//     required this.fetchedHolidays,
//     required this.classId,
//     required this.fetchAttendance,
//     required this.onDateChanged,
//     required this.onSessionChanged,
//     required this.usedDateSessions,
//     this.isExamNamePicked = false,
//     this.isSubjectPicked = false,
//   });
//
//   final Set<String> usedDateSessions;
//   final TextEditingController dateController;
//   final TextEditingController sessionController;
//   final List<Map<String, dynamic>> fetchedHolidays;
//   final String classId;
//   final Future<void> Function(DateTime date, String session) fetchAttendance;
//   final Future<void> Function() onDateChanged;
//   final Future<void> Function() onSessionChanged;
//
//   final bool isExamNamePicked;
//   final bool isSubjectPicked;
//
//   @override
//   State<CustomDateSessionPicker> createState() =>
//       _CustomDateSessionPickerState();
// }
//
// class _CustomDateSessionPickerState extends State<CustomDateSessionPicker> {
//   bool isHolidayForSelectedDate = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateHolidayStatus();
//   }
//
//   void _updateHolidayStatus() {
//     final dateStr = widget.dateController.text;
//     bool fnHoliday = false;
//     bool anHoliday = false;
//
//     for (var h in widget.fetchedHolidays) {
//       final holidayDate = DateFormat(
//         'yyyy-MM-dd',
//       ).format(DateTime.parse(h['date']));
//       final holidayClasses =
//           (h['class_ids'] as List).map((e) => e.toString()).toList();
//
//       if (holidayDate == dateStr && holidayClasses.contains(widget.classId)) {
//         if (h['fn'] == 'H') fnHoliday = true;
//         if (h['an'] == 'H') anHoliday = true;
//       }
//     }
//
//     setState(() {
//       isHolidayForSelectedDate = fnHoliday && anHoliday;
//     });
//   }
//
//   Future<void> _pickDate() async {
//     final initialDate =
//         DateTime.tryParse(widget.dateController.text) ?? DateTime.now();
//
//     final selectedDate = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       selectableDayPredicate: (date) {
//         final dateStr = DateFormat('yyyy-MM-dd').format(date);
//
//         for (var h in widget.fetchedHolidays) {
//           final holidayDate = DateFormat(
//             'yyyy-MM-dd',
//           ).format(DateTime.parse(h['date']));
//           final holidayClasses =
//               (h['class_ids'] as List).map((e) => e.toString()).toList();
//
//           if (holidayDate == dateStr &&
//               holidayClasses.contains(widget.classId)) {
//             if (h['fn'] == 'H' && h['an'] == 'H')
//               return false; // disable full holiday
//           }
//         }
//         return true;
//       },
//     );
//
//     if (selectedDate != null) {
//       widget.dateController.text = DateFormat(
//         'yyyy-MM-dd',
//       ).format(selectedDate);
//       _updateHolidayStatus();
//       await widget.fetchAttendance(selectedDate, widget.sessionController.text);
//       await widget.onDateChanged();
//       setState(() {}); // refresh UI
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final sessions = ['FN', 'AN'];
//     String sessionValue = widget.sessionController.text.toUpperCase();
//     if (!sessions.contains(sessionValue)) sessionValue = '';
//
//     if (widget.isExamNamePicked && widget.isSubjectPicked) {
//       // Show date and session as plain text
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Date"),
//           const SizedBox(height: 6),
//           Text(
//             widget.dateController.text.isEmpty
//                 ? "No date selected"
//                 : widget.dateController.text,
//             style: const TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           const Text("Session"),
//           const SizedBox(height: 6),
//           Text(
//             sessionValue.isEmpty ? "No session selected" : sessionValue,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ],
//       );
//     }
//
//     // Show date picker and session dropdown
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Select Date"),
//         const SizedBox(height: 6),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: widget.dateController,
//                 readOnly: true,
//                 onTap: _pickDate,
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   suffixIcon: Icon(Icons.calendar_today),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: DropdownButtonFormField<String>(
//                 value:
//                     widget.usedDateSessions.contains(
//                           "${widget.dateController.text}|$sessionValue",
//                         )
//                         ? null
//                         : sessionValue,
//                 items:
//                     sessions
//                         .map(
//                           (s) => DropdownMenuItem(
//                             value: s,
//                             enabled:
//                                 !widget.usedDateSessions.contains(
//                                   "${widget.dateController.text}|$s",
//                                 ),
//                             child: Text(
//                               s,
//                               style: TextStyle(
//                                 color:
//                                     widget.usedDateSessions.contains(
//                                           "${widget.dateController.text}|$s",
//                                         )
//                                         ? Colors.grey
//                                         : Colors.black,
//                               ),
//                             ),
//                           ),
//                         )
//                         .toList(),
//                 decoration: const InputDecoration(border: OutlineInputBorder()),
//                 onChanged: (value) async {
//                   if (value != null &&
//                       !widget.usedDateSessions.contains(
//                         "${widget.dateController.text}|$value",
//                       )) {
//                     widget.sessionController.text = value;
//                     await widget.fetchAttendance(
//                       DateFormat(
//                         'yyyy-MM-dd',
//                       ).parse(widget.dateController.text),
//                       value,
//                     );
//                     await widget.onSessionChanged();
//                     setState(() {});
//                   } else if (value != null) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           "Session $value for this date is already used.",
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//         if (isHolidayForSelectedDate)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Text(
//               "Selected date is a holiday. Marks entry may be restricted.",
//               style: TextStyle(
//                 color: Colors.orange.shade700,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
