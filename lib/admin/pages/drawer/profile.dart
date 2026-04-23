import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';

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
      final data = await AdminApiService.fetchAdminData(
        username: widget.username,
        schoolId: widget.schoolId,
      );
      setState(() {
        adminData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile data")),
      );
    }
  }

  void _navigateToDashboard() {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: SpinKitFoldingCube(color: Colors.blue, size: 40)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? AdminAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'My Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: _navigateToDashboard,
                )
                : AdminAppbarDesktop(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: 'My Profile',
                  onBack: _navigateToDashboard,
                ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildInfoSection(
                        title: "Personal Information",
                        items: [
                          _ProfileTile(
                            icon: Icons.phone_android,
                            label: "Mobile",
                            value: adminData?['mobile'] ?? 'N/A',
                          ),
                          _ProfileTile(
                            icon: Icons.email_outlined,
                            label: "Email Address",
                            value: adminData?['email'] ?? 'N/A',
                          ),
                          _ProfileTile(
                            icon: Icons.wc,
                            label: "Gender",
                            value: _parseGender(adminData?['gender']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        title: "School Details",
                        items: [
                          _ProfileTile(
                            icon: Icons.account_balance,
                            label: "Institution",
                            value: widget.schoolName,
                          ),
                          _ProfileTile(
                            icon: Icons.location_on_outlined,
                            label: "Address",
                            value: widget.schoolAddress,
                          ),
                          _ProfileTile(
                            icon: Icons.badge_outlined,
                            label: "System ID",
                            value: widget.schoolId,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    MemoryImage? profileImg;
    if (adminData?['photo'] != null) {
      profileImg = MemoryImage(base64Decode(adminData!['photo']));
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 64,
            backgroundColor: Colors.white24,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: profileImg,
              child:
                  profileImg == null
                      ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.blue.shade900,
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            adminData?['name'] ?? 'Admin User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            adminData?['designation'] ?? 'Administrator',
            style: TextStyle(color: Colors.blue.shade100, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "@${widget.username}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  String _parseGender(String? code) {
    if (code == 'M') return 'Male';
    if (code == 'F') return 'Female';
    return 'Other';
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade900, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
