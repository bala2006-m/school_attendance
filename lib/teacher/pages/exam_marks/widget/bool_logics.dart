// import 'dart:core';
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../admin/services/admin_api_service.dart';
// import '../add_exam_marks.dart';
//
// /// ✅ Safe date parser (returns null if invalid)
// DateTime? _tryParseDate(String? text) {
//   if (text == null || text.trim().isEmpty) return null;
//   try {
//     return DateTime.parse(text.trim());
//   } catch (_) {
//     return null;
//   }
// }
//
// /// ✅ Safe date formatter (returns '' if invalid)
// String _safeFormatDate(String? dateString) {
//   final parsed = _tryParseDate(dateString);
//   return parsed != null ? DateFormat('yyyy-MM-dd').format(parsed) : '';
// }
//
// bool canSubmit({
//   required String? examName,
//   required String? subject,
//   required int? minMark,
//   required int? maxMark,
//   required DateTime? examDate,
//   required String? session,
//   required String? enteredMark,
// }) {
//   if (examName == null || examName.trim().isEmpty) return false;
//   if (subject == null || subject.trim().isEmpty) return false;
//   if (minMark == null) return false;
//   if (maxMark == null) return false;
//   if (examDate == null) return false;
//   if (session == null || session.trim().isEmpty) return false;
//   if (enteredMark == null || enteredMark.trim().isEmpty) return false;
//
//   if (enteredMark.toUpperCase() == 'AA') return true;
//
//   final mark = int.tryParse(enteredMark);
//   if (mark == null) return false;
//   if (mark < 0 || mark > maxMark) return false;
//
//   return true;
// }
//
// Set<String> getUsedDateSessions({required List<dynamic> examMarks}) {
//   final used = <String>{};
//
//   for (var mark in examMarks) {
//     final dates =
//         mark['date'] is List
//             ? List<String>.from(
//               mark['date'].map((e) => _safeFormatDate(e.toString())),
//             )
//             : [_safeFormatDate(mark['date']?.toString())];
//
//     final sessions =
//         mark['session'] is List
//             ? List<String>.from(
//               mark['session'].map((e) => e.toString().toUpperCase()),
//             )
//             : [mark['session']?.toString().toUpperCase() ?? ''];
//
//     for (var d in dates) {
//       if (d.isEmpty) continue;
//       for (var s in sessions) {
//         if (s.isEmpty) continue;
//         used.add('$d|$s');
//       }
//     }
//   }
//
//   return used;
// }
//
// void updateExamNameSuggestions({required List<dynamic> examMarks}) {
//   final titlesSet = <String>{};
//   for (var m in examMarks) {
//     final t = m['title']?.toString().trim() ?? '';
//     if (t.isNotEmpty) titlesSet.add(t);
//   }
//
//   AddExamMarksState.examNameSuggestions = titlesSet.toList()..sort();
// }
//
// void updateSubjectSuggestions({
//   required TextEditingController examNameController,
//   required List<dynamic> examMarks,
// }) {
//   final inputExamName = examNameController.text.trim().toLowerCase();
//   final subjectsSet = <String>{};
//
//   for (var mark in examMarks) {
//     final title = mark['title']?.toString().trim().toLowerCase() ?? '';
//
//     if (inputExamName.isEmpty || title.contains(inputExamName)) {
//       final subs = (mark['subjects'] as List<dynamic>? ?? []);
//       for (var s in subs) {
//         final ss = s?.toString().trim() ?? '';
//         if (ss.isNotEmpty) subjectsSet.add(ss);
//       }
//     }
//   }
//
//   AddExamMarksState.subjectSuggestions = subjectsSet.toList()..sort();
// }
//
// void checkHasChanged({
//   required TextEditingController examNameController,
//   required TextEditingController subjectController,
//   required TextEditingController minMarkController,
//   required TextEditingController maxMarkController,
//   required TextEditingController dateController,
//   required TextEditingController sessionController,
//   required List<dynamic> examMarks,
//   required Map<String, TextEditingController> markControllers,
//   required List<Map<String, dynamic>> students,
// }) {
//   final examName = examNameController.text.trim();
//   final subject = subjectController.text.trim();
//   final minMark = int.tryParse(minMarkController.text.trim()) ?? 0;
//   final maxMark = int.tryParse(maxMarkController.text.trim()) ?? 100;
//   final date = dateController.text.trim();
//   final session = sessionController.text.trim().toUpperCase();
//
//   if (examName.isEmpty || subject.isEmpty || date.isEmpty || session.isEmpty) {
//     AddExamMarksState.hasChanged = false;
//     return;
//   }
//
//   for (var student in students) {
//     final username = student['username'].toString();
//     final markText = markControllers[username]?.text.trim() ?? '';
//
//     final existing = examMarks.firstWhere(
//       (mark) =>
//           mark['username'].toString() == username &&
//           mark['title'].toString().trim().toLowerCase() ==
//               examName.toLowerCase(),
//       orElse: () => null,
//     );
//
//     if (existing == null) {
//       if (markText.isNotEmpty) {
//         AddExamMarksState.hasChanged = true;
//         return;
//       }
//       continue;
//     }
//
//     final subList = List<String>.from(existing['subjects'] ?? []);
//     final subIndex = subList.indexWhere(
//       (s) => s.trim().toLowerCase() == subject.toLowerCase(),
//     );
//     final existingMark =
//         (existing['marks'] != null &&
//                 subIndex >= 0 &&
//                 subIndex < existing['marks'].length)
//             ? existing['marks'][subIndex].toString()
//             : '';
//
//     if (existingMark != markText) {
//       AddExamMarksState.hasChanged = true;
//       return;
//     }
//
//     if (existing['min_max_marks']?[0] != minMark ||
//         existing['min_max_marks']?[1] != maxMark) {
//       AddExamMarksState.hasChanged = true;
//       return;
//     }
//
//     final existingDates =
//         existing['date'] is List
//             ? List<String>.from(existing['date'].map((e) => e.toString()))
//             : [existing['date'].toString()];
//     if (!existingDates.contains(date)) {
//       AddExamMarksState.hasChanged = true;
//       return;
//     }
//
//     final existingSessions =
//         existing['session'] is List
//             ? List<String>.from(
//               existing['session'].map((e) => e.toString().toUpperCase()),
//             )
//             : [existing['session'].toString().toUpperCase()];
//     if (!existingSessions.contains(session)) {
//       AddExamMarksState.hasChanged = true;
//       return;
//     }
//   }
//
//   AddExamMarksState.hasChanged = false;
// }
//
// Future<void> submitMarks({
//   required TextEditingController examNameController,
//   required BuildContext context,
//   required TextEditingController subjectController,
//   required TextEditingController minMarkController,
//   required TextEditingController maxMarkController,
//   required TextEditingController dateController,
//   required TextEditingController sessionController,
//   required List<dynamic> examMarks,
//   required Map<String, TextEditingController> markControllers,
//   required List<Map<String, dynamic>> students,
//   required Map<String, int> subjectRanks,
//   required String schoolId,
//   required String classId,
//   required String username,
//   required Future<void> Function() fetchExamMarks,
//   required Future<void> Function() prefillExistingMarks,
// }) async {
//   final examName = examNameController.text.trim();
//   final subject = subjectController.text.trim();
//   final minMark = int.tryParse(minMarkController.text.trim()) ?? 0;
//   final maxMark = int.tryParse(maxMarkController.text.trim()) ?? 100;
//   final date = dateController.text.trim();
//   final session = sessionController.text.trim().toUpperCase();
//
//   // ✅ Validate required fields
//   if (examName.isEmpty || subject.isEmpty || date.isEmpty || session.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Please fill all required fields")),
//     );
//     return;
//   }
//
//   // ✅ Validate date format
//   DateTime? parsedDate;
//   try {
//     parsedDate = DateFormat("yyyy-MM-dd").parseStrict(date);
//   } catch (_) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Invalid date format. Use yyyy-MM-dd")),
//     );
//     return;
//   }
//   final newDateIso = parsedDate.toIso8601String();
//
//   bool allSuccess = true;
//
//   for (var student in students) {
//     final username = student['username'].toString();
//     final markText = markControllers[username]?.text.trim() ?? '';
//
//     if (markText.isEmpty) continue;
//
//     final markValue = markText.toUpperCase() == 'AA' ? 'AA' : markText;
//     final subjectRankValue = subjectRanks[username] ?? -1;
//
//     final existing = examMarks.firstWhere(
//       (m) =>
//           m['username'].toString() == username &&
//           m['title'].toString().trim().toLowerCase() == examName.toLowerCase(),
//       orElse: () => null,
//     );
//
//     if (existing != null) {
//       List<String> subjects = List<String>.from(
//         existing['subjects']?.map((e) => e.toString()) ?? [],
//       );
//       List<String> marks = List<String>.from(
//         existing['marks']?.map((e) => e.toString()) ?? [],
//       );
//       List<int> subjectRanksList = List<int>.from(
//         existing['subject_rank']?.map(
//               (e) => int.tryParse(e.toString()) ?? -1,
//             ) ??
//             [],
//       );
//
//       List<String> existingDates =
//           existing['date'] is List
//               ? List<String>.from(existing['date'].map((e) => e.toString()))
//               : [existing['date']?.toString() ?? ''];
//
//       List<String> existingSessions =
//           existing['session'] is List
//               ? List<String>.from(existing['session'].map((e) => e.toString()))
//               : [existing['session']?.toString() ?? ''];
//
//       int subjIndex = subjects.indexWhere(
//         (s) => s.trim().toLowerCase() == subject.toLowerCase(),
//       );
//
//       if (subjIndex >= 0) {
//         marks[subjIndex] = markValue;
//         subjectRanksList[subjIndex] = subjectRankValue;
//
//         if (existingDates.length > subjIndex) {
//           existingDates[subjIndex] = newDateIso;
//         } else {
//           while (existingDates.length < subjIndex) {
//             existingDates.add('');
//           }
//           existingDates.add(newDateIso);
//         }
//
//         if (existingSessions.length > subjIndex) {
//           existingSessions[subjIndex] = session;
//         } else {
//           while (existingSessions.length < subjIndex) {
//             existingSessions.add('');
//           }
//           existingSessions.add(session);
//         }
//       } else {
//         subjects.add(subject);
//         marks.add(markValue);
//         subjectRanksList.add(subjectRankValue);
//         existingDates.add(newDateIso);
//         existingSessions.add(session);
//       }
//
//       final updateData = {
//         'subjects': subjects,
//         'marks': marks,
//         'subject_rank': subjectRanksList,
//         'min_max_marks': [minMark, maxMark],
//         'date': existingDates,
//         'session': existingSessions,
//         'updated_by': username,
//       };
//
//       final updateSuccess = await AdminApiService.updateExamMarksByUsername(
//         schoolId: int.parse(schoolId),
//         classId: int.parse(classId),
//         username: username,
//         title: examName,
//         updateData: updateData,
//       );
//
//       if (!updateSuccess) {
//         allSuccess = false;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Failed to update $username")));
//       }
//     } else {
//       final createResult = await AdminApiService.createExamMark(
//         schoolId: schoolId,
//         classId: classId,
//         username: username,
//         title: examName,
//         subjects: [subject],
//         marks: [markValue],
//         subjectRank: [subjectRankValue],
//         minMaxMarks: [minMark, maxMark],
//         rank: '',
//         createdBy: username,
//         updatedBy: username,
//         date: [newDateIso],
//         session: [session],
//       );
//
//       if (createResult != 'Success') {
//         allSuccess = false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to create $username: $createResult")),
//         );
//       }
//     }
//   }
//
//   if (allSuccess) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Marks saved successfully ✅")));
//     await fetchExamMarks();
//     await prefillExistingMarks();
//     AddExamMarksState.hasChanged = false;
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Some marks failed to save ❌")),
//     );
//   }
// }
