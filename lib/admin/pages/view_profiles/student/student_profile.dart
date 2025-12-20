import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/view_profiles/student/view_student_profile.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
    required this.className,
    required this.section,
  });

  final String schoolId;
  final String classId;
  final String username;
  final String className;
  final String section;

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  String studentUsername = '';
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedStudent;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  /// Fetch list of students in the class
  Future<void> init() async {
    final studentData = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );
    studentData.sort((a, b) {
      // Gender: Males ('M') first, then Females
      if (a['gender'] == b['gender']) {
        var aUsername = a['username'].toString();
        var bUsername = b['username'].toString();

        // Check if both usernames are numeric
        final numA = int.tryParse(aUsername);
        final numB = int.tryParse(bUsername);

        if (numA != null && numB != null) {
          // Both numeric: compare numerically
          return numA.compareTo(numB);
        } else {
          // Otherwise: compare as strings
          return aUsername.compareTo(bUsername);
        }
      } else if (a['gender'] == 'M') {
        return -1;
      } else {
        return 1;
      }
    });
    if (!mounted) return;
    setState(() {
      students = studentData;
      filteredStudents = studentData;
      isLoading = false;
    });
  }

  /// Search students by name or username
  void filterSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredStudents =
          students.where((s) {
            final name = (s['name'] ?? '').toLowerCase();
            final username = (s['username'] ?? '').toLowerCase();
            return name.contains(searchQuery) || username.contains(searchQuery);
          }).toList();
    });
  }

  /// Fetch details for clicked student
  Future<void> fetchStudentData(
    String schoolId,
    String classId,
    String username,
  ) async {
    int id = int.parse(schoolId);
    final details = await StudentApiServices.fetchStudentDataUsername(
      schoolId: id,
      username: username,
    );

    if (!mounted) return;

    // Convert photo map to Uint8List
    if (details?['photo'] != null && details?['photo'] is Map) {
      final photoBytes = Uint8List.fromList(
        (details?['photo'] as Map).values.cast<int>().toList(),
      );
      details?['photoBytes'] = photoBytes;
    }

    setState(() {
      studentUsername = username;
      selectedStudent = details;
    });
  }

  Future<bool> onWillPop() async {
    if (selectedStudent != null) {
      setState(() {
        selectedStudent = null;
      });
      return false;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ViewStudentProfile(
                schoolId: widget.schoolId,
                username: widget.username,
              ),
        ),
      );
      return false;
    }
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
                    title:
                        selectedStudent == null
                            ? 'Student Profile'
                            : 'Student Details',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      if (selectedStudent != null) {
                        setState(() {
                          selectedStudent = null;
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ViewStudentProfile(
                                  schoolId: widget.schoolId,
                                  username: widget.username,
                                ),
                          ),
                        );
                      }
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title:
                        selectedStudent == null
                            ? 'Student Profile'
                            : 'Student Details',

                    onBack: () {
                      if (selectedStudent != null) {
                        setState(() {
                          selectedStudent = null;
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ViewStudentProfile(
                                  schoolId: widget.schoolId,
                                  username: widget.username,
                                ),
                          ),
                        );
                      }
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
                : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child:
                      selectedStudent == null
                          // ---------- Student List ----------
                          ? Column(
                            children: [
                              // Search Bar
                              TextField(
                                controller: searchController,
                                onChanged: filterSearch,
                                decoration: InputDecoration(
                                  hintText: "Search by name or admn. no",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 800;
                                    return GridView.count(
                                      crossAxisCount: isWide ? 3 : 1,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: isWide ? 2.8 : 3.5,
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      children:
                                          studentsToShow.isEmpty
                                              ? [
                                                Center(
                                                  child: Text(
                                                    "No students found",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                              : studentsToShow.map((s) {
                                                return InkWell(
                                                  onTap: () {
                                                    fetchStudentData(
                                                      widget.schoolId,
                                                      widget.classId,
                                                      s['username'],
                                                    );
                                                  },
                                                  child: Card(
                                                    color:
                                                        s['gender'] == 'F'
                                                            ? Colors.red[50]
                                                            : Colors.blue[50],
                                                    elevation: 3,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            s['gender'] == 'F'
                                                                ? Icons.female
                                                                : Icons.male,
                                                            color:
                                                                s['gender'] ==
                                                                        'F'
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .blue,
                                                            size: 30,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  s['name'] ??
                                                                      '',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color:
                                                                        s['gender'] ==
                                                                                'F'
                                                                            ? Colors.red
                                                                            : Colors.blue,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  s['username'] ??
                                                                      '',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        Colors
                                                                            .grey
                                                                            .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .arrow_forward_ios,
                                                            size: 16,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                          // ---------- Student Details ----------
                          : _buildStudentDetails(),
                ),
      ),
    );
  }

  Widget _buildStudentDetails() {
    return Center(
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              selectedStudent!['photoBytes'] != null &&
                      selectedStudent!['photoBytes'].length > 5
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.memory(
                      selectedStudent!['photoBytes'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.person, size: 60),
                  ),
              const SizedBox(height: 16),
              Text(
                selectedStudent!['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              _infoRow("Admn. No", studentUsername),
              _infoRow("Email", selectedStudent!['email'] ?? ''),
              _infoRow("Mobile", selectedStudent!['mobile'] ?? ''),
              _infoRow("Gender", selectedStudent!['gender'] ?? ''),
              Row(
                children: [
                  _infoRow("Class", widget.className),
                  Spacer(),
                  _infoRow("Section", widget.section),
                ],
              ),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedStudent = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to List"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title : ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),

          Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            //textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
