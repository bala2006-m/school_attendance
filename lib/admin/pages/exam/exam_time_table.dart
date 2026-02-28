import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import 'model/exam_time_table_model.dart';
import 'model/exam_time_table_service.dart';

class ExamTimeTableScreen extends StatefulWidget {
  const ExamTimeTableScreen({
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
  State<ExamTimeTableScreen> createState() => _ExamTimeTableScreenState();
}

class _ExamTimeTableScreenState extends State<ExamTimeTableScreen> {
  final ExamTimeTableService _service = ExamTimeTableService();

  final TextEditingController _examTitleController = TextEditingController();

  List<ExamTimeTable> _existingTables = [];
  final List<Map<String, String>> _examList = [];

  bool _isLoading = false;
  bool _isCreating = false;
  int? _editingId; // Track if we are editing an existing timetable

  final TextEditingController _searchController = TextEditingController();
  List<ExamTimeTable> _filteredTables = [];
  String? _titleError;

  final Color primaryColor = const Color(0xFF1E3A8A); // link with premium blue
  final Color secondaryColor = const Color(0xFF3B82F6);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color accentColor = Colors.pinkAccent;

  final List<String> _titleSuggestions = ["I TERM", "II TERM", "III TERM"];
  final List<String> _subjectSuggestions = [
    "TAMIL",
    "ENGLISH",
    "MATHS",
    "SCIENCE",
    "SOCIAL",
    "EVS",
    "PET",
    "VS",
  ];

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadExistingTimetable();
  }

  Future<void> _loadExistingTimetable() async {
    setState(() => _isLoading = true);

    try {
      final data = await _service.filterBySchoolClass(
        int.parse(widget.schoolId),
        int.parse(widget.classId),
      );
      setState(() {
        _existingTables = data;
        _filteredTables = data;
      });
    } catch (e) {
      debugPrint("Load Error: $e");
    }

    setState(() => _isLoading = false);
  }

  void _validateTitle(String value) {
    if (value.trim().isEmpty) {
      setState(() => _titleError = null);
      return;
    }
    bool isDuplicate = _existingTables.any(
      (table) =>
          table.examTitle.toLowerCase() == value.trim().toLowerCase() &&
          table.id != _editingId,
    );

    setState(() {
      _titleError = isDuplicate ? "Exam title already exists" : null;
    });
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

  // ================= ADD SUBJECT =================
  void _addExamDialog() {
    final subjectController = TextEditingController();
    DateTime? selectedDate;
    String selectedSession = "FN";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Logic to find occupied dates and sessions (Current form + Other saved exams)
            Map<String, List<String>> occupiedSessionsByDate = {};

            // 1. From current list (local booking)
            for (var item in _examList) {
              final dateStr = item["date"]!;
              final sess = item["session"]!;
              occupiedSessionsByDate.putIfAbsent(dateStr, () => []).add(sess);
            }

            // 2. From other existing tables (global booking for this class)
            for (var table in _existingTables) {
              if (table.id == _editingId) {
                continue; // Skip the one we are currently editing
              }
              final dates = table.date as List;
              final sessions = table.session as List;
              for (int i = 0; i < dates.length; i++) {
                final dStr = dates[i].toString();
                final sStr = sessions[i].toString();
                occupiedSessionsByDate.putIfAbsent(dStr, () => []).add(sStr);
              }
            }

            // Determine if FN/AN is available for selectedDate
            List<String> availableSessions = ["FN", "AN"];
            if (selectedDate != null) {
              final dStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
              if (occupiedSessionsByDate.containsKey(dStr)) {
                final taken = occupiedSessionsByDate[dStr]!;
                availableSessions.removeWhere((s) => taken.contains(s));
              }
            }

            // If selectedSession is not in available, pick first available
            if (!availableSessions.contains(selectedSession) &&
                availableSessions.isNotEmpty) {
              selectedSession = availableSessions[0];
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Add Subject Schedule",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _subjectSuggestions.where((String option) {
                        return option.contains(textEditingValue.text.toUpperCase());
                      });
                    },
                    onSelected: (String selection) {
                      subjectController.text = selection.toUpperCase();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync our controller with Autocomplete's controller
                      controller.addListener(() {
                        subjectController.text = controller.text.toUpperCase();
                      });

                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) {
                          final upperVal = val.toUpperCase();
                          if (val != upperVal) {
                            controller.value = controller.value.copyWith(
                              text: upperVal,
                              selection: TextSelection.collapsed(offset: upperVal.length),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Subject Name",
                          prefixIcon: const Icon(Icons.book_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Date",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                // Find a valid initial date (today or next available)
                                DateTime firstValid =
                                    selectedDate ?? DateTime.now();
                                while (true) {
                                  final dStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(firstValid);
                                  if (occupiedSessionsByDate.containsKey(
                                        dStr,
                                      ) &&
                                      occupiedSessionsByDate[dStr]!.length >=
                                          2) {
                                    firstValid = firstValid.add(
                                      const Duration(days: 1),
                                    );
                                  } else {
                                    break;
                                  }
                                }

                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: firstValid,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  selectableDayPredicate: (DateTime day) {
                                    // Disable date if both FN and AN are occupied
                                    final dStr = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(day);
                                    if (occupiedSessionsByDate.containsKey(
                                      dStr,
                                    )) {
                                      return occupiedSessionsByDate[dStr]!
                                              .length <
                                          2;
                                    }
                                    return true;
                                  },
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: primaryColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setStateDialog(() => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedDate == null
                                          ? "Pick Date"
                                          : DateFormat(
                                            'dd-MM-yyyy',
                                          ).format(selectedDate!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Session",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSession,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items:
                                      availableSessions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setStateDialog(
                                        () => selectedSession = val,
                                      );
                                    }
                                  },
                                  hint: const Text("Select"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (subjectController.text.isNotEmpty &&
                        selectedDate != null) {
                      if (availableSessions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No sessions available for this date",
                            ),
                          ),
                        );
                        return;
                      }

                      // Robust Duplicate Subject Check
                      final subName = subjectController.text.trim();
                      bool isSubDuplicate = _examList.any((item) {
                        final existingSub =
                            (item["subject"] ?? "").trim().toLowerCase();
                        return existingSub == subName.toLowerCase();
                      });

                      if (isSubDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Subject '$subName' already added to this timetable",
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _examList.add({
                          "subject": subName,
                          "date": DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDate!),
                          "session": selectedSession,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Add to List",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= CREATE / UPDATE EXAM =================
  Future<void> _createExam() async {
    final title = _examTitleController.text.trim();
    if (title.isEmpty || _examList.isEmpty || _titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_titleError ?? "Enter title & add subjects")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> subjects =
          _examList.map((e) => e["subject"]!.trim()).toList();
      final List<String> dates = _examList.map((e) => e["date"]!).toList();
      final List<String> sessions =
          _examList.map((e) => e["session"]!).toList();

      // Final check for duplicates in the list (case-insensitive)
      if (subjects.length !=
          subjects.map((s) => s.toLowerCase()).toSet().length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Duplicate subjects found in timetable"),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final exam = ExamTimeTable(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
        examTitle: title.toUpperCase(),
        subjects: subjects.map((s) => s.toUpperCase()).toList(),
        date: dates,
        session: sessions,
        createdBy: widget.username,
      );

      if (_editingId != null) {
        await _service.updateExam(_editingId!, exam.toJson());
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
        }
      } else {
        await _service.createExam(exam);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Created Successfully")));
        }
      }

      setState(() {
        _isCreating = false;
        _editingId = null;
        _examList.clear();
        _examTitleController.clear();
      });

      _loadExistingTimetable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Exam Time Table',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pop(context);
                  },
                )
                : AdminAppbarDesktop(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'Exam Time Table',
                  onBack: () {
                    Navigator.pop(context);
                  },
                ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              _isLoading
                  ? _buildShimmerLoading()
                  : !_isCreating
                  ? _buildExistingView()
                  : _buildCreateView(),
        ),
      ),
      floatingActionButton:
          !_isCreating && !_isLoading
              ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _isCreating = true;
                    _editingId = null;
                    _examTitleController.clear();
                    _examList.clear();
                    _titleError = null;
                  });
                },
                backgroundColor: primaryColor,
                icon: const Icon(Icons.add_task, color: Colors.white),
                label: Text(
                  "Create New",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : null,
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
                return _buildExamCard(exam);
              },
            ),
          ),
      ],
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

  Widget _buildExamCard(ExamTimeTable exam) {
    final subjectCount = (exam.subjects as List).length;

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
          child: ExpansionTile(
            collapsedBackgroundColor: Colors.white,
            backgroundColor: Colors.white,
            tilePadding: const EdgeInsets.symmetric(
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
            title: Text(
              exam.examTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
            subtitle: Text(
              "$subjectCount Subjects • Created by ${exam.createdBy}",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: secondaryColor,
                    size: 20,
                  ),
                  onPressed: () => _editExamTimeTable(exam),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(exam.id!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
            children: [
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

  void _editExamTimeTable(ExamTimeTable exam) {
    setState(() {
      _isCreating = true;
      _editingId = exam.id;
      _examTitleController.text = exam.examTitle;
      _titleError = null;
      _examList.clear();
      for (int i = 0; i < (exam.subjects as List).length; i++) {
        _examList.add({
          "subject": exam.subjects[i],
          "date": exam.date[i],
          "session": exam.session[i],
        });
      }
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Time Table?",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Are you sure you want to remove this exam schedule?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _service.deleteExam(id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Deleted Successfully")),
                      );
                    }
                    _loadExistingTimetable();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCreateView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingId != null
                          ? "Update Time Table"
                          : "Create Time Table",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          () => setState(() {
                            _isCreating = false;
                            _editingId = null;
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _examTitleController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _titleSuggestions.where((String option) {
                      return option.contains(textEditingValue.text.toUpperCase());
                    });
                  },
                  onSelected: (String selection) {
                    _examTitleController.text = selection.toUpperCase();
                    _validateTitle(selection.toUpperCase());
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync our controller with Autocomplete's controller
                    if (controller.text != _examTitleController.text) {
                      controller.text = _examTitleController.text;
                    }
                    controller.addListener(() {
                      if (_examTitleController.text != controller.text) {
                        _examTitleController.text = controller.text.toUpperCase();
                        // Maintain cursor position if needed, but simple sync for now
                      }
                    });

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (val) {
                        final upperVal = val.toUpperCase();
                        if (val != upperVal) {
                          controller.value = controller.value.copyWith(
                            text: upperVal,
                            selection: TextSelection.collapsed(offset: upperVal.length),
                          );
                        }
                        _validateTitle(upperVal);
                      },
                      decoration: InputDecoration(
                        labelText: "Exam Title",
                        hintText: "e.g. I TERM",
                        errorText: _titleError,
                        prefixIcon: Icon(Icons.title, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Subject Schedule",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_examList.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${_examList.length}",
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add Subject"),
                      onPressed: _addExamDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_examList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 50,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No subjects added yet",
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _examList.length,
                    itemBuilder: (context, index) {
                      final exam = _examList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.subject,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam["subject"]!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${exam["date"]} | ${exam["session"]}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed:
                                  () =>
                                      setState(() => _examList.removeAt(index)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _createExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            child: Text(
              _editingId != null
                  ? "Update Exam Time Table"
                  : "Save Exam Time Table",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
