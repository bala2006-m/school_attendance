import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/services/homework_api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

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
  List<Map<String, dynamic>> filteredHomeworkList = [];
  Map<String, dynamic>? selectedHomework;

  // Controllers
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  bool _isFormValid = false;

  DateTime? _dueDate;
  File? _image;

  int _selectedIndex = 0;

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

  // ------------------------ INIT ------------------------
  Future<void> init() async {
    staffData = await TeacherApiServices.fetchStaffDataUsername(
      username: widget.username,
      schoolId: int.parse(widget.schoolId),
    );

    final staff = staffData!['name'];

    final homeworkData = await HomeworkApiService.fetchByStaff(
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

  // ------------------------ FILTER ------------------------
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

  // ------------------------ PICK IMAGE ------------------------
  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // ------------------------ CAPITALIZE ------------------------
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ------------------------ BUILD UI ------------------------
  @override
  Widget build(BuildContext context) {
    // final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(190),
        child: MobileAppbar(
          username: widget.username,
          schoolId: widget.schoolId,
          title: 'Homework',
          enableDrawer: false,
          enableBack: true,
          onBack: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => HomeworkClassList(
                      username: widget.username,
                      schoolId: widget.schoolId,
                    ),
              ),
            );
          },
        ),
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

      // ------------------------ BOTTOM NAV ------------------------
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        currentIndex: _selectedIndex,
        onTap: (index) {
          _selectedIndex = index;
          if (index == 0) {
            applyFilter("All");
          } else if (index == 1) {
            applyFilter("Upcoming");
          }
          setState(() {});
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Upcoming',
          ),
        ],
      ),

      // ------------------------ FAB ------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHomeworkDialog,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Homework",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ------------------------ HOMEWORK LIST ------------------------
  Widget _buildHomeworkList() {
    if (filteredHomeworkList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No homework yet ✏️",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              "Tap + to assign new homework",
              style: TextStyle(color: Colors.grey),
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

              return _homeworkCard(hw, isExpired);
            },
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  // ------------------------ HOMEWORK CARD ------------------------
  Widget _homeworkCard(Map<String, dynamic> hw, bool isExpired) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isExpired ? 0.6 : 1,
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => selectedHomework = hw),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------ Title Row ------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.book_outlined,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              hw["title"],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(hw),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ------------------------ Subject Tag ------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hw["subject"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------------ Date Section ------------------------
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Due: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["due_date"]))}",
                    ),
                  ],
                ),

                if (hw.containsKey('attachments') && hw['attachments'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.network(
                      hw['attachments'][0],
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------ DETAILS PAGE ------------------------
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
                "Assigned: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["assigned_date"]))}",
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                "Due: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(hw["due_date"]))}",
              ),
            ],
          ),
          const SizedBox(height: 20),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blue),
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
                  Text(hw["description"]),

                  if (hw['attachments'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Image.network(
                        hw['attachments'][0],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
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
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _confirmDelete(hw),
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------ DELETE CONFIRMATION ------------------------
  void _confirmDelete(Map<String, dynamic> hw) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Homework ❌"),
            content: Text("Delete '${hw["title"]}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await HomeworkApiService.deleteHomework(hw["id"]);
                  setState(() {
                    homeworkList.remove(hw);
                    selectedHomework = null;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  // ------------------------ CREATE HOMEWORK DIALOG ------------------------
  void _showCreateHomeworkDialog() {
    _clearForm();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void validate() {
              setStateDialog(() {
                _isFormValid =
                    _titleController.text.isNotEmpty &&
                    _subjectController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty &&
                    _dueDate != null;
              });
            }

            return AlertDialog(
              title: const Text("✏️ Assign Homework"),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _inputField(_titleController, "Title", Icons.title),
                      const SizedBox(height: 12),
                      _inputField(_subjectController, "Subject", Icons.book),
                      const SizedBox(height: 12),
                      _inputField(
                        _descriptionController,
                        "Description",
                        Icons.description,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => _dueDate = picked);
                            validate();
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _dueDate == null
                              ? "Pick Due Date"
                              : "Due: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}",
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _image == null ? "Pick Image" : "Change Image",
                        ),
                      ),

                      if (_image != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Image.file(_image!, height: 100, width: 100),
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
                                  staffData?['name']
                                      ?.toString()
                                      .toLowerCase() ??
                                  widget.username,
                            };

                            await HomeworkApiService.createHomeworkWithFile(
                              newHomework,
                              _image!,
                              widget.schoolId,
                              widget.classId,
                            );

                            if (mounted) {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              init();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ Homework created"),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("❌ Failed to create"),
                                  ),
                                );
                              }
                            }
                          }
                          : null,
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------ FORM INPUT FIELD ------------------------
  Widget _inputField(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? "$label required" : null,
    );
  }

  // ------------------------ CLEAR FORM ------------------------
  void _clearForm() {
    _titleController.clear();
    _subjectController.clear();
    _descriptionController.clear();
    _dueDate = null;
    _image = null;
  }
}
