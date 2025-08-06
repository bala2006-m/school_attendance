import 'package:flutter/material.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/export_attendance_to_excel.dart';
import '../widget/attendance_screen.dart';
import 'admin_dashboard.dart';

class ViewStaffAttendance extends StatefulWidget {
  final String school_id;
  final String username;

  const ViewStaffAttendance({
    super.key,
    required this.school_id,
    required this.username,
  });

  @override
  State<ViewStaffAttendance> createState() => _ViewStaffAttendanceState();
}

class _ViewStaffAttendanceState extends State<ViewStaffAttendance> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _attendanceKey = GlobalKey();

  List<Map<String, dynamic>> staff = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> holidayList = [];
  bool isLoading = false;
  bool enableAttendance = false;
  String userName = '';
  String? selectedUsername;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    staff = await AdminApiService.fetchStaffData(widget.school_id);

    staff.sort(
      (a, b) => (a['username'] ?? '').toString().toLowerCase().compareTo(
        (b['username'] ?? '').toString().toLowerCase(),
      ),
    );

    setState(() {});
  }

  Future<void> fetchAttendanceData(String username) async {
    setState(() {
      isLoading = true;
      enableAttendance = false;
      selectedUsername = username;
    });

    try {
      final fetchedAttendance = await ApiService.fetchStaffAttendanceByUsername(
        username,
        widget.school_id,
      );
      final fetchedHolidays = await ApiService.fetchHolidays(widget.school_id);

      setState(() {
        userName = username;
        attendance = fetchedAttendance;
        holidayList = List<Map<String, dynamic>>.from(fetchedHolidays);
        enableAttendance = true;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(
          _attendanceKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch attendance')),
      );
    } finally {
      setState(() {
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
              schoolId: widget.school_id,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'View Staff Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.school_id,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'View Staff Attendance'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Select Staff:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  /// Grid of Staff Cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: staff.length,
                    itemBuilder: (context, index) {
                      final member = staff[index];
                      final username = member['username'] ?? 'Unknown';
                      final mobile = member['mobile'] ?? '';
                      final gender = (member['gender'] ?? '').toString();

                      Color genderColor;
                      switch (gender) {
                        case 'M':
                          genderColor = Colors.lightBlue.shade50;
                          break;
                        case 'F':
                          genderColor = Colors.pink.shade50;
                          break;
                        case 'O':
                          genderColor = Colors.purple.shade50;
                          break;
                        default:
                          genderColor = Colors.grey.shade200;
                      }

                      final isSelected = selectedUsername == username;

                      return Material(
                        color: isSelected ? Colors.blue.shade100 : genderColor,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => fetchAttendanceData(username),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    child: Text(username[0].toUpperCase()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username.toString().length < 11
                                          ? username
                                          : '${username.substring(0, 11)}...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mobile,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  /// Attendance section
                  if (isLoading && !enableAttendance)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    )
                  else if (enableAttendance && attendance.isEmpty)
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              size: 36,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No attendance found',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (enableAttendance && attendance.isNotEmpty)
                    Column(
                      key: _attendanceKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AttendanceScreen(
                          schoolId: widget.school_id,
                          holidayList: holidayList,
                          data: attendance,
                          title: 'Staff Attendance',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download_outlined),
                              label: const Text("Export to Excel"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  () => exportAttendanceToExcel(
                                    context,
                                    attendance,
                                    userName,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
