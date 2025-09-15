import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/view_profiles/staff/view_staff_profile.dart';

import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';

class StaffProfile extends StatefulWidget {
  const StaffProfile({
    super.key,
    required this.username,
    required this.schoolId,
    required this.staffName,
  });

  final String username;
  final String schoolId;
  final String staffName;

  @override
  State<StaffProfile> createState() => _StaffProfileState();
}

class _StaffProfileState extends State<StaffProfile> {
  Map<String, dynamic>? staff;
  bool isLoading = true;
  Uint8List? profileImageBytes;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      int id = int.parse(widget.schoolId);
      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.staffName,
        schoolId: id,
      );
      //print(data);

      if (mounted) {
        setState(() {
          staff = data;
          isLoading = false;

          if (staff?['photo'] != null) {
            final photoData = staff!['photo'];
            if (photoData is String) {
              // API returned Base64 string
              profileImageBytes = base64Decode(photoData);
            } else if (photoData is Map) {
              // API returned raw bytes map {0:255, 1:216, ...}
              profileImageBytes = Uint8List.fromList(
                photoData.values.cast<int>().toList(),
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching staff profile: $e");
      if (mounted) {
        setState(() {
          staff = null;
          isLoading = false;
        });
      }
    }
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ViewStaffProfile(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Widget buildInfoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon),
      title: Text("$label: ${value ?? 'N/A'}"),
    );
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
                    title: 'Staff Profile',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewStaffProfile(
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
                    title: 'Staff Profile',

                    onBack: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewStaffProfile(
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
                : staff == null
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
                                  profileImageBytes != null
                                      ? MemoryImage(profileImageBytes!)
                                      : null,
                              child:
                                  profileImageBytes == null
                                      ? Text(
                                        staff?['name'] != null
                                            ? staff!['name'][0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.grey,
                                        ),
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 20),

                            // Name
                            Text(
                              staff?['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Designation
                            Text(
                              staff?['designation'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Divider(height: 30),

                            // Details
                            buildInfoTile(
                              Icons.badge,
                              "Username",
                              widget.staffName,
                            ),
                            buildInfoTile(
                              Icons.phone,
                              "Mobile",
                              staff?['mobile'],
                            ),
                            buildInfoTile(
                              Icons.email,
                              "Email",
                              staff?['email'],
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
