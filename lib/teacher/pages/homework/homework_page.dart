import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
    required this.classId,
    required this.className,
    required this.section,
    super.key,
  });

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  Map<String, dynamic>? staffData = {};
  List<Map<String, dynamic>> homeworkList = [];
  Map<String, dynamic>? selectedHomework;

  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  bool _isFormValid = false;

  int _selectedIndex = 0;
  List<Map<String, dynamic>> filteredHomeworkList = [];

  @override
  void initState() {
    super.initState();
    init();

    _titleController.addListener(_validateForm);
    _subjectController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _titleController.text.isNotEmpty &&
          _subjectController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _dueDate != null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    staffData = await TeacherApiServices.fetchStaffDataUsername(
      username: widget.username,
      schoolId: int.parse(widget.schoolId),
    );

    final staff = staffData!['name'];

    final homeworkData = await TeacherApiServices.fetchHomeworkByStaff(
      staff: staff,
      schoolId: int.parse(widget.schoolId),
      classId: int.parse(widget.classId),
    );

    setState(() {
      homeworkList = homeworkData.cast<Map<String, dynamic>>();
      filteredHomeworkList = homeworkList;
      isLoading = false;
    });
  }

  void applyFilter(String filter) {
    if (filter == "Upcoming") {
      filteredHomeworkList =
          homeworkList.where((hw) {
            final dueDate = DateTime.parse(hw["due_date"]);
            return dueDate.isAfter(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            );
          }).toList();
    } else {
      filteredHomeworkList = homeworkList;
    }
    setState(() {});
  }

  // Capitalize first letter helper
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
      body:
          isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : Container(
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            applyFilter("All");
          } else if (index == 1) {
            applyFilter("Upcoming");
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Upcoming',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHomeworkDialog,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Homework",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 📋 Homework List
  Widget _buildHomeworkList() {
    if (filteredHomeworkList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No homework yet ✏️",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap + to assign new homework",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredHomeworkList.length,
            itemBuilder: (context, index) {
              final hw = filteredHomeworkList[index];
              final dueDate = DateTime.parse(hw["due_date"]);
              final isExpired = dueDate.isBefore(
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
              );

              return Opacity(
                opacity: isExpired ? 0.7 : 1, // faded look for expired
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side:
                        isExpired
                            ? const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            )
                            : BorderSide.none,
                  ),
                  color: isExpired ? Colors.grey.shade100 : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => selectedHomework = hw),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Delete + Expired Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        hw["title"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isExpired) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          "Expired",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(hw),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Chip(
                                label: Text(hw["subject"]),
                                backgroundColor:
                                    isExpired
                                        ? Colors.grey.shade300
                                        : Colors.blue.shade50,
                                labelStyle: TextStyle(
                                  color:
                                      isExpired
                                          ? Colors.grey.shade700
                                          : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "📄 ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["assigned_date"]))}",
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                "📅 ${DateFormat('dd/MM/yyyy').format(dueDate)}",
                                style: TextStyle(
                                  color:
                                      isExpired ? Colors.redAccent : Colors.red,
                                  fontWeight:
                                      isExpired
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
            },
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  // 📄 Homework Detail
  Widget _buildHomeworkDetail() {
    final hw = selectedHomework!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hw["title"],
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "Assigned : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["assigned_date"]))}",
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
                "Due : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["due_date"]))}",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        hw["subject"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    "📖 Description",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hw["description"],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Confirm Delete
  void _confirmDelete(Map<String, dynamic> hw) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Delete Homework ❌"),
            content: Text("Are you sure you want to delete '${hw["title"]}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await TeacherApiServices.deleteHomeworkById(hw["id"]);
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
    _clearForm();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void validateFormDialog() {
              setStateDialog(() {
                _isFormValid =
                    _titleController.text.isNotEmpty &&
                    _subjectController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty &&
                    _dueDate != null;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("✏️ Assign Homework"),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Enter homework title",
                          labelText: "Title",
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "Title required"
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Enter subject name",
                          labelText: "Subject",
                          prefixIcon: Icon(Icons.book),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "Subject required"
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Enter homework description",
                          labelText: "Description below 500 words",
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "Description required"
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            initialDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              _dueDate = picked;
                            });
                            validateFormDialog();
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _isFormValid
                          ? () async {
                            final newHomework = {
                              "school_id": int.parse(widget.schoolId),
                              "class_id": int.parse(widget.classId),
                              "title": _capitalize(
                                _titleController.text.trim(),
                              ),
                              "subject": _capitalize(
                                _subjectController.text.trim(),
                              ),
                              "description": _capitalize(
                                _descriptionController.text.trim(),
                              ),
                              "assigned_date": DateTime.now().toIso8601String(),
                              "due_date": _dueDate!.toIso8601String(),
                              "assigned_by":
                                  staffData?['name'].toString().toLowerCase() ??
                                  widget.username,
                              "attachments": null,
                            };

                            final success =
                                await TeacherApiServices.createHomework(
                                  newHomework,
                                );

                            if (success) {
                              Navigator.pop(context);
                              _clearForm();
                              init();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Homework created"),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ Failed to create homework"),
                                ),
                              );
                            }
                          }
                          : null,
                  child: const Text(
                    "Save",
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

  void _clearForm() {
    _titleController.clear();
    _subjectController.clear();
    _descriptionController.clear();
    _dueDate = null;
  }
}
