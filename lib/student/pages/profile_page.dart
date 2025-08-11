import 'package:flutter/material.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userData, required this.username});
  final Map<String, dynamic> userData;
  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    final userData = widget.userData;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
        isMobile
            ? StudentAppbarMobile(
          title: 'Student Attendance', enableDrawer: false,enableBack: true,onBack: () {
          StudentDashboardState.selectedIndex = 1;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StudentDashboard(
                username: widget.username,
              ),
            ),
          );
        },

        )
            : const StudentAppbarDesktop(title: 'Student Attendance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            children: [
              userData["photo"] != null && userData["photo"].isNotEmpty
                  ? CircleAvatar(
                    radius: 40,
                    backgroundImage: MemoryImage(userData["photo"]),
                  )
                  : const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.indigo),
                  ),
              const SizedBox(height: 12),
              Text(
                userData["name"] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userData["role"] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _buildInfoTile("Roll Number", userData["rollNumber"] ?? ''),
              _buildInfoTile("Class Name", userData['className']),
              _buildInfoTile("School Name", userData['schoolName']),
              _buildInfoTile("Email", userData["email"] ?? ''),
              _buildInfoTile("Phone", userData["phone"] ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(_getIcon(title), color: Colors.indigo),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  IconData _getIcon(String label) {
    switch (label.toLowerCase()) {
      case "email":
        return Icons.email;
      case "phone":
        return Icons.phone;
      case "school name":
        return Icons.school;
      case "class name":
        return Icons.class_;
      case "roll number":
        return Icons.badge;
      default:
        return Icons.info_outline;
    }
  }
}
