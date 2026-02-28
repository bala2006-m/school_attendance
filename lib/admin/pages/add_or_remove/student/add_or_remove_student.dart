import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../widget/student_registration_desktop.dart';
import '../../../widget/student_registration_mobile.dart';
import 'add_or_remove_class_list.dart';

class StudentRegistration extends StatefulWidget {
  final String schoolId;
  final String username;
  final String classId;
  final String section;
  final String className;

  const StudentRegistration({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
    required this.section,
    required this.className,
  });

  @override
  State<StudentRegistration> createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final GlobalKey _formKey = GlobalKey();
  List<Map<String, dynamic>> studentData = [];
  bool isLoading = true;
  bool showForm = false;
  final ScrollController _scrollController = ScrollController();
  String searchQuery = "";

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddOrRemoveClassList(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    studentData.clear();
    studentData = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredStudents {
    if (searchQuery.isEmpty) return studentData;
    return studentData.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final username = (student['username'] ?? '').toString().toLowerCase();
      final mobile = (student['mobile'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) ||
          username.contains(query) ||
          mobile.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> sortedGroupedStudents(
    List<Map<String, dynamic>> students,
  ) {
    int usernameComparator(a, b) {
      // Sort numbers as numbers, strings lexicographically
      final aStr = a['username'].toString();
      final bStr = b['username'].toString();
      final aNum = num.tryParse(aStr);
      final bNum = num.tryParse(bStr);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      } else {
        return aStr.compareTo(bStr);
      }
    }

    // Group by gender
    final males =
        students
            .where((s) => (s['gender'] ?? '').toUpperCase() == 'M')
            .toList();
    final females =
        students
            .where((s) => (s['gender'] ?? '').toUpperCase() == 'F')
            .toList();

    // Sort each group by username
    males.sort(usernameComparator);
    females.sort(usernameComparator);

    // Concatenate, males first
    return [...males, ...females];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final studentsToShow = sortedGroupedStudents(filteredStudents);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Student',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Student',
                    onBack: () {
                      onWillPop();
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
                : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (showForm)
                      Column(
                        children: [
                          SizedBox(key: _formKey, height: 10),
                          isMobile
                              ? StudentRegistrationMobile(
                                classId: widget.classId,
                                username: widget.username,
                                schoolId: widget.schoolId,
                                onRegistered: () async {
                                  await init();
                                  if (!mounted) return;
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Student Registered'),
                                      ),
                                    );
                                  }
                                },
                              )
                              : StudentRegistrationDesktop(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Class : ${widget.className}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Section : ${widget.section}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search by name, admn. no, or mobile",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Registered Students',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Total : ${studentsToShow.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Student List
                    ...studentsToShow.map((student) {
                      final username = (student['username'] ?? '').toString();
                      final gender =
                          (student['gender'].toString().toUpperCase())
                              .toString();
                      final name =
                          (student['name'] ?? 'Name not available').toString();
                      final mobile = (student['mobile'] ?? 'N/A').toString();
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              gender == 'M'
                                  ? Icons.male
                                  : gender == 'F'
                                  ? Icons.female
                                  : Icons.person,
                              color:
                                  gender == 'M'
                                      ? Colors.blue
                                      : gender == 'F'
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  gender == 'M'
                                      ? Colors.blue
                                      : gender == 'F'
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admn. No: $username'),
                              Text('Mobile: $mobile'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🚪 LEFT STUDENT BUTTON
                              IconButton(
                                icon: const Icon(
                                  Icons.person_off,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Mark as Left',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Student Left'),
                                          content: Text(
                                            'Do you want to mark this student as left?\n\n'
                                            'Name: $name\n'
                                            'Class: ${widget.className}\n'
                                            'Username: $username',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    final success =
                                        await ApiService.markStudentLeft(
                                          schoolId: int.parse(widget.schoolId),
                                          classId: int.parse(
                                            widget.classId,
                                          ), // ✅ convert here
                                          username: username,
                                        );

                                    if (!mounted) return;

                                    if (success) {
                                      await init();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '$name marked as left',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to update student status',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),

                              // ❌ DELETE BUTTON (your existing one)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Delete Student'),
                                          content: Text(
                                            'Are you sure you want to delete "$username"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    int id = int.parse(widget.schoolId);
                                    final success = await ApiService.deleteUser(
                                      username: username,
                                      role: 'student',
                                      schoolId: id,
                                    );
                                    if (!mounted) return;
                                    if (success) {
                                      await init();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Deleted $username'),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete $username\n$username is used in other services',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 90),
                    const Divider(),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed: () {
            setState(() {
              showForm = !showForm;
            });
            if (showForm) {
              // Smooth scroll to top when form is shown
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
          child:
              showForm
                  ? Icon(Icons.close, size: 30, color: Colors.blue.shade900)
                  : Icon(Icons.add, size: 30, color: Colors.blue.shade900),
        ),
      ),
    );
  }
}
