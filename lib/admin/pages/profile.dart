import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class Profile extends StatefulWidget {
  final String username;
  final String schoolId;
  final String schoolName;
  final String schoolAddress;

  const Profile({
    super.key,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String adminName = '';
  String adminMobileNumber = '';
  String adminDesignation = '';
  String adminEmail = '';
  String adminGender = '';
  Image? adminPhoto;
  Map<String, dynamic>? adminData;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    initializeInitialData();
  }

  Future<void> initializeInitialData() async {
    try {
      setState(() => _isLoading = true);
      adminData = await AdminApiService.fetchAdminData(
        username: widget.username,
        schoolId: widget.schoolId,
      );
      setState(() {
        adminName = adminData?['name'] ?? '';
        adminMobileNumber = adminData?['mobile'] ?? '';
        adminDesignation = adminData?['designation'] ?? '';
        adminEmail = adminData?['email'];
        adminGender = adminData?['gender'];
        if (adminData?['photo'] != null) {
          adminPhoto = Image.memory(base64Decode(adminData!['photo']));
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Initial load failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'My Profile',
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
                : const AdminAppbarDesktop(title: 'My Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: adminPhoto?.image,
                    child:
                        adminPhoto == null
                            ? const Icon(Icons.person, size: 65)
                            : null,
                  ),

                  const SizedBox(height: 20),
                  Text(
                    adminName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.username}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    adminDesignation,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  _buildProfileDetailRow(Icons.phone, adminMobileNumber),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(Icons.email, adminEmail),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(
                    Icons.person,
                    adminGender == 'M'
                        ? 'Male'
                        : adminGender == 'F'
                        ? 'Female'
                        : 'Other',
                  ),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(Icons.school, widget.schoolName),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(
                    Icons.location_on,
                    widget.schoolAddress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade900, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
        ),
      ],
    );
  }
}
