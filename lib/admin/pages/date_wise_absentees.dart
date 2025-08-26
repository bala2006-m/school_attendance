import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/class_grid_view.dart';
import '../services/sttendance_helper.dart';
import 'admin_dashboard.dart';
import 'date_absent.dart';

class DateWiseAbsentees extends StatefulWidget {
  final String schoolId;
  final String username;
  const DateWiseAbsentees({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<DateWiseAbsentees> createState() => _DateWiseAbsenteesState();
}

class _DateWiseAbsenteesState extends State<DateWiseAbsentees> {
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
    final info = await AttendanceHelper.fetchSchoolInfo(widget.schoolId);
    final classList = await AttendanceHelper.fetchClasses(widget.schoolId);
    final statusMap = await AttendanceHelper.fetchAttendanceStatusMap(
      widget.schoolId,
      selectedDate,
      classList,
    );

    setState(() {
      schoolName = info['name'];
      schoolAddress = info['address'];
      schoolPhoto = info['image'];
      classes = classList;
      attendanceStatusMap = statusMap;
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      final statusMap = await AttendanceHelper.fetchAttendanceStatusMap(
        widget.schoolId,
        picked,
        classes,
      );
      setState(() {
        selectedDate = picked;
        attendanceStatusMap = statusMap;
        isLoading = false;
      });
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
      return const Scaffold(
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
          preferredSize: const Size.fromHeight(60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Date wise Absentees',
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
                  : const AdminAppbarDesktop(title: 'Date wise Absentees'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (schoolPhoto != null)
                Container(height: 100, width: 100, child: schoolPhoto),
              const SizedBox(height: 10),
              Text(
                schoolName ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                schoolAddress ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text("Select Date"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ClassGridView(
                  classes: classes,
                  attendanceStatusMap: attendanceStatusMap,
                  onClassTap: (item) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DateAbsent(
                              username: widget.username,
                              date: DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate),
                              className: item['class'],
                              section: item['section'],
                              classId: item['id'].toString(),
                              schoolId: widget.schoolId,
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
    );
  }
}
