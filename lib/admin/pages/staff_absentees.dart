import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import 'admin_dashboard.dart';

class StaffAbsentees extends StatefulWidget {
  final String schoolId;
  final String username;

  const StaffAbsentees({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StaffAbsentees> createState() => _StaffAbsenteesState();
}

class _StaffAbsenteesState extends State<StaffAbsentees> {
  DateTime selectedDate = DateTime.now();
  Map<String, String> fnStatus = {};
  Map<String, String> anStatus = {};
  List<String> absentsList = [];
  List<String> absentsDesg = [];
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final fn = await ApiService.fetchTodayAttendance(
      formattedDate,
      'fn',
      widget.schoolId,
    );
    final an = await ApiService.fetchTodayAttendance(
      formattedDate,
      'an',
      widget.schoolId,
    );

    final fnAbsentees =
        fn.entries.where((entry) => entry.value == 'A').toList();
    final anAbsentees =
        an.entries.where((entry) => entry.value == 'A').toList();

    final uniqueUsernames = {
      ...fnAbsentees.map((e) => e.key),
      ...anAbsentees.map((e) => e.key),
    };

    Map<String, Map<String, String>> userDetails = {};
    for (var username in uniqueUsernames) {
      final data = await TeacherApiServices.fetchStaffDataUsername(username);
      if (data != null && data['name'] != null && data['mobile'] != null) {
        userDetails[username] = {
          'name': data['name'],
          'designation': data['mobile'],
        };
      } else {
        debugPrint('Missing data for $username: $data');
      }
    }

    setState(() {
      fnStatus = fn;
      anStatus = an;
      absentsList =
          userDetails.entries.map((e) => e.value['name'] ?? e.key).toList();
      absentsDesg =
          userDetails.entries.map((e) => e.value['designation'] ?? '').toList();
    });
  }

  Future<bool> onWillPop() async {
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
    return false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime day) => day.weekday != DateTime.sunday,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await init();
    }
  }

  Future<void> loop(List<MapEntry<String, String>> absentees) async {
    for (var absent in absentees) {
      final data = await TeacherApiServices.fetchStaffDataUsername(absent.key);
      print(' data:$data');
      final name = data?['name'];
      final designation = data?['mobile'];
      setState(() {
        absentsList.add(name);
        absentsDesg.add(designation);
      });
    }
  }

  Widget buildAbsenteeCard(
    String title,
    Map<String, String> data,
    Color color,
  ) {
    final absentees =
        data.entries.where((entry) => entry.value == 'A').toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${absentees.length}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            if (absentees.isEmpty)
              Center(
                child: Column(
                  children: const [
                    Icon(Icons.emoji_emotions, size: 40, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'No absentees',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: absentees.length,
                itemBuilder: (context, index) {
                  final entry = absentees[index];
                  final nameIndex = absentsList.indexWhere(
                    (name) => name == entry.key || name.contains(entry.key),
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      absentsList.length > nameIndex && nameIndex >= 0
                          ? absentsList[nameIndex]
                          : entry.key,
                    ),
                    subtitle: Text(
                      absentsDesg.length > nameIndex && nameIndex >= 0
                          ? absentsDesg[nameIndex]
                          : 'Mobile',
                    ),
                    leading: const Icon(Icons.person_off, color: Colors.red),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Staff Absentees',
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
                  : const AdminAppbarDesktop(title: 'Staff Absentees'),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today_outlined, size: 20),
                    label: const Text('Change Date'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [
                          buildAbsenteeCard(
                            'FN - Absentees',
                            fnStatus,
                            Colors.deepPurple,
                          ),
                          buildAbsenteeCard(
                            'AN - Absentees',
                            anStatus,
                            Colors.orange,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildAbsenteeCard(
                              'FN - Absentees',
                              fnStatus,
                              Colors.deepPurple,
                            ),
                          ),
                          Expanded(
                            child: buildAbsenteeCard(
                              'AN - Absentees',
                              anStatus,
                              Colors.orange,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
