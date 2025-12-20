import 'package:flutter/material.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

class AddExamMarks extends StatefulWidget {
  const AddExamMarks({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
    required this.className,
    required this.section,
    required this.studentUsername,
    required this.onCancel,
    required this.onSaved,
  });

  final String schoolId;
  final String classId;
  final String username;
  final String className;
  final String section;
  final String studentUsername;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<AddExamMarks> createState() => _AddExamMarksState();
}

class _AddExamMarksState extends State<AddExamMarks> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<dynamic> studentMarks = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();
  final TextEditingController overallRankController = TextEditingController();

  final List<_SubjectRow> _subjectRows = [];
  int? selectedMarkId;

  @override
  void initState() {
    super.initState();
    _addSubjectRow();
    init();
  }

  Future<void> init() async {
    try {
      studentMarks = await AdminApiService.fetchExamMarkStudent(
        schoolId: widget.schoolId,
        classId: widget.classId,
        username: widget.studentUsername,
      );
      setState(() {});
    } catch (e) {
      _showSnack('Failed to load exam marks.');
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    minController.dispose();
    maxController.dispose();
    overallRankController.dispose();
    for (final row in _subjectRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addSubjectRow() {
    setState(() => _subjectRows.add(_SubjectRow()));
  }

  void _removeSubjectRow(int index) async {
    if (_subjectRows.length == 1) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Subject'),
            content: const Text(
              'Are you sure you want to remove this subject?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() {
        _subjectRows[index].dispose();
        _subjectRows.removeAt(index);
      });
    }
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) return false;

    final min = int.tryParse(minController.text.trim());
    final max = int.tryParse(maxController.text.trim());
    if (min == null || max == null || min >= max) {
      _showSnack('Please enter valid Min < Max marks.');
      return false;
    }

    for (var i = 0; i < _subjectRows.length; i++) {
      final s = _subjectRows[i];
      final mark = int.tryParse(s.marksController.text.trim());
      final rank = int.tryParse(s.rankController.text.trim());

      if (mark == null || mark < min || mark > max) {
        _showSnack(
          'Marks for "${s.subjectController.text}" must be between $min and $max.',
        );
        return false;
      }
      if (rank == null || rank < 1) {
        _showSnack('Rank for "${s.subjectController.text}" must be ≥ 1.');
        return false;
      }
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_validateInputs()) return;

    final enteredTitle = titleController.text.trim();

    if (selectedMarkId == null &&
        studentMarks.any(
          (mark) =>
              mark['title'].toString().toLowerCase() ==
              enteredTitle.toLowerCase(),
        )) {
      _showSnack('Title already exists.');
      return;
    }

    final min = int.parse(minController.text.trim());
    final max = int.parse(maxController.text.trim());

    final subjects =
        _subjectRows
            .map((s) => s.subjectController.text.trim().toUpperCase())
            .toList();
    final marks =
        _subjectRows.map((s) => s.marksController.text.trim()).toList();
    final ranks =
        _subjectRows
            .map((s) => int.parse(s.rankController.text.trim()))
            .toList();

    setState(() => _isLoading = true);

    try {
      if (selectedMarkId != null) {
        final success = await AdminApiService.updateExamMark(selectedMarkId!, {
          'title': enteredTitle,
          'min_max_marks': [min, max],
          'marks': marks,
          'subjects': subjects,
          'subject_rank': ranks,
          'rank': overallRankController.text.trim(),
          'updated_by': widget.username,
        });
        if (success) {
          _showSnack('Exam mark updated successfully.');
          init();
          widget.onSaved();
          _clearForm();
        } else {
          _showSnack('Failed to update exam mark.');
        }
      } else {
        final success = await AdminApiService.createExamMark(
          schoolId: widget.schoolId,
          classId: widget.classId,
          username: widget.studentUsername,
          title: enteredTitle,
          minMaxMarks: [min, max],
          marks: marks,
          subjects: subjects,
          subjectRank: ranks,
          rank: overallRankController.text.trim(),
          createdBy: widget.username,
          updatedBy: widget.username,
          date: [],
          session: [],
        );
        if (success == 'Success') {
          _showSnack('Exam marks created successfully.');
          init();
          widget.onSaved();
          _clearForm();
        } else {
          _showSnack(success);
        }
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    titleController.clear();
    minController.clear();
    maxController.clear();
    overallRankController.clear();
    for (var row in _subjectRows) {
      row.dispose();
    }
    _subjectRows.clear();
    _addSubjectRow();
    selectedMarkId = null;
  }

  Future<void> _deleteExamMark(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Exam Mark'),
            content: const Text(
              'Are you sure you want to delete this exam mark?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await AdminApiService.deleteExamMark(id);
    setState(() => _isLoading = false);

    if (success) {
      _showSnack('Exam mark deleted successfully.');
      if (mounted) {
        Navigator.pop(context);
      }
      init();
      widget.onSaved();
    } else {
      _showSnack('Failed to delete exam mark.');
    }
  }

  void _showAllMarks() {
    if (studentMarks.isEmpty) {
      _showSnack('No marks to show.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Exam Marks'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Title')),

                  DataColumn(label: Text('Actions')),
                ],
                rows:
                    studentMarks.map((mark) {
                      return DataRow(
                        cells: [
                          DataCell(Text(mark['title'] ?? '')),

                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _editMark(mark);
                                    Navigator.pop(context);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteExamMark(mark['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _editMark(Map mark) {
    setState(() {
      selectedMarkId = mark['id'];
      titleController.text = mark['title'];
      final minMax = mark['min_max_marks'] ?? [];
      if (minMax.length >= 2) {
        minController.text = minMax[0].toString();
        maxController.text = minMax[1].toString();
      }
      overallRankController.text = mark['rank']?.toString() ?? '';
      _subjectRows.clear();
      final subjects = mark['subjects'] ?? [];
      final marks = mark['marks'] ?? [];
      final subjectRanks = mark['subject_rank'] ?? [];

      for (var i = 0; i < subjects.length; i++) {
        final s = _SubjectRow();
        s.subjectController.text = subjects[i];
        s.marksController.text = i < marks.length ? marks[i].toString() : '';
        s.rankController.text =
            i < subjectRanks.length ? subjectRanks[i].toString() : '';
        _subjectRows.add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onCancel,
                      tooltip: 'Back to student list',
                    ),
                    Expanded(
                      child: Text(
                        '${selectedMarkId != null ? "Edit Marks" : "Add Marks"} - ${widget.studentUsername}',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAllMarks,
                      icon: const Icon(Icons.list),
                      label: const Text('Show All'),
                    ),
                  ],
                ),
                const Divider(height: 30),

                _buildField(
                  titleController,
                  'Exam Title',
                  hintText: 'Enter exam title',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        minController,
                        'Min Marks',
                        isNumber: true,
                        hintText: 'e.g. 0',
                        helperText: 'Lowest mark allowed',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        maxController,
                        'Max Marks',
                        isNumber: true,
                        hintText: 'e.g. 100',
                        helperText: 'Highest mark allowed',
                      ),
                    ),
                  ],
                ),
                _buildField(
                  overallRankController,
                  'Overall Rank',
                  isNumber: true,
                  hintText: 'Enter overall rank',
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subjects & Marks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addSubjectRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subject'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subjectRows.length,
                  itemBuilder: (context, index) {
                    final s = _subjectRows[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width:
                                  isMobile
                                      ? MediaQuery.of(context).size.width * 0.6
                                      : 320,
                              child: TextFormField(
                                controller: s.subjectController,
                                decoration: const InputDecoration(
                                  labelText: 'Subject',
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? 90 : 120,
                              child: TextFormField(
                                controller: s.marksController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Marks',
                                  border: const OutlineInputBorder(),
                                  helperText:
                                      minController.text.isNotEmpty
                                          ? "Range: ${minController.text}-${maxController.text}"
                                          : null,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? 80 : 100,
                              child: TextFormField(
                                controller: s.rankController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Rank',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeSubjectRow(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isLoading
                              ? 'Saving...'
                              : (selectedMarkId != null ? 'Update' : 'Submit'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (selectedMarkId != null) const SizedBox(width: 12),
                    if (selectedMarkId != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _clearForm,
                          icon: const Icon(Icons.cancel, color: Colors.white),
                          label: const Text(
                            'Cancel Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label, {
    bool isNumber = false,
    String? hintText,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return '$label is required';
          return null;
        },
      ),
    );
  }
}

class _SubjectRow {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController marksController = TextEditingController();
  final TextEditingController rankController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    marksController.dispose();
    rankController.dispose();
  }
}
