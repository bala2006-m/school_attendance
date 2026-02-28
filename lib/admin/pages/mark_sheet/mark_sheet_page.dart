import 'dart:convert';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_attendance/services/api_service.dart';

import '../../../../teacher/services/teacher_api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../exam/model/exam_time_table_model.dart';
import '../exam/model/exam_time_table_service.dart';

class EditableMarksheet extends StatefulWidget {
  const EditableMarksheet({
    super.key,
    required this.username,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.classId,
  });
  final String username;
  final String schoolId;
  final String className;
  final String section;
  final String classId;

  @override
  State<EditableMarksheet> createState() => _EditableMarksheetState();
}

class _EditableMarksheetState extends State<EditableMarksheet> {
  final ExamTimeTableService _service = ExamTimeTableService();
  bool isLoading = false;
  List<ExamTimeTable> _existingTables = [];
  List<ExamTimeTable> _filteredTables = [];
  final Color primaryColor = const Color(0xFF1E3A8A);
  final Color secondaryColor = const Color(0xFF3B82F6);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color accentColor = Colors.pinkAccent;
  final TextEditingController _searchController = TextEditingController();
  int? expandedIndex;
  bool _isUploadingView = false;
  ExamTimeTable? _selectedExam;
  List<Map<String, dynamic>> _parsedStudents = [];
  List<String> _currentSubjects = [];
  List<int> _maxMarks = [];
  List<int> _minMarks = [];
  List<String> _existingMarkTitles = [];
  List<dynamic> studentMarks = [];
  String? _initialMarksJson;

  @override
  void initState() {
    super.initState();
    _loadExistingTimetable();
  }

  Future<void> init() async {
    try {
      // 1. Fetch titles for button status
      final titlesRaw = await AdminApiService.fetchExamMarkClassTitles(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );

      // 2. Fetch full class marks (for general metadata if needed)
      final marks = await AdminApiService.fetchExamMarkClass(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );

      if (mounted) {
        setState(() {
          _existingMarkTitles =
              titlesRaw.map((e) {
                if (e is Map && e.containsKey('title')) {
                  return e['title'].toString().trim().toUpperCase();
                }
                return e.toString().trim().toUpperCase();
              }).toList();
          studentMarks = marks;
        });
      }
    } catch (e) {
      debugPrint("Error in init: $e");
    }
  }

