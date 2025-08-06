import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../student/services/student_api_services.dart';
import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../models/staff_models.dart';
import '../services/teacher_api_service.dart';

class StaffProfileScreen extends StatefulWidget {
  final String username;
  const StaffProfileScreen({super.key, required this.username});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  late Future<Staff> _staffFuture;
  Map<String, dynamic>? schoolData;

  @override
  void initState() {
    super.initState();
    _staffFuture = TeacherApiServices.fetchProfile(widget.username);
    init();
  }

  Future<void> init() async {
    try {
      final staff = await _staffFuture;
      final schoolResult = await StudentApiServices.fetchSchoolData(
        '${staff.schoolId}',
      );

      setState(() {
        schoolData = (schoolResult.isNotEmpty) ? schoolResult[0] : null;
      });
    } catch (e) {
      print("Error loading school data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopAppbar(title: 'MY Profile')
              : MobileAppbar(title: 'MY Profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: FutureBuilder<Staff>(
            future: _staffFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final staff = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Staff Details',
                      icon: Icons.person,
                      fields: [
                        _buildField('Username', staff.username),
                        _buildField('Name', staff.name),
                        _buildField('Email', staff.email),
                        _buildField('Mobile', staff.mobile),
                        _buildField('Designation', staff.designation),
                        _buildField('Gender', staff.gender),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'School Info',
                      icon: Icons.school,
                      fields: [
                        _buildField(
                          'Name',
                          schoolData?['name'] ?? 'Loading...',
                        ),
                        _buildField(
                          'Address',
                          schoolData?['address'] ?? 'Loading...',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> fields,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
