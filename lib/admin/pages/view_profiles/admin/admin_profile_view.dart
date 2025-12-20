import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import 'view_admin_profiles.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({
    super.key,
    required this.username,
    required this.schoolId,
    required this.adminName,
  });
  final String adminName;
  final String username;
  final String schoolId;

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  Map<String, dynamic>? admin;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final data = await AdminApiService.fetchAdminData(
      username: widget.adminName,
      schoolId: widget.schoolId,
    );
    if (mounted) {
      setState(() {
        admin = data;
        isLoading = false;
      });
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ViewAdminProfile(
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
                    title: 'Admin Profile',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewAdminProfile(
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
                    title: 'Admin Profile',

                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewAdminProfile(
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
                : admin == null
                ? const Center(child: Text("No profile found"))
                : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile Image
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  admin!['photo'] != null
                                      ? MemoryImage(
                                        base64Decode(admin!['photo']),
                                      )
                                      : null,
                              child:
                                  admin!['photo'] == null
                                      ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 20),

                            // Name
                            Text(
                              admin!['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Designation
                            Text(
                              admin!['designation'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Divider(height: 30),

                            // Details
                            ListTile(
                              leading: const Icon(Icons.badge),
                              title: Text("User ID: ${admin!['username']}"),
                            ),
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text("Mobile: ${admin!['mobile']}"),
                            ),
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: Text("Email: ${admin!['email']}"),
                            ),
                            ListTile(
                              leading: Icon(
                                admin!['gender'] == 'M'
                                    ? Icons.male
                                    : admin!['gender'] == 'F'
                                    ? Icons.female
                                    : Icons.person,
                              ),
                              title: Text(
                                "Gender: ${admin!['gender'] == 'M'
                                    ? 'Male'
                                    : admin!['gender'] == 'F'
                                    ? 'Female'
                                    : ''}",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
