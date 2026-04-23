import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../admin/services/admin_api_service.dart';
import '../../../services/api_service.dart';
import '../../appbar/mobile_appbar.dart';
import '../../services/teacher_api_service.dart';
import './helper/build_widgets.dart';
import './helper/exam_mark_helper.dart';
import 'exam_marks_classes.dart';

class AddExamMarks extends StatefulWidget {
  const AddExamMarks({
    super.key,
    required this.schoolId,
    required this.username,
    required this.className,
    required this.section,
    required this.classId,
  });

  final String schoolId;
  final String username;
  final String className;
  final String section;
  final String classId;

  @override
  State<AddExamMarks> createState() => _AddExamMarksState();
}

class _AddExamMarksState extends State<AddExamMarks> {
  // Controllers for form fields
  final TextEditingController examNameController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController minMarkController = TextEditingController(
    text: '35',
  );
  final TextEditingController maxMarkController = TextEditingController(
    text: '100',
  );
  final TextEditingController dateController = TextEditingController();
  final TextEditingController sessionController = TextEditingController(
    text: 'FN',
  );

  // State
  bool isLoading = true;
  bool isSubmitting = false;
  bool isHolidayForSelectedDate = false;
  bool _dateManuallyEdited = false;
  bool _sessionManuallyEdited = false;

  // Data
  List<Map<String, dynamic>> students = [];
  List<dynamic> examMarks = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> fetchedHolidays = [];

  // Per-student mark controllers & computed ranks
  final Map<String, TextEditingController> markControllers = {};
  final Map<String, int> subjectRanks = {};

  // Suggestions (derived from examMarks)
  List<String> examNameSuggestions = [];
  List<String> subjectSuggestions = [];

  // Debounce timers for suggestions
  Timer? _examNameDebounce;
  Timer? _subjectDebounce;

  // Track whether anything changed compared to existing marks
  bool hasChanged = false;

  /// Validate and return DateTime or null
  DateTime? _validatedDateFromController() {
    return tryParseDate(dateController.text);
  }

  /// Basic can submit check for a single student entry (used to enable submit button)

  // ---------------------------
  // Lifecycle
  // ---------------------------

