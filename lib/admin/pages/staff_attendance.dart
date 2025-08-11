import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/attendance_already_marked_dialog.dart';
import '../components/build_profile_card_mobile.dart';
import '../widget/notification_dialog.dart';
import 'admin_dashboard.dart';

enum AttendanceSession { FN, AN }

const String presentStatus = 'P';
const String absentStatus = 'A';

class StaffAttendance extends StatefulWidget {
  final String schoolId;
  final String username;

  const StaffAttendance({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StaffAttendance> createState() => _StaffAttendanceState();
}

class _StaffAttendanceState extends State<StaffAttendance> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.FN : AttendanceSession.AN;
  List<Map<String, dynamic>> holidays = [];
  final List<Map<String, dynamic>> staffList = [];
  bool isLoading = true;
  bool allPresent = false;
  String submit = 'Submit';
  bool isHolidayFn = false;
  bool isHolidayAn = false;
  String holidayReason = '';

  final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, String> attendanceMap = {};
  Map<String, Map<String, String>> attendanceCache = {};

  String get sessionKey => session == AttendanceSession.FN ? 'fn' : 'an';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchHolidays(); // Load holidays first

      final now = DateTime.now();
      final hour = now.hour;

      // Determine session only if it's a working session
      if (hour < 13 && !isHolidayFn) {
        setState(() => session = AttendanceSession.FN);
      } else if (hour >= 13 && !isHolidayAn) {
        setState(() => session = AttendanceSession.AN);
      } else if (!isHolidayFn) {
        setState(() => session = AttendanceSession.FN);
      } else if (!isHolidayAn) {
        setState(() => session = AttendanceSession.AN);
      }

      await fetchSchoolInfo();
      await fetchStaff(); // Fetch staff after setting session
    });
  }

  Future<void> fetchHolidays() async {
    final allHolidays = await ApiService.fetchHolidays(widget.schoolId);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    for (var holiday in allHolidays) {
      final holidayDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(holiday['date']));
      if (holidayDate == todayStr) {
        setState(() {
          isHolidayFn = holiday['fn'] == 'H';
          isHolidayAn = holiday['an'] == 'H';
          holidayReason = holiday['reason'] ?? 'Holiday';
        });

        // If full day is holiday, show dialog and exit
        if (isHolidayFn && isHolidayAn) {
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (_) => AlertDialog(
                    title: const Text("Holiday"),
                    content: Text(
                      "Today is a holiday.\nReason: $holidayReason",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
            );
          });
        }

        break;
      }
    }

    setState(() {
      holidays = allHolidays;
    });
  }

  Future<void> fetchSchoolInfo() async {
    final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
    if (!mounted) return;

    setState(() {
      schoolName = schoolData[0]['name'];
      schoolAddress = schoolData[0]['address'];
    });

    try {
      if (schoolData[0]['photo'] != null) {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        if (!mounted) return;
        setState(() {
          schoolPhoto = Image.memory(
            imageBytes,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
        });
      }
    } catch (e) {
      print('Image decode error: $e');
    }
  }

  Future<void> fetchStaff() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final fetchedStaff = await AdminApiService.fetchStaffData(widget.schoolId);
    if (!mounted) return;

    final cacheKey = '${currentDate}_$sessionKey';
    Map<String, String> currentAttendance;

    if (attendanceCache.containsKey(cacheKey)) {
      currentAttendance = attendanceCache[cacheKey]!;
    } else {
      currentAttendance = await ApiService.fetchTodayAttendance(
        currentDate,
        sessionKey,
        widget.schoolId,
      );
      if (!mounted) return;
      attendanceCache[cacheKey] = currentAttendance;
    }

    setState(() {
      staffList.clear();
      staffList.addAll(fetchedStaff);
      attendanceMap = {
        for (var staff in staffList)
          staff['username']:
              currentAttendance[staff['username']] == 'NM'
                  ? presentStatus
                  : currentAttendance[staff['username']] == 'A'
                  ? absentStatus
                  : presentStatus,
      };
      allPresent = attendanceMap.values.every((s) => s == presentStatus);
      isLoading = false;
      submit =
          currentAttendance.values.any(
                (s) => s == presentStatus || s == absentStatus,
              )
              ? 'Submitted'
              : 'Submit';
    });

    if (submit == 'Submitted') {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => WillPopScope(
                onWillPop: () async {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                  return false;
                },
                child: AttendanceAlreadyMarkedDialog(
                  onYesPressed: () => Navigator.of(context).pop(),
                  onNoPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pop(context); // Pop the StaffAttendance screen
                  },
                ),
              ),
        );
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Staff Attendance',
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
                  : const AdminAppbarDesktop(title: 'Staff Attendance'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  children: [
                    BuildProfileCard(
                      schoolPhoto: schoolPhoto,
                      schoolAddress: '$schoolAddress',
                      schoolName: '$schoolName',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Session: ", style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        _buildSessionButton('FN', AttendanceSession.FN),
                        const SizedBox(width: 8),
                        _buildSessionButton('AN', AttendanceSession.AN),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                allPresent ? Colors.red : Colors.green,
                          ),
                          onPressed: () {
                            setState(() {
                              allPresent = !allPresent;
                              for (var staff in staffList) {
                                attendanceMap[staff['username']] =
                                    allPresent ? presentStatus : absentStatus;
                              }
                            });
                          },
                          child: Text(
                            allPresent ? 'All Absent' : 'All Present',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Teaching Staff',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...staffList.map(_buildStaffCard).toList(),
                    SizedBox(height: 80),
                  ],
                ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: MediaQuery.sizeOf(context).width / 1.5,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor:
                  submit == 'Submitted' ? Colors.green : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onPressed: _submitAttendance,
            child: Text(
              submit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final username = staff['username'];
    final originalStatus = attendanceMap[username] ?? 'NM';
    final displayStatus = originalStatus == 'NM' ? 'P' : originalStatus;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          staff['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: staff['gender'] == 'F' ? Colors.red : Colors.blue,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          staff['mobile'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () async {
                final phone = staff['mobile'];
                if (phone == null || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number not available')),
                  );
                  return;
                }

                final isDesktop =
                    kIsWeb ||
                    Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS;

                final url =
                    isDesktop
                        ? Uri.parse('https://wa.me/$phone')
                        : Uri.parse('tel:$phone');

                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch link')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  attendanceMap[username] =
                      originalStatus == presentStatus
                          ? absentStatus
                          : presentStatus;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      displayStatus == presentStatus ? Colors.teal : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionButton(String label, AttendanceSession type) {
    final isSelected = session == type;

    final isDisabled =
        (type == AttendanceSession.FN && isHolidayFn) ||
        (type == AttendanceSession.AN && isHolidayAn);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
      ),
      onPressed:
          isDisabled
              ? null
              : () {
                setState(() {
                  session = type;
                  fetchStaff();
                });
              },
      child: Text(
        label,
        style: TextStyle(
          color: isDisabled ? Colors.grey : Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final failedUsernames = <String>[];

    await Future.wait(
      attendanceMap.entries.map((entry) async {
        if (entry.value == 'NM') return;
        final result = await ApiService.postAttendance(
          username: entry.key,
          date: currentDate,
          session: sessionKey.toUpperCase(),
          status: entry.value,
          school_id: widget.schoolId,
        );
        if (!result) failedUsernames.add(entry.key);
      }),
    );

    final success = failedUsernames.isEmpty;
    final message =
        success
            ? 'Attendance submitted successfully'
            : 'Failed to submit attendance';

    showDialog(
      context: context,
      builder:
          (_) => StatusDialog(
            message1: message,
            isSuccess: success,
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                setState(() => submit = 'Submitted');
                fetchStaff();
                Navigator.pop(context);
              }
            },
          ),
    );
  }
}
