import 'package:flutter/material.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userData,
    required this.username,
    required this.schoolId,
  });
  final Map<String, dynamic> userData;
  final String username;
  final int schoolId;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    final userData = widget.userData;

    final dob =
        userData['DOB'].toString().isNotEmpty
            ? DateTime.parse(userData["DOB"]).toLocal().toString().split(' ')[0]
            : '';
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  schoolId: widget.schoolId,
                  username: widget.username,
                  title: ' Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : StudentAppbarDesktop(
                  title: ' Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                ),
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
              _buildInfoTile(
                "Gender",
                userData["gender"] == 'M'
                    ? 'Male'
                    : userData["gender"] == 'f'
                    ? 'Female'
                    : userData["gender"] == 'O'
                    ? 'Other'
                    : '',
              ),
              _buildInfoTile("Community", userData["community"] ?? ''),
              _buildInfoTile("Father's Name", userData["father_name"] ?? ''),
              _buildInfoTile("Date of Birth", dob),
              if (userData['address'].toString().isNotEmpty &&
                  userData['address'].toString() != 'null')
                _buildInfoTile("Address", userData['address']),
              if (userData['date_of_join'].toString().isNotEmpty)
                _buildInfoTile(
                  "Date of join",
                  DateTime.parse(
                    userData["date_of_join"],
                  ).toLocal().toString().split(' ')[0],
                ),
              if (userData['route'].toString().isNotEmpty &&
                  userData['route'].toString() != 'null')
                _buildInfoTile("Route", userData["route"] ?? ''),
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
      case "gender":
        return Icons.person;
      case "community":
        return Icons.people;
      case "father's name":
        return Icons.person;
      case "date of birth":
        return Icons.calendar_today;
      case "date of join":
        return Icons.calendar_today_outlined;
      case "Address":
        return Icons.location_city;
      default:
        return Icons.info_outline;
    }
  }
}
