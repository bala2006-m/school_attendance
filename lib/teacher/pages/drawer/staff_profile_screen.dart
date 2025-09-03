import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../student/services/student_api_services.dart';
import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../services/teacher_api_service.dart';

class StaffProfileScreen extends StatefulWidget {
  final String username;
  final int schoolId;
  const StaffProfileScreen({
    super.key,
    required this.username,
    required this.schoolId,
  });

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  String username = '';
  String name = '';
  String email = '';
  String mobile = '';
  String designation = '';
  String gender = '';
  Map<String, dynamic>? schoolData;
  Uint8List? profilePhoto;
  bool _isLoading = false;
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      _isLoading = true;

      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.username,
        schoolId: widget.schoolId,
      );

      final fetchedClasses = <Map<String, dynamic>>[];
      if (data?['class_ids'].toString() != 'null') {
        for (final id in data?['class_ids']) {
          final classData = await StudentApiServices.fetchClassDatas(
            '${data?['school_id']}',
            '$id',
          );
          if (classData != null) {
            fetchedClasses.add(classData);
          }
        }

        setState(() {
          classes = fetchedClasses;
        });
      }
      final schoolResult = await StudentApiServices.fetchSchoolData(
        '${data?['school_id']}',
      );

      Uint8List? photoBytes;
      final photoField = data?['photo'];
      if (photoField != null) {
        if (photoField is Map) {
          photoBytes = Uint8List.fromList(List<int>.from(photoField.values));
        } else if (photoField is String && photoField.isNotEmpty) {
          try {
            photoBytes = base64Decode(photoField);
          } catch (e) {
            debugPrint("Invalid Base64 photo: $e");
          }
        }
      }

      // Store in SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      if (photoBytes != null && photoBytes.isNotEmpty) {
        prefs.setString('staffPhoto', base64Encode(photoBytes));
      }

      setState(() {
        username = widget.username;
        name = data?['name'] ?? '';
        email = data?['email'] ?? '';
        mobile = data?['mobile'] ?? '';
        designation = data?['designation'] ?? '';
        gender = data?['gender'] ?? '';
        schoolData = (schoolResult.isNotEmpty) ? schoolResult[0] : null;
        profilePhoto = photoBytes;
        _isLoading = false;
      });
      //print(profilePhoto);
    } catch (e) {
      debugPrint("Error loading school data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    if (_isLoading) {
      return const Scaffold(
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
                ? MobileAppbar(
                  title: 'Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StaffDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId.toString(),
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Profile'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                      (profilePhoto.toString() != 'null' &&
                              profilePhoto != null &&
                              profilePhoto!.isNotEmpty)
                          ? MemoryImage(profilePhoto!)
                          : NetworkImage(
                            'https://cdn0.iconfinder.com/data/icons/employee-and-business-fill/512/Office_Staff-1024.png',
                          ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Staff Details',
                  icon: Icons.person,
                  fields: [
                    _buildField('Username', username),
                    _buildField('Name', name),
                    _buildField('Email', email),
                    _buildField('Mobile', mobile),
                    _buildField('Designation', designation),
                    _buildField(
                      'Gender',
                      gender == 'F'
                          ? 'Female'
                          : gender == 'M'
                          ? 'Male'
                          : 'Others',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child:
                          classes.isNotEmpty
                              ? Column(
                                children: [
                                  const Text(
                                    'Classes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 5,
                                    children:
                                        classes
                                            .map(
                                              (c) => Chip(
                                                label: Text(
                                                  '${c['class']}-${c['section']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              )
                              : const Text(''),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'School Info',
                  icon: Icons.school,
                  fields: [
                    _buildField('Name', schoolData?['name'] ?? 'Loading...'),
                    _buildField(
                      'Address',
                      schoolData?['address'] ?? 'Loading...',
                    ),
                  ],
                ),
              ],
            ),
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
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
