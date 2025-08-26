import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../appbar/administrator_appbar_desktop.dart';
import '../appbar/administrator_appbar_mobile.dart';
import '../widget/mobile_first_page.dart';
import 'dashboard.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({
    super.key,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
    required this.username,
  });

  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;

  @override
  State<FirstPage> createState() => FirstPageState();
}

class FirstPageState extends State<FirstPage> {
  List<dynamic> classes = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> admins = [];
  bool isLoading = true;
  static int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      // fetch class data
      TeacherApiServices.fetchClassData(widget.schoolId).then((class1) {
        if (mounted) setState(() => classes = class1);
      });

      // fetch staff data
      AdminApiService.fetchStaffData(widget.schoolId).then((staff) {
        if (mounted) setState(() => staffs = staff);
      });

      // fetch students
      AdminApiService.fetchAllStudentData(widget.schoolId).then((student) {
        if (mounted) setState(() => students = student);
      });

      // fetch admins
      ApiService.getUsersByRole(
        role: 'admin',
        schoolId: int.parse(widget.schoolId),
      ).then((admin) {
        final filtered =
            admin
                .where(
                  (item) => item["school_id"] == int.parse(widget.schoolId),
                )
                .toList();
        if (mounted) setState(() => admins = filtered);
      });

      // hide loader earlier (UI loads while some data may still be coming)
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("❌ Error loading data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdministratorDashboard(userName: widget.username),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdministratorAppbarMobile(
                    title:
                        '${widget.schoolName.length < 15 ? widget.schoolName : '${widget.schoolName.substring(0, 15)} ...'}\n'
                        '${widget.schoolAddress.length < 15 ? widget.schoolAddress : '${widget.schoolAddress.substring(0, 15)} ...'}',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdministratorDashboard(
                                userName: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : AdministratorAppbarDesktop(
                    title: '${widget.schoolName}\n${widget.schoolAddress}',
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 80.0,
                  ),
                )
                : MobileFirstPage(
                  selectedIndex: selectedIndex,
                  classes: classes,
                  staffs: staffs,
                  students: students,
                  admins: admins,
                  username: widget.username,
                  schoolName: widget.schoolName,
                  schoolAddress: widget.schoolAddress,
                  schoolId: widget.schoolId,
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics, size: 30),
              label: 'Manage',
            ),
          ],
        ),
      ),
    );
  }
}