  Future<void> _loadExistingTimetable() async {
    setState(() => isLoading = true);

    try {
      final data = await _service.filterBySchoolClass(
        int.parse(widget.schoolId),
        int.parse(widget.classId),
      );
      setState(() {
        _existingTables = data;
        _filteredTables = data;
      });

      // Sequence: Timetable Loaded -> Then Fetch init data
      await init();
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentAttendance(String date) async {
    return ApiService.fetchStudentAttendance(
      schoolId: (widget.schoolId),
      classId: (widget.classId),
      date: date,
    );
  }

  void _filterTables(String query) {
    setState(() {
      _filteredTables =
          _existingTables
              .where(
                (table) =>
                    table.examTitle.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  Future<void> _importMarks(ExamTimeTable exam) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return;

      setState(() => isLoading = true);

      // --- Read file bytes ---
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = result.files.first.bytes;
      } else {
        bytes = result.files.first.bytes;
      }

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not read file bytes")),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      // --- Parse Excel ---
      var excel = Excel.decodeBytes(bytes);
      List<String> examSubjects = List<String>.from(exam.subjects as List);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.maxRows < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Excel file has insufficient data rows"),
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      // --- 1. SUBJECT VALIDATION ---
      // Read subject names from Row 1 (index 1), skipping first column
      final subjectRow = sheet.rows[1];
      List<String> excelSubjects = [];
      for (int col = 1; col < subjectRow.length; col++) {
        final val = subjectRow[col]?.value?.toString().trim() ?? "";
        if (val.isNotEmpty) {
          excelSubjects.add(val);
        }
      }

      // Normalize for comparison (case-insensitive, order-independent)
      final ttSubjectsNorm =
          examSubjects.map((s) => s.trim().toUpperCase()).toSet();
      final excelSubjectsNorm =
          excelSubjects.map((s) => s.trim().toUpperCase()).toSet();

      if (!ttSubjectsNorm.containsAll(excelSubjectsNorm) ||
          !excelSubjectsNorm.containsAll(ttSubjectsNorm)) {
        final missingInExcel = ttSubjectsNorm.difference(excelSubjectsNorm);
        final extraInExcel = excelSubjectsNorm.difference(ttSubjectsNorm);

        setState(() => isLoading = false);
        if (mounted) {
          await showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text("Subject Mismatch"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "The subjects in the Excel do not match the timetable.",
                        ),
                        const SizedBox(height: 12),
                        if (missingInExcel.isNotEmpty) ...[
                          const Text(
                            "Missing in Excel:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(missingInExcel.join(", ")),
                          const SizedBox(height: 8),
                        ],
                        if (extraInExcel.isNotEmpty) ...[
                          const Text(
                            "Extra in Excel:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(extraInExcel.join(", ")),
                        ],
                        const SizedBox(height: 12),
                        Text("Timetable: ${examSubjects.join(', ')}"),
                        Text("Excel: ${excelSubjects.join(', ')}"),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
        return;
      }

      // --- Build subject index mapping (Excel col -> timetable order) ---
      List<int> excelToTTIndexMap = [];
      for (int ttIdx = 0; ttIdx < examSubjects.length; ttIdx++) {
        final ttSubNorm = examSubjects[ttIdx].trim().toUpperCase();
        int excelColIdx = excelSubjects.indexWhere(
          (es) => es.trim().toUpperCase() == ttSubNorm,
        );
        excelToTTIndexMap.add(excelColIdx);
      }

      // --- 2. STUDENT VALIDATION ---
      List<Map<String, dynamic>> classStudents =
          await TeacherApiServices.fetchStudentData(
            schoolId: widget.schoolId,
            classId: widget.classId,
          );

      // Official admission numbers
      final officialAdmnNos =
          classStudents
              .map((s) => (s['username'] ?? '').toString().trim())
              .toSet();

      // Excel admission numbers (rows 2+)
      List<String> excelAdmnNos = [];
      for (int i = 2; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.isEmpty) continue;
        final admnNo = row[0]?.value?.toString().trim() ?? "";
        if (admnNo.isNotEmpty) {
          excelAdmnNos.add(admnNo);
        }
      }
      final excelAdmnSet = excelAdmnNos.toSet();

      final missingStudents = officialAdmnNos.difference(excelAdmnSet);
      final extraStudents = excelAdmnSet.difference(officialAdmnNos);

      if (missingStudents.isNotEmpty || extraStudents.isNotEmpty) {
        final admnToName = {
          for (var s in classStudents)
            (s['username'] ?? '').toString().trim():
                (s['name'] ?? '').toString(),
        };

        setState(() => isLoading = false);
        if (mounted) {
          await showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text("Student Mismatch"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "The students in the Excel do not match the class roster.",
                        ),
                        const SizedBox(height: 12),
                        if (missingStudents.isNotEmpty) ...[
                          const Text(
                            "Missing in Excel:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          ...missingStudents.map(
                            (id) =>
                                Text("$id - ${admnToName[id] ?? 'Unknown'}"),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (extraStudents.isNotEmpty) ...[
                          const Text(
                            "Extra in Excel (not in class):",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          ...extraStudents.map((id) => Text(id)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          "Class roster: ${officialAdmnNos.length} students",
                        ),
                        Text("Excel: ${excelAdmnNos.length} students"),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
        return;
      }

      // --- 3. PARSE MIN/MAX MARKS from Row 0 ---
      // Row 0 format: "I TERM" | "35/100" | "35/100" | ...
      final markInfoRow = sheet.rows[0];
      List<int> parsedMaxMarks = [];
      List<int> parsedMinMarks = [];
      for (int ttIdx = 0; ttIdx < examSubjects.length; ttIdx++) {
        int excelCol = excelToTTIndexMap[ttIdx];
        final cellVal =
            markInfoRow[excelCol + 1]?.value?.toString().trim() ?? "";
        if (cellVal.contains('/')) {
          final parts = cellVal.split('/');
          parsedMinMarks.add(int.tryParse(parts[0]) ?? 0);
          parsedMaxMarks.add(int.tryParse(parts[1]) ?? 100);
        } else {
          parsedMinMarks.add(0);
          parsedMaxMarks.add(int.tryParse(cellVal) ?? 100);
        }
      }

      // --- 4. PARSE MARKS (reordered to match timetable) ---
      final admnToName = {
        for (var s in classStudents)
          (s['username'] ?? '').toString().trim(): (s['name'] ?? '').toString(),
      };

      List<Map<String, dynamic>> studentsList = [];
      for (int i = 2; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.isEmpty) continue;

        String admnNo = row[0]?.value?.toString().trim() ?? "";
        String studentName = admnToName[admnNo] ?? admnNo;
        List<dynamic> marks = [];

        for (int ttIdx = 0; ttIdx < examSubjects.length; ttIdx++) {
          int excelCol = excelToTTIndexMap[ttIdx];
          var cellValue = row[excelCol + 1]?.value;
          if (cellValue != null) {
            final strVal = cellValue.toString().trim().toUpperCase();
            if (strVal == 'AA') {
              marks.add('AA');
            } else {
              marks.add(int.tryParse(strVal) ?? 0);
            }
          } else {
            marks.add(0);
          }
        }

        studentsList.add({
          "name": studentName,
          "admnNo": admnNo,
          "marks": marks,
        });
      }

      // --- 5. FETCH ATTENDANCE & APPLY AA for absent students ---
      final examDates = List<String>.from(exam.date as List);
      final examSessions = List<String>.from(exam.session as List);

      // Collect unique dates to avoid duplicate API calls
      final uniqueDates = examDates.toSet();
      final Map<String, List<Map<String, dynamic>>> attendanceByDate = {};

      for (final date in uniqueDates) {
        try {
          final att = await fetchStudentAttendance(date);
          attendanceByDate[date] = att;
        } catch (_) {
          attendanceByDate[date] = [];
        }
      }

      // For each subject, check attendance on its date+session
      for (int sIdx = 0; sIdx < examSubjects.length; sIdx++) {
        final subjectDate = examDates[sIdx];
        final subjectSession = examSessions[sIdx].toString().toUpperCase();
        final attList = attendanceByDate[subjectDate] ?? [];

        for (var student in studentsList) {
          final admnNo = student["admnNo"].toString();
          final att = attList.firstWhere(
            (a) => a['username'].toString() == admnNo,
            orElse: () => {},
          );

          if (att.isNotEmpty) {
            final status =
                subjectSession == 'FN'
                    ? (att['fn_status']?.toString() ?? '')
                    : (att['an_status']?.toString() ?? '');
            if (status == 'A') {
              (student["marks"] as List)[sIdx] = 'AA';
            }
          }
        }
      }

      setState(() {
        _selectedExam = exam;
        _currentSubjects = examSubjects;
        _parsedStudents = studentsList;
        _maxMarks = parsedMaxMarks;
        _minMarks = parsedMinMarks;

        _calculateRanks();

        _initialMarksJson = null; // Always allow save after fresh import
        _isUploadingView = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error importing Excel: $e")));
      }
      setState(() => isLoading = false);
    }
  }

  void _calculateRanks() {
    if (_parsedStudents.isEmpty || _currentSubjects.isEmpty) return;
    List<bool> studentEligibility = [];
    for (int i = 0; i < _parsedStudents.length; i++) {
      var marks = _parsedStudents[i]["marks"] as List;
      bool eligible = true;
      for (int sIdx = 0; sIdx < _currentSubjects.length; sIdx++) {
        var markVal = marks[sIdx];
        int minMark = sIdx < _minMarks.length ? _minMarks[sIdx] : 0;

        if (markVal.toString().toUpperCase() == 'AA') {
          eligible = false;
          break;
        }
        int score =
            markVal is int ? markVal : (int.tryParse(markVal.toString()) ?? 0);
        if (score < minMark) {
          eligible = false;
          break;
        }
      }
      studentEligibility.add(eligible);
      _parsedStudents[i]['subjectRanks'] = List<int>.filled(
        _currentSubjects.length,
        0,
      );
      _parsedStudents[i]['rank'] = 0;
    }
    for (int sIdx = 0; sIdx < _currentSubjects.length; sIdx++) {
      List<Map<String, dynamic>> subjectScores = [];
      for (int i = 0; i < _parsedStudents.length; i++) {
        if (!studentEligibility[i]) continue; // Skip ineligible

        var markVal = (_parsedStudents[i]["marks"] as List)[sIdx];
        // We already checked for AA in eligibility, so this must be a valid number
        int score =
            markVal is int ? markVal : (int.tryParse(markVal.toString()) ?? 0);
        subjectScores.add({'index': i, 'score': score});
      }

      // Sort desc
      subjectScores.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int),
      );

      int rank = 1;
      for (int k = 0; k < subjectScores.length; k++) {
        if (k > 0 &&
            subjectScores[k]['score'] == subjectScores[k - 1]['score']) {
          // Tie
          int prevIndex = subjectScores[k - 1]['index'];
          int prevRank =
              (_parsedStudents[prevIndex]['subjectRanks'] as List)[sIdx];
          int currIndex = subjectScores[k]['index'];
          (_parsedStudents[currIndex]['subjectRanks'] as List)[sIdx] = prevRank;
        } else {
          int currIndex = subjectScores[k]['index'];
          (_parsedStudents[currIndex]['subjectRanks'] as List)[sIdx] = rank;
        }
        rank++;
      }
    }

    // 3. Calculate Overall Ranks (only for eligible students)
    List<Map<String, dynamic>> totalScores = [];
    for (int i = 0; i < _parsedStudents.length; i++) {
      if (!studentEligibility[i]) continue; // Skip ineligible

      var marks = _parsedStudents[i]["marks"] as List;
      int total = marks.fold(0, (sum, m) {
        // We know passing students have no AA, but safe to check
        if (m.toString().toUpperCase() == 'AA') return sum;
        return (sum) + (m is int ? m : (int.tryParse(m.toString()) ?? 0));
      });
      totalScores.add({'index': i, 'score': total});
    }

    totalScores.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    int rank = 1;
    for (int k = 0; k < totalScores.length; k++) {
      if (k > 0 && totalScores[k]['score'] == totalScores[k - 1]['score']) {
        int prevIndex = totalScores[k - 1]['index'];
        int prevRank = _parsedStudents[prevIndex]['rank'] ?? 0;
        int currIndex = totalScores[k]['index'];
        _parsedStudents[currIndex]['rank'] = prevRank;
      } else {
        int currIndex = totalScores[k]['index'];
        _parsedStudents[currIndex]['rank'] = rank;
      }
      rank++;
    }
  }

  int getTotal(List<dynamic> marks) {
    return marks.fold<int>(0, (a, b) {
      if (b is int) return a + b;
      final val = int.tryParse(b.toString());
      return a + (val ?? 0);
    });
  }

  List<int> getMax() {
    if (_parsedStudents.isEmpty || _currentSubjects.isEmpty) return [];
    final dataRows = _parsedStudents;
    if (dataRows.isEmpty) return [];

    return List.generate(_currentSubjects.length, (i) {
      final numericMarks =
          dataRows
              .map((s) => (s["marks"] as List)[i])
              .map((m) => m is int ? m : int.tryParse(m.toString()))
              .whereType<int>()
              .toList();
      if (numericMarks.isEmpty) return 0;
      return numericMarks.reduce((a, b) => a > b ? a : b);
    });
  }

  List<int> getMin() {
    if (_parsedStudents.isEmpty || _currentSubjects.isEmpty) return [];
    final dataRows = _parsedStudents;
    if (dataRows.isEmpty) return [];

    return List.generate(_currentSubjects.length, (i) {
      final numericMarks =
          dataRows
              .map((s) => (s["marks"] as List)[i])
              .map((m) => m is int ? m : int.tryParse(m.toString()))
              .whereType<int>()
              .toList();
      if (numericMarks.isEmpty) return 0;
      return numericMarks.reduce((a, b) => a < b ? a : b);
    });
  }

  List<double> getAverage() {
    if (_parsedStudents.isEmpty || _currentSubjects.isEmpty) return [];
    final dataRows = _parsedStudents;
    if (dataRows.isEmpty) return [];

    return List.generate(_currentSubjects.length, (i) {
      final numericMarks =
          dataRows
              .map((s) => (s["marks"] as List)[i])
              .map((m) => m is int ? m : int.tryParse(m.toString()))
              .whereType<int>()
              .toList();
      if (numericMarks.isEmpty) return 0.0;
      double sum = numericMarks.reduce((a, b) => a + b).toDouble();
      return sum / numericMarks.length;
    });
  }

  bool _hasChanges() {
    if (_initialMarksJson == null) return true;
    final currentMarksJson = jsonEncode(
      _parsedStudents.map((s) => s['marks']).toList(),
    );
    return currentMarksJson != _initialMarksJson;
  }

  Future<void> _viewUpdateMarks(ExamTimeTable exam) async {
    setState(() => isLoading = true);
    try {
      final allStudents = await TeacherApiServices.fetchStudentData(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      final existingMarksRaw = await AdminApiService.fetchExamMarkClassTitle(
        schoolId: widget.schoolId,
        classId: widget.classId,
        title: exam.examTitle,
      );
      final Map<String, dynamic> marksMap = {};
      int? minMarkVal;
      int? maxMarkVal;

      for (var em in existingMarksRaw) {
        marksMap[em['username'].toString()] = em;
        if (minMarkVal == null && em['min_max_marks'] != null) {
          final mm = em['min_max_marks'] as List;
          if (mm.isNotEmpty) minMarkVal = int.tryParse(mm[0].toString());
          if (mm.length > 1) maxMarkVal = int.tryParse(mm[1].toString());
        }
      }
      List<Map<String, dynamic>> parsedList = [];
      for (var student in allStudents) {
        final admnNo = student['username'].toString();
        final name = student['name'] ?? 'Unknown';

        List<dynamic> studentMarksList;
        List<int> studentSubjRanks;
        dynamic overallRank;

        if (marksMap.containsKey(admnNo)) {
          final mData = marksMap[admnNo];
          studentMarksList =
              mData['marks'] ?? List.filled(exam.subjects.length, "AA");
          studentSubjRanks =
              (mData['subject_rank'] as List<dynamic>?)
                  ?.map((e) => int.tryParse(e.toString()) ?? 0)
                  .toList() ??
              List.filled(exam.subjects.length, 0);
          overallRank = mData['rank'];
        } else {
          studentMarksList = List.filled(exam.subjects.length, "AA");
          studentSubjRanks = List.filled(exam.subjects.length, 0);
          overallRank = "-";
        }

        parsedList.add({
          "admnNo": admnNo,
          "name": name,
          "marks": studentMarksList,
          "subjectRanks": studentSubjRanks,
          "rank":
              overallRank == '-'
                  ? -1
                  : int.tryParse(overallRank.toString()) ?? -1,
        });
      }

      // 4. Update State
      setState(() {
        _selectedExam = exam;
        _currentSubjects = List<String>.from(exam.subjects);
        _parsedStudents = parsedList;

        // Restore min/max marks
        // The API stores [min, max] globally (usually).
        // We need to expand this to lists for the UI state variables
        int defaultsMax = maxMarkVal ?? 100;
        int defaultsMin = minMarkVal ?? 35;

        _maxMarks = List.filled(_currentSubjects.length, defaultsMax);
        _minMarks = List.filled(_currentSubjects.length, defaultsMin);

        _calculateRanks(); // ensure everything is calculated initially

        _initialMarksJson = jsonEncode(
          parsedList.map((s) => s['marks']).toList(),
        );
        _isUploadingView = true;
      });
    } catch (e) {
      debugPrint("Error viewing marks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading marks: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> onWillPop() async {
    if (_isUploadingView) {
      setState(() {
        _isUploadingView = false;
        _selectedExam = null;
        _parsedStudents = [];
        _currentSubjects = [];
        _maxMarks = [];
        _minMarks = [];
      });
      return false;
    }
    if (kIsWeb) {
      return false;
    } else {
      Navigator.pop(context);
      return true;
    }
  }

  Future<void> submit() async {
    if (_parsedStudents.isEmpty || _selectedExam == null) return;

    setState(() => isLoading = true);

    int successCount = 0;
    int failCount = 0;

    try {
      for (var student in _parsedStudents) {
        final username = student['admnNo'].toString();

        final List<String> marksStr =
            (student['marks'] as List).map((e) => e.toString()).toList();
        final List<int> subjRanks =
            (student['subjectRanks'] as List<int>?) ??
            List.filled(_currentSubjects.length, 0);
        final String overallRank =
            (student['rank'] != null && student['rank'] > 0)
                ? student['rank'].toString()
                : "-";

        final List<String> dates = List<String>.from(_selectedExam!.date);
        final List<String> sessions = List<String>.from(_selectedExam!.session);

        int defaultMin = 0;
        int defaultMax = 100;
        if (_minMarks.isNotEmpty) defaultMin = _minMarks[0];
        if (_maxMarks.isNotEmpty) defaultMax = _maxMarks[0];

        // 1. Try Create
        String result = await AdminApiService.createExamMark(
          schoolId: widget.schoolId,
          classId: widget.classId,
          username: username,
          title: _selectedExam!.examTitle,
          minMaxMarks: [defaultMin, defaultMax],
          marks: marksStr,
          subjects: _currentSubjects,
          subjectRank: subjRanks,
          rank: overallRank,
          createdBy: widget.username,
          updatedBy: widget.username,
          date: dates,
          session: sessions,
        );

        if (result == 'Success') {
          successCount++;
        } else if (result.contains('already exists')) {
          // 2. Fallback to Update
          final updateData = {
            'subjects': _currentSubjects,
            'marks': marksStr,
            'subject_rank': subjRanks,
            'min_max_marks': [defaultMin, defaultMax],
            'rank': overallRank,
            'date': dates,
            'session': sessions,
            'updated_by': widget.username,
          };

          bool updated = await AdminApiService.updateExamMarksByUsername(
            schoolId: int.parse(widget.schoolId),
            classId: int.parse(widget.classId),
            username: username,
            title: _selectedExam!.examTitle,
            updateData: updateData,
          );

          if (updated) {
            successCount++;
          } else {
            failCount++;
            debugPrint("Failed to update for $username");
          }
        } else {
          failCount++;
          debugPrint("Failed to create for $username: $result");
        }
      }

      // Refresh marked exam titles to update "View/Update" button status
      await init();

      if (failCount == 0) {
        _initialMarksJson = jsonEncode(
          _parsedStudents.map((s) => s['marks']).toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Submission Complete. Success: $successCount, Failed: $failCount",
            ),
            backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting marks: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final max = getMax();
    // final min = getMin();
    // final avg = getAverage();
    final isMobile = MediaQuery.of(context).size.width < 900;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Exam Mark Sheet',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pop(context);
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Exam Mark Sheet',
                    onBack: () {
                      Navigator.pop(context);
                    },
                  ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_isUploadingView
                    ? _buildUploadMarkSheet()
                    : _buildExistingView()),
      ),
    );
  }

  Widget _buildSummaryAndSearch() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Overview",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${_existingTables.length} Total Timetables",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _filterTables,
          decoration: InputDecoration(
            hintText: "Search exam titles...",
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterTables("");
                      },
                    )
                    : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingView() {
    return Column(
      children: [
        _buildSummaryAndSearch(),
        const SizedBox(height: 10),
        if (_filteredTables.isEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _existingTables.isEmpty
                            ? "No Time Tables Created"
                            : "No results found for \"${_searchController.text}\"",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTables.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                final exam = _filteredTables[index];
                return _buildExamCard(exam, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExamCard(ExamTimeTable exam, int index) {
    final subjectCount = (exam.subjects as List).length;
    final bool isExpanded = expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryColor.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_outlined, color: primaryColor),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "$subjectCount Subjects • Created by ${exam.createdBy}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                subtitle: ElevatedButton(
                  onPressed: () {
                    if (_existingMarkTitles.contains(
                      exam.examTitle.trim().toUpperCase(),
                    )) {
                      _viewUpdateMarks(exam);
                    } else {
                      _importMarks(exam);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _existingMarkTitles.contains(
                              exam.examTitle.trim().toUpperCase(),
                            )
                            ? Colors.orange
                            : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _existingMarkTitles.contains(
                          exam.examTitle.trim().toUpperCase(),
                        )
                        ? "View/Update"
                        : "Select",
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                ),
              ),

              /// Expand content ONLY if arrow clicked
              if (isExpanded) ...[
                const Divider(indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: List.generate(subjectCount, (sIdx) {
                      final session = exam.session[sIdx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: secondaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${sIdx + 1}",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.subjects[sIdx],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "Date: ${exam.date[sIdx]} | Session: $session",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _getSessionBadge(session),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSessionBadge(String session) {
    final isFN = session == "FN";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isFN
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFN ? Icons.wb_sunny_outlined : Icons.wb_twilight_outlined,
            size: 14,
            color: isFN ? Colors.orange : Colors.purple,
          ),
          const SizedBox(width: 4),
          Text(
            session,
            style: TextStyle(
              color: isFN ? Colors.orange : Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadMarkSheet() {
    final max = getMax();
    final min = getMin();
    final avg = getAverage();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedExam?.examTitle ?? "Mark Sheet",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    "Review and edit marks before saving",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isUploadingView = false;
                        _selectedExam = null;
                        _parsedStudents = [];
                        _currentSubjects = [];
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (isLoading || !_hasChanges()) ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text("Save Marks"),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text("ADMN NO")),
                  ..._currentSubjects.map((s) => DataColumn(label: Text(s))),
                  const DataColumn(label: Text("Total")),
                  const DataColumn(label: Text("Rank")),
                ],
                rows: [
                  // Date and Session Row
                  if (_selectedExam != null)
                    DataRow(
                      color: WidgetStateProperty.all(
                        primaryColor.withValues(alpha: 0.05),
                      ),
                      cells: [
                        const DataCell(
                          Text(
                            "Date & Session",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...List.generate(_currentSubjects.length, (index) {
                          final date = _selectedExam!.date[index];
                          final session = _selectedExam!.session[index];
                          return DataCell(
                            Text(
                              "$date\n($session)",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          );
                        }),
                        const DataCell(Text("")), // Total column
                        const DataCell(Text("")), // Rank column
                      ],
                    ),
                  ..._parsedStudents.map((student) {
                    final studentMarks = student["marks"] as List;
                    final subjectRanks = student['subjectRanks'] as List<int>?;

                    return DataRow(
                      cells: [
                        DataCell(Text(student["name"])),
                        ...List.generate(_currentSubjects.length, (index) {
                          final markVal = studentMarks[index];
                          final isAA = markVal.toString().toUpperCase() == 'AA';
                          final numericMark =
                              isAA
                                  ? 0
                                  : (markVal is int
                                      ? markVal
                                      : int.tryParse(markVal.toString()) ?? 0);
                          final minMark =
                              index < _minMarks.length ? _minMarks[index] : 0;
                          final maxMark =
                              index < _maxMarks.length ? _maxMarks[index] : 100;
                          final isBelowMin = !isAA && numericMark < minMark;
                          final isRed = isAA || isBelowMin;

                          int subjectRank = 0;
                          if (subjectRanks != null &&
                              index < subjectRanks.length) {
                            subjectRank = subjectRanks[index];
                          }

                          return DataCell(
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: TextEditingController(
                                        text:
                                            isAA
                                                ? 'AA'
                                                : numericMark.toString(),
                                      )
                                      ..selection = TextSelection.collapsed(
                                        offset:
                                            isAA
                                                ? 2
                                                : numericMark.toString().length,
                                      ),
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                      color: isRed ? Colors.red : Colors.black,
                                      fontWeight:
                                          isRed
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        6,
                                        6,
                                        6,
                                        14,
                                      ), // details space
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              isRed
                                                  ? Colors.red.shade300
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final trimmed =
                                          value.trim().toUpperCase();
                                      bool updated = false;
                                      if (trimmed == 'AA' || trimmed == 'A') {
                                        studentMarks[index] = 'AA';
                                        updated = true;
                                      } else {
                                        final parsed = int.tryParse(trimmed);
                                        if (parsed != null) {
                                          final clamped = parsed.clamp(
                                            0,
                                            maxMark,
                                          );
                                          studentMarks[index] = clamped;
                                          updated = true;
                                        } else if (trimmed.isEmpty) {
                                          studentMarks[index] = 0;
                                          updated = true;
                                        }
                                      }

                                      if (updated) {
                                        setState(() {
                                          _calculateRanks();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                if (subjectRank > 0)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "#$subjectRank",
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        DataCell(
                          Text(
                            getTotal(
                              List<dynamic>.from(studentMarks),
                            ).toString(),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (student['rank'] == 1)
                                      ? Colors.amber.withValues(alpha: 0.2)
                                      : (student['rank'] == 2)
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : (student['rank'] == 3)
                                      ? Colors.brown.withValues(alpha: 0.2)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  (student['rank'] != null &&
                                          student['rank'] <= 3)
                                      ? Border.all(
                                        color:
                                            (student['rank'] == 1)
                                                ? Colors.amber
                                                : (student['rank'] == 2)
                                                ? Colors.grey
                                                : Colors.brown,
                                        width: 1,
                                      )
                                      : null,
                            ),
                            child: Text(
                              (student['rank'] != null && student['rank'] > 0)
                                  ? student['rank'].toString()
                                  : "-",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // MAX ROW
                  if (_parsedStudents.isNotEmpty)
                    DataRow(
                      color: WidgetStateProperty.all(Colors.grey.shade100),
                      cells: [
                        const DataCell(
                          Text(
                            "MAXIMUM",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...max.map(
                          (m) => DataCell(
                            Text(
                              m.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            max.fold(0, (a, b) => a + b).toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text("")), // Rank column
                      ],
                    ),

                  // MIN ROW
                  if (_parsedStudents.isNotEmpty)
                    DataRow(
                      color: WidgetStateProperty.all(Colors.grey.shade100),
                      cells: [
                        const DataCell(
                          Text(
                            "MINIMUM",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...min.map(
                          (m) => DataCell(
                            Text(
                              m.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            min.fold(0, (a, b) => a + b).toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text("")), // Rank column
                      ],
                    ),

                  // AVERAGE ROW
                  if (_parsedStudents.isNotEmpty)
                    DataRow(
                      color: WidgetStateProperty.all(Colors.grey.shade100),
                      cells: [
                        const DataCell(
                          Text(
                            "AVERAGE",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...avg.map(
                          (a) => DataCell(
                            Text(
                              a.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            (avg.isEmpty
                                    ? 0.0
                                    : avg.reduce((a, b) => a + b) / avg.length)
                                .toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text("")), // Rank column
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