  @override
  void initState() {
    super.initState();
    // set sensible defaults synchronously to avoid build-time parsing issues
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    sessionController.text = 'FN';
    // kick off data load
    _initAll();
    // watchers for suggestion updates & change detection
    examNameController.addListener(_onExamNameChanged);
    subjectController.addListener(_onSubjectChanged);
    minMarkController.addListener(_onFieldChanged);
    maxMarkController.addListener(_onFieldChanged);
    dateController.addListener(_onFieldChanged);
    sessionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _examNameDebounce?.cancel();
    _subjectDebounce?.cancel();
    examNameController.dispose();
    subjectController.dispose();
    minMarkController.dispose();
    maxMarkController.dispose();
    dateController.dispose();
    sessionController.dispose();
    for (final c in markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------
  // Data loading & helpers
  // ---------------------------

  Future<void> _initAll() async {
    setState(() {
      isLoading = true;
    });

    // fetch exam marks first for suggestions & prefill
    await _fetchExamMarks();
    // fetch students & attendance & holidays
    await _fetchStudentsAndInitControllers();
    await _fetchHolidays();
    // fetch attendance for selected date/session
    await _fetchAttendanceForCurrentDateSession();
    // build suggestions
    _updateSuggestions();
    // prefill marks where applicable
    await _prefillExistingMarks();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchExamMarks() async {
    try {
      examMarks = await AdminApiService.fetchExamMarkClass(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
    } catch (e) {
      examMarks = [];
      // optionally show snackbar
    }
  }

  Future<void> _fetchStudentsAndInitControllers() async {
    try {
      final fetched = await TeacherApiServices.fetchStudentData(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      // The API here previously returned {"status":"success","count":22,"students":[ ... ]}
      // But your original code used a plain list. Normalize to List<Map<String,dynamic>>
      if (fetched is Map && fetched[0]['students'] is List) {
        final raw = fetched[0]['students'] as List;
        students = raw.cast<Map<String, dynamic>>();
      } else {
        students = fetched.cast<Map<String, dynamic>>();
      }

      // Sort by gender then username numeric when possible (kept original behavior)
      students.sort((a, b) {
        final ag = a['gender']?.toString() ?? '';
        final bg = b['gender']?.toString() ?? '';
        if (ag == bg) {
          final au = a['username']?.toString() ?? '';
          final bu = b['username']?.toString() ?? '';
          final an = int.tryParse(au);
          final bn = int.tryParse(bu);
          if (an != null && bn != null) return an.compareTo(bn);
          return au.compareTo(bu);
        }
        if (ag == 'M') return -1;
        return 1;
      });

      // Create mark controllers for each student
      markControllers.clear();
      for (var s in students) {
        final u = s['username'].toString();
        final c = TextEditingController();
        c.addListener(() {
          _computeSubjectRanks();
          setState(() {}); // reflect rank changes & canSubmit validity
        });
        markControllers[u] = c;
      }
    } catch (e) {
      students = [];
    }
  }

  Future<void> _fetchHolidays() async {
    try {
      fetchedHolidays = await ApiService.fetchHolidays(widget.schoolId);
    } catch (e) {
      fetchedHolidays = [];
    }
  }

  Future<void> _fetchAttendanceForCurrentDateSession() async {
    final dt = _validatedDateFromController();
    if (dt == null) {
      attendance = [];
      setState(() {});
      return;
    }
    await _fetchAttendance(dt, sessionController.text.toUpperCase());
    setState(() {});
  }

  // Enable submit button only if all conditions met
  bool _canSubmitForm() {
    final examName = examNameController.text.trim();
    final subject = subjectController.text.trim();
    final minMark = int.tryParse(minMarkController.text.trim());
    final maxMark = int.tryParse(maxMarkController.text.trim());

    // Validate presence and correctness of form fields
    if (examName.isEmpty ||
        subject.isEmpty ||
        minMark == null ||
        maxMark == null ||
        minMark < 0 ||
        maxMark <= 0 ||
        minMark > maxMark) {
      return false;
    }

    bool anyValidMark = false;

    // Check if at least one student mark is valid
    for (var s in students) {
      final u = s['username'].toString();
      final text = markControllers[u]?.text.trim().toUpperCase() ?? '';

      if (text.isNotEmpty) {
        if (text == 'AA') {
          anyValidMark = true; // 'AA' counts as a valid mark
        } else {
          final val = int.tryParse(text);
          if (val == null) {
            return false; // invalid numeric mark
          } else if (val < 0 || val > maxMark) {
            return false; // mark out of acceptable range
          } else {
            anyValidMark = true;
          }
        }
      }
    }

    return anyValidMark;
  }

  Future<void> _fetchAttendance(DateTime date, String session) async {
    try {
      attendance = await ApiService.fetchStudentAttendance(
        date: DateFormat('yyyy-MM-dd').format(date),
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
    } catch (e) {
      attendance = [];
    }
    _applyAttendanceToMarks(session.toUpperCase());
    _updateHolidayStatusForDate(DateFormat('yyyy-MM-dd').format(date));
  }

  void _applyAttendanceToMarks(String session) {
    for (var s in students) {
      final u = s['username'].toString();
      final att = attendance.firstWhere(
        (a) => a['username'].toString() == u,
        orElse: () => {},
      );
      String status = '';
      if (att.isNotEmpty) {
        status =
            session == 'FN'
                ? (att['fn_status']?.toString() ?? '')
                : (att['an_status']?.toString() ?? '');
      }
      if (status == 'A') {
        markControllers[u]?.text = 'AA';
      } else {
        if (markControllers[u]?.text.toUpperCase() == 'AA') {
          markControllers[u]?.clear();
        }
      }
    }
    setState(() {});
  }

  void _updateHolidayStatusForDate(String dateYmd) {
    bool fnH = false;
    bool anH = false;
    for (var h in fetchedHolidays) {
      final raw = h['date']?.toString() ?? '';
      final formatted = safeFormatToYMD(raw);
      final classIds =
          (h['class_ids'] is List)
              ? (h['class_ids'] as List).map((e) => e.toString()).toList()
              : [];
      if (formatted == dateYmd &&
          classIds.contains(widget.classId.toString())) {
        if (h['fn'] == 'H') fnH = true;
        if (h['an'] == 'H') anH = true;
      }
    }
    setState(() {
      isHolidayForSelectedDate = fnH && anH;
    });
  }

  /// Prefill existing marks for the selected exam/title/subject/date/session
  Future<void> _prefillExistingMarks() async {
    final examName = examNameController.text.trim().toLowerCase();
    final subject = subjectController.text.trim().toLowerCase();
    final session = sessionController.text.trim().toUpperCase();

    if (examName.isEmpty || subject.isEmpty) {
      for (var u in markControllers.keys) {
        markControllers[u]?.clear();
      }
      _computeSubjectRanks();
      setState(() {});
      return;
    }

    for (var s in students) {
      final u = s['username'].toString();

      // Return null if no attendance found to avoid NPE
      final att = attendance.firstWhere(
        (a) => a['username'].toString() == u,
        orElse: () => {},
      );

      String attStatus = '';
      attStatus =
          (session == 'FN')
              ? (att['fn_status']?.toString() ?? '')
              : (att['an_status']?.toString() ?? '');

      final existing = examMarks.firstWhere(
        (m) =>
            m['username']?.toString() == u &&
            (m['title']?.toString().trim().toLowerCase() ?? '') == examName,
        orElse: () => null,
      );

      if (existing != null) {
        final subjects = List<String>.from(existing['subjects'] ?? []);
        final marks = List<String>.from(existing['marks'] ?? []);
        final sessions =
            existing['session'] is List
                ? List<String>.from(
                  existing['session'].map((e) => e.toString().toUpperCase()),
                )
                : [existing['session']?.toString().toUpperCase() ?? ''];

        final matchedIndices = <int>[];
        for (int i = 0; i < subjects.length; i++) {
          if (subjects[i].trim().toLowerCase() == subject) {
            matchedIndices.add(i);
          }
        }

        String existingMark = '';
        for (int idx in matchedIndices) {
          if (idx < sessions.length && sessions[idx] == session) {
            if (idx < marks.length) {
              existingMark = marks[idx].toString();
              break;
            }
          }
        }

        if (existingMark.isEmpty && matchedIndices.isNotEmpty) {
          final fallbackIndex = matchedIndices.first;
          if (fallbackIndex < marks.length) {
            existingMark = marks[fallbackIndex].toString();
          }
        }

        markControllers[u]?.text = attStatus == 'A' ? 'AA' : existingMark;

        if (!_dateManuallyEdited &&
            existing['date'] != null &&
            examName.isNotEmpty &&
            subject.isNotEmpty) {
          final rawDates =
              existing['date'] is List
                  ? List<String>.from(existing['date'].map((e) => e.toString()))
                  : [existing['date']?.toString() ?? ''];
          String dateToUse = '';
          if (matchedIndices.isNotEmpty) {
            for (int idx in matchedIndices) {
              if (idx < rawDates.length) {
                dateToUse = rawDates[idx];
                break;
              }
            }
          }
          if (dateToUse.isEmpty && rawDates.isNotEmpty) {
            dateToUse = rawDates.first;
          }
          final fmtDate = safeFormatToYMD(dateToUse);
          if (fmtDate.isNotEmpty) dateController.text = fmtDate;
        }

        if (!_sessionManuallyEdited &&
            existing['session'] != null &&
            examName.isNotEmpty &&
            subject.isNotEmpty) {
          final rawSessions =
              existing['session'] is List
                  ? List<String>.from(
                    existing['session'].map((e) => e.toString().toUpperCase()),
                  )
                  : [existing['session']?.toString().toUpperCase() ?? ''];
          String sessionToUse = '';
          if (matchedIndices.isNotEmpty) {
            for (int idx in matchedIndices) {
              if (idx < rawSessions.length) {
                sessionToUse = rawSessions[idx];
                break;
              }
            }
          }
          if (sessionToUse.isEmpty && rawSessions.isNotEmpty) {
            sessionToUse = rawSessions.first;
          }
          if (sessionToUse.isNotEmpty) {
            sessionController.text = sessionToUse;
          }
        }

        if (existing['min_max_marks'] is List &&
            (existing['min_max_marks'] as List).length >= 2 &&
            examName.isNotEmpty &&
            subject.isNotEmpty) {
          final mm = existing['min_max_marks'] as List;
          minMarkController.text = mm[0].toString();
          maxMarkController.text = mm[1].toString();
        }
      } else {
        markControllers[u]?.text = attStatus == 'A' ? 'AA' : '';
      }
    }

    _computeSubjectRanks();
    setState(() {});
  }

  // ---------------------------
  // Ranking logic
  // ---------------------------

  void _computeSubjectRanks() {
    subjectRanks.clear();
    final minMark = int.tryParse(minMarkController.text.trim()) ?? 0;
    final List<Map<String, dynamic>> validMarks = [];
    for (var s in students) {
      final u = s['username'].toString();
      final txt = markControllers[u]?.text.trim() ?? '';
      if (txt.isEmpty) continue;
      if (txt.toUpperCase() == 'AA') {
        subjectRanks[u] = -1;
        continue;
      }
      final m = int.tryParse(txt);
      if (m == null) {
        subjectRanks[u] = -1;
        continue;
      }
      if (m < minMark) {
        subjectRanks[u] = -1;
        continue;
      }
      validMarks.add({'username': u, 'mark': m});
    }

    // sort desc
    validMarks.sort((a, b) => b['mark'].compareTo(a['mark']));
    int rank = 1;
    for (var i = 0; i < validMarks.length; i++) {
      final u = validMarks[i]['username'];
      final m = validMarks[i]['mark'] as int;
      if (i > 0 && m == validMarks[i - 1]['mark']) {
        subjectRanks[u] = subjectRanks[validMarks[i - 1]['username']]!;
      } else {
        subjectRanks[u] = rank;
      }
      rank++;
    }
  }

  // ---------------------------
  // Event handlers for text controllers
  // ---------------------------

  void _onExamNameChanged() {
    _examNameDebounce?.cancel();
    _examNameDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _dateManuallyEdited = false;
        _sessionManuallyEdited = false;
      });

      _updateSuggestions();
      await _updateSubjectSuggestionsBasedOnExam();
      await _prefillExistingMarks();
      await _fetchAttendanceForCurrentDateSession();
    });
  }

  // Called when subject input changes
  void _onSubjectChanged() {
    _subjectDebounce?.cancel();
    _subjectDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _dateManuallyEdited = false;
        _sessionManuallyEdited = false;
      });

      await _updateSubjectSuggestionsBasedOnExam();
      await _prefillExistingMarks();
      await _fetchAttendanceForCurrentDateSession();
    });
  }

  void _onFieldChanged() {
    // generic change -> recompute ranks / canSubmit
    _computeSubjectRanks();
    setState(() {});
  }

  void _updateSuggestions() {
    final titles = <String>{};
    final subs = <String>{};
    for (var m in examMarks) {
      final t = m['title']?.toString().trim() ?? '';
      if (t.isNotEmpty) titles.add(t);

      final subjects = (m['subjects'] is List) ? (m['subjects'] as List) : [];
      for (var s in subjects) {
        final ss = s?.toString().trim() ?? '';
        if (ss.isNotEmpty) subs.add(ss);
      }
    }
    setState(() {
      examNameSuggestions = titles.toList()..sort();
      subjectSuggestions = subs.toList()..sort();
    });
  }

  Future<void> _updateSubjectSuggestionsBasedOnExam() async {
    final inputExam = examNameController.text.trim().toLowerCase();

    if (inputExam.isEmpty) {
      // No exam selected, clear subjects
      setState(() {
        subjectSuggestions = [];
      });
      return;
    }

    final subs = <String>{};

    // Filter subjects for the selected exam
    for (var m in examMarks) {
      final title = m['title']?.toString().trim().toLowerCase() ?? '';
      if (title == inputExam) {
        final sList = (m['subjects'] is List) ? (m['subjects'] as List) : [];
        for (var s in sList) {
          final ss = s?.toString().trim() ?? '';
          if (ss.isNotEmpty) subs.add(ss);
        }
      }
    }

    setState(() {
      subjectSuggestions = subs.toList()..sort();
    });
  }

  // ---------------------------
  // Submit logic
  // ---------------------------

  Future<void> _submitMarks() async {
    if (isSubmitting) return;

    final examName = examNameController.text.trim();
    final subject = subjectController.text.trim();
    final minMark = int.tryParse(minMarkController.text.trim()) ?? 0;
    final maxMark = int.tryParse(maxMarkController.text.trim()) ?? 100;
    final dateStr = dateController.text.trim();
    final session = sessionController.text.trim().toUpperCase();

    if (examName.isEmpty ||
        subject.isEmpty ||
        dateStr.isEmpty ||
        session.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final parsedDate = tryParseDate(dateStr);
    if (parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid date. Use yyyy-MM-dd or ISO date'),
        ),
      );
      return;
    }
    final newDateIso =
        DateFormat(
          'yyyy-MM-dd',
        ).parse(parsedDate.toIso8601String()).toIso8601String();
    // Note: we normalise to ISO; server previously stored ISO strings.

    setState(() {
      isSubmitting = true;
    });

    bool allSuccess = true;

    // iterate students and create/update per-student record
    for (var s in students) {
      final u = s['username'].toString();
      final rawMark = markControllers[u]?.text.trim() ?? '';
      if (rawMark.isEmpty) continue; // skip students with no mark

      final markValue = rawMark.toUpperCase() == 'AA' ? 'AA' : rawMark;
      final subjectRankValue = subjectRanks[u] ?? -1;

      // find existing record for this username + exam title
      final existing = examMarks.firstWhere(
        (m) =>
            m['username']?.toString() == u &&
            (m['title']?.toString().trim().toLowerCase() ?? '') ==
                examName.toLowerCase(),
        orElse: () => null,
      );

      if (existing != null) {
        // merge update
        List<String> subjects = List<String>.from(
          existing['subjects']?.map((e) => e.toString()) ?? [],
        );
        List<String> marks = List<String>.from(
          existing['marks']?.map((e) => e.toString()) ?? [],
        );
        List<int> subjRanks = List<int>.from(
          existing['subject_rank']?.map(
                (e) => int.tryParse(e.toString()) ?? -1,
              ) ??
              [],
        );

        // dates & sessions per subject index
        List<String> existingDates =
            existing['date'] is List
                ? List<String>.from(existing['date'].map((e) => e.toString()))
                : [existing['date']?.toString() ?? ''];
        List<String> existingSessions =
            existing['session'] is List
                ? List<String>.from(
                  existing['session'].map((e) => e.toString()),
                )
                : [existing['session']?.toString() ?? ''];

        int subjIndex = subjects.indexWhere(
          (x) => x.trim().toLowerCase() == subject.toLowerCase(),
        );

        if (subjIndex >= 0) {
          // update
          marks[subjIndex] = markValue;
          subjRanks[subjIndex] = subjectRankValue;

          if (existingDates.length > subjIndex) {
            existingDates[subjIndex] = newDateIso;
          } else {
            while (existingDates.length < subjIndex) {
              existingDates.add('');
            }
            existingDates.add(newDateIso);
          }

          if (existingSessions.length > subjIndex) {
            existingSessions[subjIndex] = session;
          } else {
            while (existingSessions.length < subjIndex) {
              existingSessions.add('');
            }
            existingSessions.add(session);
          }
        } else {
          // add new subject at end
          subjects.add(subject);
          marks.add(markValue);
          subjRanks.add(subjectRankValue);
          existingDates.add(newDateIso);
          existingSessions.add(session);
        }

        final updateData = {
          'subjects': subjects,
          'marks': marks,
          'subject_rank': subjRanks,
          'min_max_marks': [minMark, maxMark],
          'date': existingDates,
          'session': existingSessions,
          'updated_by': widget.username,
        };

        final updateSuccess = await AdminApiService.updateExamMarksByUsername(
          schoolId: int.parse(widget.schoolId),
          classId: int.parse(widget.classId),
          username: u,
          title: examName,
          updateData: updateData,
        );

        if (!updateSuccess) {
          allSuccess = false;
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to update $u')));
          }
        }
      } else {
        // create new record
        final createResult = await AdminApiService.createExamMark(
          schoolId: widget.schoolId,
          classId: widget.classId,
          username: u,
          title: examName,
          subjects: [subject],
          marks: [markValue],
          subjectRank: [subjectRankValue],
          minMaxMarks: [minMark.toString(), maxMark.toString()],
          rank: '',
          createdBy: widget.username,
          updatedBy: widget.username,
          date: [newDateIso],
          session: [session],
        );

        if (createResult != 'Success') {
          allSuccess = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create $u: $createResult')),
            );
          }
        }
      }
    } // end for students

    setState(() {
      isSubmitting = false;
    });

    if (allSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully ✅')),
        );
      }
      // Refresh data + reset fields per your choice
      await _initAll();
      // reset form fields
      examNameController.clear();
      subjectController.clear();
      minMarkController.text = '35';
      maxMarkController.text = '100';
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      sessionController.text = 'FN';
      for (var c in markControllers.values) {
        c.clear();
      }
      subjectRanks.clear();
      hasChanged = false;
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some marks failed to save ❌')),
        );
      }
    }
  }

  // ---------------------------
  // UI building
  // ---------------------------

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamMarksClasses(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  // Full body section of AddExamMarks widget
  @override
  Widget build(BuildContext context) {
    // final isMobile = MediaQuery.of(context).size.width < 500;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: MobileAppbar(
            username: widget.username,
            schoolId: widget.schoolId.toString(),
            title: 'Add Exam Marks',
            enableDrawer: false,
            enableBack: true,
            onBack: () {
              onWillPop();
            },
          ),
        ),
        body: Stack(
          children: [
            if (isLoading)
              const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
            else
              students.isEmpty
                  ? const Center(child: Text('No Students Found'))
                  : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: buildHeader(
                            className: widget.className,
                            section: widget.section,
                          ),
                        ),
                        const SizedBox(height: 12),
                        buildFormSection(
                          examNameController: examNameController,
                          subjectController: subjectController,
                          minMarkController: minMarkController,
                          maxMarkController: maxMarkController,
                          dateController: dateController,
                          sessionController: sessionController,
                          examNameSuggestions: examNameSuggestions,
                          subjectSuggestions: subjectSuggestions,
                          students: students,
                          markControllers: markControllers,
                          subjectRanks: subjectRanks,
                          dateManuallyEdited: _dateManuallyEdited,
                          sessionManuallyEdited: _sessionManuallyEdited,
                          isHolidayForSelectedDate: isHolidayForSelectedDate,
                          fetchAttendanceForCurrentDateSession:
                              _fetchAttendanceForCurrentDateSession,
                          prefillExistingMarks: _prefillExistingMarks,
                          updateSubjectSuggestionsBasedOnExam:
                              _updateSubjectSuggestionsBasedOnExam,
                          context: context,
                          onDateManuallyEdited: () {
                            setState(() {
                              _dateManuallyEdited = true;
                            });
                          },
                          onSessionManuallyEdited: () {
                            setState(() {
                              _sessionManuallyEdited = true;
                            });
                          },
                        ),
                        if (isHolidayForSelectedDate)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Selected day is a holiday. You can change the date or still enter marks.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        if (attendance.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Attendance not marked for selected date and session.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          )
                        else
                          buildAttendanceList(
                            students: students,
                            markControllers: markControllers,
                            subjectRanks: subjectRanks,
                            minMarkController: minMarkController,
                            maxMarkController: maxMarkController,
                            context: context,
                            isHolidayForSelectedDate: isHolidayForSelectedDate,
                            prefillExistingMarks: _prefillExistingMarks,
                            updateSubjectSuggestionsBasedOnExam:
                                _updateSubjectSuggestionsBasedOnExam,
                            submitMarks: _submitMarks,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 30,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (isSubmitting || !_canSubmitForm())
                                      ? null
                                      : _submitMarks,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.teal[700],
                              ),
                              child:
                                  isSubmitting
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Submit Marks',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
            if (isSubmitting)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: SpinKitFadingCircle(color: Colors.teal, size: 60),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
