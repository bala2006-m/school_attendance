import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../widget/student_registration_desktop.dart';
import '../widget/student_registration_mobile.dart';
import 'admin_dashboard.dart';

class StudentRegistration extends StatefulWidget {
  final String schoolId;
  final String username;

  const StudentRegistration({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentRegistration> createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final GlobalKey _formKey = GlobalKey();
  final GlobalKey _formKey1 = GlobalKey();

  List<dynamic> student = [];
  Map<String, dynamic> studentData = {};
  bool isLoading = true;
  bool showForm = false;
  int _selectedIndex = 0;

  String searchQuery = "";

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
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
    student = await ApiService.getUsersByRole(
      role: 'student',
      schoolId: int.parse(widget.schoolId),
    );
    student =
        student
            .where((e) => e["school_id"] == int.parse(widget.schoolId))
            .toList();
    studentData.clear();
    List<Future<void>> futures = [];

    for (var user in student) {
      final username = user['username'];
      futures.add(
        StudentApiServices.fetchStudentDataUsername(
          username: username,
          schoolId: int.parse(widget.schoolId),
        ).then((data) {
          studentData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // filter students based on search query
    final filteredStudents =
        student.where((adminUser) {
          final username = adminUser['username'].toString().toLowerCase();
          final data = studentData[username] ?? {};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final mobile = (data['mobile'] ?? '').toString().toLowerCase();

          return username.contains(searchQuery.toLowerCase()) ||
              name.contains(searchQuery.toLowerCase()) ||
              mobile.contains(searchQuery.toLowerCase());
        }).toList();

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Student',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Add Or Remove Student'),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (showForm)
                      Column(
                        children: [
                          SizedBox(key: _formKey, height: 10),
                          isMobile
                              ? StudentRegistrationMobile(
                                username: widget.username,
                                schoolId: widget.schoolId,
                                onRegistered: () async {
                                  await init();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Student Registered'),
                                    ),
                                  );
                                },
                              )
                              : StudentRegistrationDesktop(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // 🔍 Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search by name, username, or mobile",
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
                          'Total : ${filteredStudents.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // student list
                    ...filteredStudents.map((adminUser) {
                      final username = adminUser['username'];
                      final data = studentData[username] ?? {};
                      final name = data['name'] ?? 'Name not available';
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
                          leading: CircleAvatar(child: Text(name[0])),
                          title: Text(
                            data['name'] ?? 'Name not available',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username: $username'),
                              Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted $username'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete $username\n$username is used in other services',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed: () {
            setState(() {
              showForm = !showForm;
            });
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
