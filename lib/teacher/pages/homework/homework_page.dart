import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../appbar/desktop_appbar.dart';
import '../../appbar/mobile_appbar.dart';
import 'homework_class_list.dart';

class HomeworkPage extends StatefulWidget {
  final String username;
  final String schoolId;
  final String classId;
  final String className;
  final String section;
  const HomeworkPage({
    required this.username,
    required this.schoolId,
    super.key,
    required this.classId,
    required this.className,
    required this.section,
  });

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<dynamic> homeworkList = [];
  Map<String, dynamic>? selectedHomework;

  final _titleController = TextEditingController();
  DateTime? _dueDate;

  // dynamic subject-description controllers
  final List<TextEditingController> _subjectControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final homeworkData = await TeacherApiServices.fetchHomeworkByStaff(
      staff: 'bala',
      schoolId: int.parse(widget.schoolId),
      classId: int.parse(widget.classId),
    );
    print(homeworkData);
    setState(() {
      homeworkList = homeworkData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Homework',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HomeworkClassList(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Homework'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            selectedHomework != null
                ? _buildHomeworkDetail()
                : _buildHomeworkList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Homework"),
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showCreateHomeworkDialog(),
      ),
    );
  }

  // 📋 Homework List
  Widget _buildHomeworkList() {
    if (homeworkList.isEmpty) {
      return const Center(
        child: Text(
          "No homework assigned yet ✏️",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homeworkList.length,
      itemBuilder: (context, index) {
        final hw = homeworkList[index];
        final DateTime assignedDate = DateTime.parse(hw['assigned_date']);
        final DateTime dueDate = DateTime.parse(hw['due_date']);
        final subjects =
            '${hw['subject'][0].toString().toUpperCase()}${hw['subject'].substring(1)}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              '${hw['title'][0].toString().toUpperCase()}${hw['title'].substring(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Subjects: $subjects",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "📄 Assigned : ${DateFormat('dd/MM/yyyy').format(assignedDate)}",
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  "📅 Due : ${DateFormat('dd/MM/yyyy').format(dueDate)}",
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(hw),
            ),
            onTap: () => setState(() => selectedHomework = hw),
          ),
        );
      },
    );
  }

  // 📄 Homework Detail
  Widget _buildHomeworkDetail() {
    final hw = selectedHomework!;
    final DateTime assignedDate = DateTime.parse(hw['assigned_date']);
    final DateTime dueDate = DateTime.parse(hw['due_date']);
    final subjects =
        '${hw['subject'][0].toString().toUpperCase()}${hw['subject'].substring(1)}';
    final description =
        '${hw['description'][0].toString().toUpperCase()}${hw['description'].substring(1)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hw['title'][0].toString().toUpperCase()}${hw['title'].substring(1)}',

            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Assigned & Due Dates
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "Assigned Date : ${DateFormat('dd/MM/yyyy').format(assignedDate)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                "Due Date : ${DateFormat('dd/MM/yyyy').format(dueDate)}",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: const Icon(Icons.book, size: 16),
                  label: Text(
                    subjects,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(height: 10),
                const Text(
                  "📖 Description",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => selectedHomework = null),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  "Back",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _confirmDelete(hw),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Confirm Delete
  void _confirmDelete(hw) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Delete Homework ❌"),
            content: Text("Are you sure you want to delete '${hw.title}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    homeworkList.remove(hw);
                    selectedHomework = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  // ➕ Create Homework
  void _showCreateHomeworkDialog() {
    _subjectControllers.clear();
    _descriptionControllers.clear();
    _addTaskField(); // add first pair by default

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("✏️ Assign Homework"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(_subjectControllers.length, (
                        index,
                      ) {
                        return Column(
                          children: [
                            TextField(
                              controller: _subjectControllers[index],
                              decoration: InputDecoration(
                                labelText: "Subject ${index + 1}",
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _descriptionControllers[index],
                              decoration: InputDecoration(
                                labelText: "Description ${index + 1}",
                              ),
                              maxLines: 2,
                            ),
                            const Divider(),
                          ],
                        );
                      }),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setStateDialog(() => _addTaskField());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add another subject"),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      label: Text(
                        _dueDate == null
                            ? "Pick Due Date"
                            : "Due: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}",
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {},
              // onPressed: () {
              //   if (_titleController.text.isNotEmpty &&
              //       _dueDate != null &&
              //       _subjectControllers.isNotEmpty) {
              //     final tasks = List.generate(
              //       _subjectControllers.length,
              //       (i) => HomeworkTask(
              //         subject: _subjectControllers[i].text,
              //         description: _descriptionControllers[i].text,
              //       ),
              //     );
              //
              //     setState(() {
              //       // homeworkList.add(
              //       //   Homework(
              //       //     id: DateTime.now().millisecondsSinceEpoch.toString(),
              //       //     schoolId: widget.schoolId,
              //       //     classId: "-",
              //       //     title: _titleController.text,
              //       //     assignedDate: DateTime.now(),
              //       //     dueDate: _dueDate!,
              //       //     assignedBy: widget.username,
              //       //     tasks: tasks,
              //       //   ),
              //       // );
              //     });
              //     Navigator.pop(context);
              //     _clearForm();
              //   }
              // },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _addTaskField() {
    _subjectControllers.add(TextEditingController());
    _descriptionControllers.add(TextEditingController());
  }

  void _clearForm() {
    _titleController.clear();
    _dueDate = null;
    _subjectControllers.clear();
    _descriptionControllers.clear();
  }
}
I/flutter ( 9836): [{id: 1, school_id: 2, class_id: 1, title: assignment, subject: tamil, description: do, assigned_date: 2025-08-31T00:00:00.000Z, due_date: 2025-09-01T00:00:00.000Z, assigned_by: bala, attachments: null}]
