import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/attendance_screen.dart';
import '../dashboard/admin_dashboard.dart';

class ViewStaffAttendance extends StatefulWidget {
  final String schoolId;
  final String username;

  const ViewStaffAttendance({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ViewStaffAttendance> createState() => _ViewStaffAttendanceState();
}

class _ViewStaffAttendanceState extends State<ViewStaffAttendance> {
  static int selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _attendanceKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> staff = [];
  List<Map<String, dynamic>> filteredStaff = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> holidayList = [];

  bool isLoading = false;
  bool enableAttendance = false;
  String? selectedUsername;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _initStaff();
  }

  Future<void> _initStaff() async {
    staff = await AdminApiService.fetchStaffData(widget.schoolId);

    staff.sort(
      (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
        (b['name'] ?? '').toString().toLowerCase(),
      ),
    );

    setState(() {
      filteredStaff = staff;
    });
  }

  void _filterStaff(String query) {
    setState(() {
      filteredStaff =
          query.isEmpty
              ? staff
              : staff.where((member) {
                final name = (member['name'] ?? '').toString().toLowerCase();
                final mobile =
                    (member['mobile'] ?? '').toString().toLowerCase();
                final search = query.toLowerCase();
                return name.contains(search) || mobile.contains(search);
              }).toList();
    });
  }

  Future<void> _fetchAttendance(String username) async {
    setState(() {
      isLoading = true;
      enableAttendance = false;
      selectedUsername = username;
    });

    try {
      final fetchedAttendance = await ApiService.fetchStaffAttendanceByUsername(
        username,
        widget.schoolId,
      );
      final fetchedHolidays = await ApiService.fetchHolidays(widget.schoolId);

      setState(() {
        attendance = fetchedAttendance;
        holidayList = List<Map<String, dynamic>>.from(fetchedHolidays);
        enableAttendance = true;
        userName = username;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_attendanceKey.currentContext != null) {
          Scrollable.ensureVisible(
            _attendanceKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch attendance')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
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

    // Filter staff per tab
    final displayedStaff =
        filteredStaff.where((s) {
          return selectedIndex == 0
              ? s['faculty'] == 'teaching'
              : selectedIndex == 1
              ? s['faculty'] == 'nonteaching'
              : true;
        }).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Attendance',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  ),
        ),
        body: SingleChildScrollView(
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

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by name or mobile",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _filterStaff,
              ),
              const SizedBox(height: 20),

              // Grid of Staff Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4,
                ),
                itemCount: displayedStaff.length,
                itemBuilder: (context, index) {
                  final member = displayedStaff[index];
                  final name = member['name'] ?? 'Unknown';
                  final username = member['username'] ?? 'Unknown';
                  final gender = (member['gender'] ?? '').toString();
                  final designation = member['designation'] ?? 'Designation';
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
                      onTap: () => _fetchAttendance(username),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              child: Text(name[0].toUpperCase()),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name.length < 16
                                      ? name
                                      : '${name.substring(0, 16)}...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  designation,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Attendance Section
              if (isLoading && !enableAttendance)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
              else if (enableAttendance && attendance.isEmpty)
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: const [
                        Icon(Icons.info_outline, size: 36, color: Colors.grey),
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
                      schoolId: widget.schoolId,
                      holidayList: holidayList,
                      data: attendance,
                      title: 'Staff Attendance',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              label: 'Teaching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 30),
              label: 'Non Teaching',
            ),
          ],
        ),
      ),
    );
  }
}
