import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import './admin_dashboard.dart';
import './class_attendance.dart';

class ClassWiseAttendance extends StatefulWidget {
  final String schoolId;
  final String username;
  const ClassWiseAttendance({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ClassWiseAttendance> createState() => _ClassWiseAttendanceState();
}

class _ClassWiseAttendanceState extends State<ClassWiseAttendance> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  List<Map<String, dynamic>> classes = [];
  Map<String, bool> attendanceStatusMap = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      await fetchSchoolInfo();
      await fetchClasses();
      await fetchAttendanceStatusForAll();
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      schoolName = schoolData[0]['name'];
      schoolAddress = schoolData[0]['address'];

      if (schoolData[0]['photo'] != null) {
        try {
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          schoolPhoto = Image.memory(imageBytes, gaplessPlayback: true);
        } catch (_) {
          schoolPhoto = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
    }
  }

  Future<void> fetchClasses() async {
    try {
      classes = await TeacherApiServices.fetchClassData(widget.schoolId);
      classes.sort((a, b) {
        int classCompare = a['class'].compareTo(b['class']);
        return classCompare != 0
            ? classCompare
            : a['section'].compareTo(b['section']);
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> fetchAttendanceStatusForAll() async {
    final String schoolId = widget.schoolId;
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    List<Future<void>> futures = [];

    for (var cls in classes) {
      final classId = cls['id'].toString();
      futures.add(
        ApiService.checkAttendanceStatus(schoolId, classId, formattedDate)
            .then((result) {
              attendanceStatusMap[classId] = result == false;
            })
            .catchError((e) {
              debugPrint("Error checking attendance for class $classId: $e");
              attendanceStatusMap[classId] = true;
            }),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      await fetchAttendanceStatusForAll();
      setState(() => isLoading = false);
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
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
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Class Wise Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
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
                  : const AdminAppbarDesktop(title: 'Class Wise Attendance'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (schoolPhoto != null)
                          Container(
                            height: 100,
                            width: 100,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: schoolPhoto,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          schoolName ?? '',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          schoolAddress ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () => _selectDate(context),
                              child: const Text('Select Date'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_box_outline_blank,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text("Not Marked"),
                            SizedBox(width: 20),
                            Icon(Icons.check_box, color: Colors.teal),
                            SizedBox(width: 5),
                            Text("Marked"),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child:
                              classes.isEmpty
                                  ? const Center(
                                    child: Text("No Classes Found"),
                                  )
                                  : GridView.builder(
                                    itemCount: classes.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 1.2,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = classes[index];
                                      final classId = item['id'].toString();
                                      final isMarked =
                                          attendanceStatusMap[classId] ?? true;
                                      final buttonColor =
                                          isMarked ? Colors.white : Colors.teal;
                                      final textColor =
                                          isMarked
                                              ? Colors.black
                                              : Colors.white;
                                      final isClickable = !isMarked;

                                      return GestureDetector(
                                        onTap:
                                            isClickable
                                                ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => ClassAttendance(
                                                            classId: classId,
                                                            schoolId:
                                                                widget.schoolId,
                                                            date: selectedDate,
                                                            username:
                                                                widget.username,
                                                          ),
                                                    ),
                                                  );
                                                }
                                                : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: buttonColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    isClickable
                                                        ? Colors.black12
                                                        : Colors.transparent,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${item['class']} Std",
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  "${item['section']} Sec",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color:
                                                        isMarked
                                                            ? Colors.black54
                                                            : textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
