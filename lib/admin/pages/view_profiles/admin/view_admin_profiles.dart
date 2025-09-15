import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';
import 'admin_profile_view.dart';

class ViewAdminProfile extends StatefulWidget {
  const ViewAdminProfile({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<ViewAdminProfile> createState() => _ViewAdminProfileState();
}

class _ViewAdminProfileState extends State<ViewAdminProfile> {
  List<Map<String, dynamic>> admins = [];
  List<Map<String, dynamic>> filteredAdmins = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
    _searchController.addListener(_filterAdmins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    final id = int.tryParse(widget.schoolId);
    if (id == null) return;

    final users = await AdminApiService.fetchAllAdmin(
      schoolId: widget.schoolId,
    );
    final converted =
        (users as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    setState(() {
      admins =
          converted.where((admin) {
            return admin['username']?.toString() != widget.username;
          }).toList();

      filteredAdmins = List<Map<String, dynamic>>.from(admins);
      isLoading = false;
    });
  }

  void _filterAdmins() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredAdmins = admins);
    } else {
      setState(() {
        filteredAdmins =
            admins.where((admin) {
              final name = admin['name']?.toString().toLowerCase() ?? '';
              final mobile = admin['mobile']?.toString().toLowerCase() ?? '';
              final designation =
                  admin['designation']?.toString().toLowerCase() ?? '';
              return name.contains(query) ||
                  mobile.contains(query) ||
                  designation.contains(query);
            }).toList();
      });
    }
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
                    title: 'Admin Profiles',
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
                    title: 'Admin Profiles',

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
                    // ✅ Search bar
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
                          filteredAdmins.isEmpty
                              ? const Center(child: Text('No Admins Found'))
                              : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredAdmins.length,
                                itemBuilder: (context, index) {
                                  final admin = filteredAdmins[index];
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
                                        admin['name'] ?? 'Unknown',
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
                                            'Mobile: ${admin['mobile'] ?? 'N/A'}',
                                          ),
                                          Text(
                                            'Designation: ${admin['designation'] ?? 'N/A'}',
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
                                                (_) => AdminProfile(
                                                  schoolId:
                                                      '${admin['school_id']}',
                                                  adminName: admin['username'],
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
      ),
    );
  }
}
