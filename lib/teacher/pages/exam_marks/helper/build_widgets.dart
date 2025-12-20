import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Small header widget
Widget buildHeader({required String className, required String section}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        className,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'Section : $section',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    ],
  );
}

Widget buildFormSection({
  required TextEditingController examNameController,
  required TextEditingController subjectController,
  required TextEditingController minMarkController,
  required TextEditingController maxMarkController,
  required TextEditingController dateController,
  required TextEditingController sessionController,
  required List<String> examNameSuggestions,
  required List<String> subjectSuggestions,
  required List<Map<String, dynamic>> students,
  required Map<String, TextEditingController> markControllers,
  required Map<String, int> subjectRanks,
  required bool dateManuallyEdited,
  required bool sessionManuallyEdited,
  required bool isHolidayForSelectedDate,
  required VoidCallback onDateManuallyEdited,
  required VoidCallback onSessionManuallyEdited,
  required Future<void> Function() fetchAttendanceForCurrentDateSession,
  required Future<void> Function() prefillExistingMarks,
  required Future<void> Function() updateSubjectSuggestionsBasedOnExam,
  required BuildContext context,
}) {
  const primaryBlue = Color(0xFF1E88E5);
  final lightBlue = Colors.blue[50];

  OutlineInputBorder blueBorder({
    double width = 1.5,
    Color color = primaryBlue,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );

  return Card(
    elevation: 8, // stronger shadow for card
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    color: lightBlue,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title or Header (optional)
          Text(
            'Exam details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 16),

          // Exam Name Autocomplete with icon and animated fade on suggestions
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              return examNameSuggestions.where(
                (option) => option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (value) async {
              examNameController.text = value;
              onDateManuallyEdited();
              onSessionManuallyEdited();
              await updateSubjectSuggestionsBasedOnExam();
              await prefillExistingMarks();
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
            ) {
              controller.text = examNameController.text;
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
              controller.addListener(() {
                if (examNameController.text != controller.text) {
                  examNameController.text = controller.text;
                }
              });
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Exam Name',
                  labelStyle: TextStyle(color: primaryBlue),
                  hintText: 'Enter exam title',
                  prefixIcon: Icon(
                    Icons.school,
                    color: primaryBlue.withValues(alpha: 0.7),
                  ),
                  suffixIcon:
                      controller.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: primaryBlue),
                            onPressed: () => controller.clear(),
                            tooltip: 'Clear exam name',
                          )
                          : Icon(Icons.arrow_drop_down, color: primaryBlue),
                  filled: true,
                  fillColor: Colors.white,
                  border: blueBorder(),
                  focusedBorder: blueBorder(width: 2),
                ),
                onChanged: (value) async {
                  if (value.trim().isEmpty) {
                    subjectController.clear();
                    subjectSuggestions.clear();
                    (context as Element).markNeedsBuild();
                  } else {
                    await updateSubjectSuggestionsBasedOnExam();
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Subject Autocomplete with similar enhancements + icon
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              return subjectSuggestions.where(
                (option) => option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (value) async {
              subjectController.text = value;
              onDateManuallyEdited();
              onSessionManuallyEdited();
              await prefillExistingMarks();
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
            ) {
              controller.text = subjectController.text;
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
              controller.addListener(() {
                if (subjectController.text != controller.text) {
                  subjectController.text = controller.text;
                }
              });
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: primaryBlue),
                  prefixIcon: Icon(
                    Icons.book,
                    color: primaryBlue.withValues(alpha: 0.7),
                  ),
                  hintText: 'Enter subject',
                  suffixIcon:
                      controller.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: primaryBlue),
                            onPressed: () => controller.clear(),
                            tooltip: 'Clear subject',
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: blueBorder(),
                  focusedBorder: blueBorder(width: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Min / Max Marks inputs side by side with icons
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: minMarkController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Mark',
                    labelStyle: TextStyle(color: primaryBlue),
                    prefixIcon: Icon(
                      Icons.exposure_minus_1,
                      color: primaryBlue.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: blueBorder(),
                    focusedBorder: blueBorder(width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: maxMarkController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Mark',
                    labelStyle: TextStyle(color: primaryBlue),
                    prefixIcon: Icon(
                      Icons.exposure_plus_1,
                      color: primaryBlue.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: blueBorder(),
                    focusedBorder: blueBorder(width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Session pickers row with enhanced UI
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _pickDate(
                      context: context,
                      dateController: dateController,
                      sessionController: sessionController,
                      fetchAttendance:
                          (_, __) async =>
                              await fetchAttendanceForCurrentDateSession(),
                      prefillExistingMarks: prefillExistingMarks,
                      dateManuallyEditedSetter: onDateManuallyEdited,
                      sessionManuallyEditedSetter: onSessionManuallyEdited,
                      validatedDateFromController: () {
                        try {
                          return DateFormat(
                            'yyyy-MM-dd',
                          ).parse(dateController.text);
                        } catch (_) {
                          return null;
                        }
                      },
                    );
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date (yyyy-MM-dd)',
                        labelStyle: TextStyle(color: primaryBlue),
                        helperText:
                            isHolidayForSelectedDate
                                ? 'Holiday selected'
                                : null,
                        helperStyle: TextStyle(color: Colors.blueAccent),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: primaryBlue,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: blueBorder(),
                        focusedBorder: blueBorder(width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(12),
                  borderColor: primaryBlue,
                  selectedBorderColor: primaryBlue,
                  selectedColor: Colors.white,
                  fillColor: primaryBlue,
                  color: primaryBlue,
                  constraints: BoxConstraints(minHeight: 48, minWidth: 60),
                  isSelected: [
                    sessionController.text == 'FN',
                    sessionController.text == 'AN',
                  ],
                  onPressed: (index) async {
                    final value = (index == 0) ? 'FN' : 'AN';
                    sessionController.text = value;
                    onSessionManuallyEdited();
                    await fetchAttendanceForCurrentDateSession();
                  },
                  children: const [
                    Text('FN', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('AN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button with elevated shadow & hover effect
          ElevatedButton(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(
                Size(MediaQuery.sizeOf(context).width, 52),
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return primaryBlue.withValues(alpha: 0.8);
                }
                if (states.contains(WidgetState.disabled)) return Colors.grey;
                return primaryBlue;
              }),
              elevation: WidgetStateProperty.all(6),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              shadowColor: WidgetStateProperty.all(
                primaryBlue.withValues(alpha: 0.5),
              ),
              overlayColor: WidgetStateProperty.all(
                primaryBlue.withValues(alpha: 0.15),
              ),
            ),
            onPressed: () {
              dateManuallyEdited = true;
              sessionManuallyEdited = true;
              prefillExistingMarks();
              fetchAttendanceForCurrentDateSession();
            },
            child: const Text(
              'Apply',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );
}

// Date picker function with boolean setters (callback)
Future<void> _pickDate({
  required BuildContext context,
  required TextEditingController dateController,
  required TextEditingController sessionController,
  required Future<void> Function(DateTime, String) fetchAttendance,
  required Future<void> Function() prefillExistingMarks,
  required VoidCallback dateManuallyEditedSetter,
  required VoidCallback sessionManuallyEditedSetter,
  required DateTime? Function() validatedDateFromController,
}) async {
  final currentDate = validatedDateFromController() ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: currentDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked != null) {
    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    dateManuallyEditedSetter.call();
    await fetchAttendance(picked, sessionController.text.toUpperCase());
    await prefillExistingMarks();
  }
}

// Attendance / marks list view
Widget buildAttendanceList({
  required List<Map<String, dynamic>> students,
  required Map<String, TextEditingController> markControllers,
  required Map<String, int> subjectRanks,
  required TextEditingController minMarkController,
  required TextEditingController maxMarkController,
  required BuildContext context,
  required bool isHolidayForSelectedDate,
  required Future<void> Function() prefillExistingMarks,
  required Future<void> Function() updateSubjectSuggestionsBasedOnExam,
  required Future<void> Function() submitMarks,
}) {
  const primaryBlue = Color(0xFF1E88E5);
  final lightBlue = Colors.blue[50];

  OutlineInputBorder blueBorder({double width = 1.5}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: primaryBlue, width: width),
  );

  return Card(
    color: lightBlue,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 48,
                  child: Text(
                    'Admn no',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Student',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Mark',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Student rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final username = student['username'].toString();
              final name =
                  student['name']!.toString().length > 10
                      ? '${student['name']?.toString().substring(0, 10)}...'
                      : student['name']?.toString() ?? username;
              final markController = markControllers[username]!;
              final rank = subjectRanks[username];

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 48, child: Text(username)),
                    Expanded(child: Text(name)),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: markController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Mark',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          border: blueBorder(),
                          focusedBorder: blueBorder(width: 2),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) {
                          if (val.isEmpty) return;
                          final maxMark =
                              int.tryParse(maxMarkController.text) ?? 100;
                          final input = int.tryParse(val);
                          if (input == null || input > maxMark) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Mark must be between 0 and $maxMark',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Center(
                        child: Text(
                          rank == null
                              ? '-'
                              : (rank == -1 ? 'NA' : rank.toString()),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import 'exam_mark_helper.dart';
//
// // small header widget
// Widget buildHeader({required String className, required String section}) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.center,
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Text(
//         className,
//         style: const TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           color: Colors.teal,
//         ),
//       ),
//       const SizedBox(width: 10),
//       Text(
//         'Section : $section',
//         style: const TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           color: Colors.teal,
//         ),
//       ),
//     ],
//   );
// }
//
// // form for exam/subject/min/max/date/session
// Widget buildFormSection({
//   required TextEditingController examNameController,
//   required TextEditingController subjectController,
//   required TextEditingController minMarkController,
//   required TextEditingController maxMarkController,
//   required TextEditingController dateController,
//   required TextEditingController sessionController,
//   required List<String> examNameSuggestions,
//   required List<String> subjectSuggestions,
//   required List<Map<String, dynamic>> students,
//   required Map<String, TextEditingController> markControllers,
//   required Map<String, int> subjectRanks,
//   required bool dateManuallyEdited,
//   required bool sessionManuallyEdited,
//   required bool isHolidayForSelectedDate,
//   required Future<void> Function() fetchAttendanceForCurrentDateSession,
//   required Future<void> Function() prefillExistingMarks,
//   required Future<void> Function() updateSubjectSuggestionsBasedOnExam,
// }) {
//   return Column(
//     children: [
//       TextFormField(
//         controller: examNameController,
//         decoration: InputDecoration(
//           labelText: 'Exam Name',
//           hintText: 'Enter exam title',
//           suffixIcon:
//               examNameSuggestions.isEmpty
//                   ? null
//                   : PopupMenuButton<String>(
//                     icon: const Icon(Icons.arrow_drop_down),
//                     onSelected: (v) {
//                       examNameController.text = v;
//                       dateManuallyEdited = false;
//                       sessionManuallyEdited = false;
//                       updateSubjectSuggestionsBasedOnExam();
//                       prefillExistingMarks();
//                     },
//                     itemBuilder:
//                         (_) =>
//                             examNameSuggestions
//                                 .map(
//                                   (e) =>
//                                       PopupMenuItem(value: e, child: Text(e)),
//                                 )
//                                 .toList(),
//                   ),
//         ),
//       ),
//       const SizedBox(height: 8),
//       TextFormField(
//         controller: subjectController,
//         decoration: InputDecoration(
//           labelText: 'Subject',
//           hintText: 'Enter subject',
//           suffixIcon:
//               subjectSuggestions.isEmpty
//                   ? null
//                   : PopupMenuButton<String>(
//                     icon: const Icon(Icons.arrow_drop_down),
//                     onSelected: (v) {
//                       subjectController.text = v;
//                       dateManuallyEdited = false;
//                       sessionManuallyEdited = false;
//                       prefillExistingMarks();
//                     },
//                     itemBuilder:
//                         (_) =>
//                             subjectSuggestions
//                                 .map(
//                                   (e) =>
//                                       PopupMenuItem(value: e, child: Text(e)),
//                                 )
//                                 .toList(),
//                   ),
//         ),
//       ),
//       const SizedBox(height: 8),
//       Row(
//         children: [
//           Expanded(
//             child: TextFormField(
//               controller: minMarkController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'Min Mark'),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: TextFormField(
//               controller: maxMarkController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'Max Mark'),
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 8),
//       Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: _pickDate,
//               child: AbsorbPointer(
//                 child: TextFormField(
//                   controller: dateController,
//                   decoration: const InputDecoration(
//                     labelText: 'Date (yyyy-MM-dd)',
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           SizedBox(
//             width: 120,
//             child: TextFormField(
//               controller: sessionController,
//               decoration: const InputDecoration(labelText: 'Session (FN/AN)'),
//               onChanged: (_) {
//                 sessionManuallyEdited = true;
//                 fetchAttendanceForCurrentDateSession();
//               },
//             ),
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton(
//             onPressed: () {
//               dateManuallyEdited = true;
//               sessionManuallyEdited = true;
//               prefillExistingMarks();
//               fetchAttendanceForCurrentDateSession();
//             },
//             child: const Text('Apply'),
//           ),
//         ],
//       ),
//     ],
//   );
// }
//
// // date picker
// Future<void> _pickDate({
//   required BuildContext context,
//   required TextEditingController dateController,
//   required TextEditingController sessionController,
//   required Future<void> Function(DateTime, String) fetchAttendance,
//   required Future<void> Function() prefillExistingMarks,
//   required bool dateManuallyEdited,
//   required bool sessionManuallyEdited,
//   required DateTime? Function() validatedDateFromController,
// }) async {
//   final cur = validatedDateFromController() ?? DateTime.now();
//   final picked = await showDatePicker(
//     context: context,
//     initialDate: cur,
//     firstDate: DateTime(2000),
//     lastDate: DateTime(2100),
//   );
//   if (picked != null) {
//     dateController.text = DateFormat('yyyy-MM-dd').format(picked);
//     dateManuallyEdited = true;
//     await fetchAttendance(picked, sessionController.text.toUpperCase());
//     await prefillExistingMarks();
//   }
// }
//
// // attendance / marks list view
// Widget buildAttendanceList({
//   required List<Map<String, dynamic>> students,
//   required Map<String, TextEditingController> markControllers,
//   required Map<String, int> subjectRanks,
//   required TextEditingController minMarkController,
//   required TextEditingController maxMarkController,
//   required BuildContext context,
//   required bool isHolidayForSelectedDate,
//   required Future<void> Function() prefillExistingMarks,
//   required Future<void> Function() updateSubjectSuggestionsBasedOnExam,
//   required Future<void> Function() submitMarks,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//     child: Column(
//       children: [
//         // header row
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           child: Row(
//             children: const [
//               SizedBox(
//                 width: 48,
//                 child: Text(
//                   'S No',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   'Student',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 width: 100,
//                 child: Text(
//                   'Mark',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 width: 60,
//                 child: Text(
//                   'Rank',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Divider(),
//         // students rows
//         ...List.generate(students.length, (index) {
//           final s = students[index];
//           final u = s['username'].toString();
//           final name = s['name']?.toString() ?? s['username'].toString();
//           final markController = markControllers[u]!;
//           final rank = subjectRanks[u];
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6.0),
//             child: Row(
//               children: [
//                 SizedBox(width: 48, child: Text('${index + 1}')),
//                 Expanded(child: Text(name)),
//                 SizedBox(
//                   width: 100,
//                   child: TextField(
//                     onChanged: (val) {
//                       if (int.parse(val) > int.parse(maxMarkController.text)) {
//                         showColoredSnackBar(
//                           backgroundColor: Colors.red,
//                           context: context,
//                           message:
//                               'Mark must be between 0 and ${maxMarkController.text}',
//                         );
//                       }
//                     },
//                     controller: markController,
//                     textAlign: TextAlign.center,
//                     decoration: const InputDecoration(hintText: 'Mark'),
//                     keyboardType: TextInputType.text,
//                   ),
//                 ),
//                 SizedBox(
//                   width: 60,
//                   child: Center(
//                     child: Text(
//                       rank == null
//                           ? '-'
//                           : (rank == -1 ? 'NA' : rank.toString()),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ],
//     ),
//   );
// }
