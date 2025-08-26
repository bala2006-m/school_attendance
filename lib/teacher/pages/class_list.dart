import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/mobile_appbar.dart';
import '../widget/desktop_class_list.dart';
import '../widget/mobile_class_list.dart';

class ClassList extends StatefulWidget {
  final String schoolId;
  final String username;
  const ClassList({super.key, required this.schoolId, required this.username});

  @override
  State<ClassList> createState() => _ClassListState();
}

class _ClassListState extends State<ClassList> {
  List<dynamic> classList = [];
  bool isLoading = true;
  Map<String, bool> attendanceStatusMapFn = {};
  Map<String, bool> attendanceStatusMapAn = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> fetchAttendanceStatusForAll() async {
    final today = DateTime.now();
    final currentDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await Future.wait(
      classList.map((cls) async {
        final classId = cls['id'].toString();
        final result = await ApiService.checkAttendanceStatusSession(
          widget.schoolId,
          classId,
          currentDate,
          'FN',
        );

        setState(() {
          attendanceStatusMapFn[classId] = result ?? false;
        });
      }),
    );
    await Future.wait(
      classList.map((cls) async {
        final classId = cls['id'].toString();
        final result = await ApiService.checkAttendanceStatusSession(
          widget.schoolId,
          classId,
          currentDate,
          'AN',
        );

        setState(() {
          attendanceStatusMapAn[classId] = result ?? false;
        });
      }),
    );
  }

  Future<void> init() async {
    final fetchedClassList = await TeacherApiServices.fetchClassData(
      widget.schoolId,
    );

    setState(() {
      classList = fetchedClassList;

      isLoading = false;
    });
    fetchAttendanceStatusForAll();
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
                  title: 'Class List',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StaffDashboardState.selectedIndex = 0;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StaffDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Class List'),
      ),
      body:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopClassList(
                classList: classList,
                schoolId: widget.schoolId,
                isLoading: isLoading,
                username: widget.username,
              )
              : MobileClassList(
                attendanceStatusMapFN: attendanceStatusMapFn,
                attendanceStatusMapAN: attendanceStatusMapAn,
                username: widget.username,
                classList: classList,
                schoolId: widget.schoolId,
                isLoading: isLoading,
              ),
    );
  }
}
