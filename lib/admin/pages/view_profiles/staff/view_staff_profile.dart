import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';
import 'staff_profile.dart';

class ViewStaffProfile extends StatefulWidget {
  const ViewStaffProfile({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<ViewStaffProfile> createState() => _ViewStaffProfileState();
}

class _ViewStaffProfileState extends State<ViewStaffProfile> {
  List<Map<String, dynamic>> staffs = [];
  List<Map<String, dynamic>> filteredStaffs = [];
  bool isLoading = true;
  static int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStaffs);
    init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoading) {
      _filterStaffs(); // Apply filter when returning to this page
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    final id = int.tryParse(widget.schoolId);
    if (id == null) return;

    final users = await AdminApiService.fetchStaffData(widget.schoolId);

    // Remove currently logged-in staff
    users.removeWhere(
      (user) =>
          user["username"]?.toString() == widget.username &&
          user["school_id"].toString() == widget.schoolId,
    );

    final converted =
        (users as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    setState(() {
      staffs = converted;
      isLoading = false;
    });

    _filterStaffs(); // Apply initial filter
  }

  void _filterStaffs() {
    final query = _searchController.text.trim().toLowerCase();

    // Filter by search query
    List<Map<String, dynamic>> tempList =
        staffs.where((staff) {
          final username = staff['username']?.toString().toLowerCase() ?? '';
          final name = staff['name']?.toString().toLowerCase() ?? '';
          final mobile = staff['mobile']?.toString().toLowerCase() ?? '';
          final designation =
              staff['designation']?.toString().toLowerCase() ?? '';

          return username.contains(query) ||
              name.contains(query) ||
              mobile.contains(query) ||
              designation.contains(query);
        }).toList();

    // Filter by bottom navigation selection
    if (selectedIndex == 0) {
      // Teaching staff
      tempList =
          tempList
              .where(
                (staff) =>
                    staff['faculty']?.toString().toLowerCase() == 'teaching',
              )
              .toList();
    } else if (selectedIndex == 1) {
      // Non-Teaching staff
      tempList =
          tempList
              .where(
                (staff) =>
                    staff['faculty']?.toString().toLowerCase() == 'nonteaching',
              )
              .toList();
    }

    setState(() {
      filteredStaffs = tempList;
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Staff Profiles',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
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
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Staff Profiles',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.push(
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
                : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by name, mobile, or designation',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          filteredStaffs.isEmpty
                              ? const Center(child: Text('No Staff Found'))
                              : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredStaffs.length,
                                itemBuilder: (context, index) {
                                  final staff = filteredStaffs[index];
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.blue.shade100,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        staff['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mobile: ${staff['mobile'] ?? 'N/A'}',
                                          ),
                                          Text(
                                            'Designation: ${staff['designation'] ?? 'N/A'}',
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => StaffProfile(
                                                  schoolId: widget.schoolId,
                                                  staffName: staff['username'],
                                                  username: widget.username,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() => selectedIndex = index);
            _filterStaffs(); // Apply category filter on tab change
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
