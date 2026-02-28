import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../components/attendance_already_marked_dialog.dart';
import '../../components/build_profile_card_mobile.dart';
import '../../widget/notification_dialog.dart';
import '../dashboard/admin_dashboard.dart';

enum AttendanceSession { fN, aN }

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
  final ScrollController _mainScrollController = ScrollController();
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  AttendanceSession session =
      DateTime.now().hour < 13 ? AttendanceSession.fN : AttendanceSession.aN;
  List<Map<String, dynamic>> holidays = [];
  final List<Map<String, dynamic>> staffList = [];
  bool isLoading = true;
  bool allPresent = false;
  String submit = 'Submit';
  bool isHolidayFn = false;
  bool isHolidayAn = false;
  String holidayReason = '';
  Map<String, String> originalAttendance = {};
  final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, String> attendanceMap = {};
  Map<String, Map<String, String>> attendanceCache = {};
  String get sessionKey => session == AttendanceSession.fN ? 'fn' : 'an';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchHolidays();
      final now = DateTime.now();
      final hour = now.hour;
      if (hour < 13 && !isHolidayFn) {
        setState(() => session = AttendanceSession.fN);
      } else if (hour >= 13 && !isHolidayAn) {
        setState(() => session = AttendanceSession.aN);
      } else if (!isHolidayFn) {
        setState(() => session = AttendanceSession.fN);
      } else if (!isHolidayAn) {
        setState(() => session = AttendanceSession.aN);
      }
      await fetchSchoolInfo();
      await fetchStaff();
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
        if (isHolidayFn && isHolidayAn) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
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
                            onWillPop();
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
              );
            }
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
      setState(() {});
    }
  }

  // Group staff by gender and sort each group alphabetically by name
  List<Map<String, dynamic>> groupAndSortStaffByGender(
    List<Map<String, dynamic>> staff,
  ) {
    List<Map<String, dynamic>> males =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'M')
            .toList();
    List<Map<String, dynamic>> females =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'F')
            .toList();

    int nameComparator(a, b) => (a['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['name'] ?? '').toString().toLowerCase());

    males.sort(nameComparator);
    females.sort(nameComparator);

    return [...males, ...females];
  }

  Future<void> fetchStaff() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final fetchedStaffs = await AdminApiService.fetchStaffData(
        widget.schoolId,
      );
      final fetchedStaff = groupAndSortStaffByGender(fetchedStaffs);
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
        staffList
          ..clear()
          ..addAll(fetchedStaff);
        attendanceMap = {
          for (var staff in staffList)
            staff['username']:
                currentAttendance[staff['username']] == 'NM'
                    ? presentStatus
                    : currentAttendance[staff['username']] == 'A'
                    ? absentStatus
                    : presentStatus,
        };
        originalAttendance = Map<String, String>.from(attendanceMap);
        allPresent = attendanceMap.values.every((s) => s == presentStatus);
        submit =
            currentAttendance.values.any(
                  (s) => s == presentStatus || s == absentStatus,
                )
                ? 'Update'
                : 'Submit';
      });
      if (submit == 'Update') {
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => AttendanceAlreadyMarkedDialog(
                  onWillPop: onWillPop,
                  onYesPressed: () => Navigator.of(context).pop(),
                  onNoPressed: () {
                    Navigator.of(context).pop();
                    onWillPop();
                  },
                ),
          );
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool get hasChanges {
    return !mapEquals(attendanceMap, originalAttendance);
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.push(
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
                    title: 'Staff Attendance',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.push(
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
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Staff Attendance',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.push(
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
                : ListView(
                  controller: _mainScrollController,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  children: [
                    BuildProfileCard(
                      schoolPhoto: schoolPhoto,
                      schoolAddress: '$schoolAddress',
                      schoolName: '$schoolName',
                    ),
                    const SizedBox(height: 16),
                    teaching(),
                    nonTeaching(),
                  ],
                ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton:
            isLoading
                ? SizedBox()
                : SizedBox(
                  width: MediaQuery.sizeOf(context).width / 2.5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                          submit == 'Update' ? Colors.green : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed:
                        (submit == 'Update' && !hasChanges)
                            ? null
                            : _submitAttendance,
                    child: Row(
                      children: [
                        Spacer(),
                        Icon(
                          submit == 'Update' ? Icons.update : Icons.check,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          submit,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget teaching() {
    final teachingStaff =
        staffList.where((s) => s['faculty'] == 'teaching').toList();
    teachingStaff.sort((a, b) {
      final genderA = a['gender'] ?? '';
      final genderB = b['gender'] ?? '';

      // Put males first
      if (genderA == 'M' && genderB != 'M') return -1;
      if (genderA != 'M' && genderB == 'M') return 1;

      // Same gender, sort by username alphabetically
      final userA = (a['username'] ?? '').toString();
      final userB = (b['username'] ?? '').toString();
      return userA.compareTo(userB);
    });

    return Column(
      children: [
        Row(
          children: [
            const Text("Session: ", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            _buildSessionButton('FN', AttendanceSession.fN),
            const SizedBox(width: 8),
            _buildSessionButton('AN', AttendanceSession.aN),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: allPresent ? Colors.red : Colors.green,
              ),
              onPressed: () {
                setState(() {
                  allPresent = !allPresent;
                  // Updated: set attendance status for all staff
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
        ...teachingStaff.map(_buildStaffCard),
      ],
    );
  }

  Widget nonTeaching() {
    final nonTeachingStaff =
        staffList.where((s) => s['faculty'] == 'nonteaching').toList();
    nonTeachingStaff.sort((a, b) {
      final genderA = a['gender'] ?? '';
      final genderB = b['gender'] ?? '';

      // Put males first
      if (genderA == 'M' && genderB != 'M') return -1;
      if (genderA != 'M' && genderB == 'M') return 1;

      // Same gender, sort by username alphabetically
      final userA = (a['username'] ?? '').toString();
      final userB = (b['username'] ?? '').toString();
      return userA.compareTo(userB);
    });

    return Column(
      children: [
        SizedBox(height: 20),
        const Center(
          child: Text(
            'Non Teaching Staff',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...nonTeachingStaff.map(_buildStaffCard),
        const SizedBox(height: 120),
      ],
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
          staff['designation'] ?? '',
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
                final isDesktop = kIsWeb || isDesktopPlatform;
                final url =
                    isDesktop
                        ? Uri.parse('https://wa.me/$phone')
                        : Uri.parse('tel:$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch link')),
                    );
                  }
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
        (type == AttendanceSession.fN && isHolidayFn) ||
        (type == AttendanceSession.aN && isHolidayAn);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey,
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
    final now = DateTime.now();
    final isValidTime =
        (session == AttendanceSession.fN && now.hour < 13 && !isHolidayFn) ||
        (session == AttendanceSession.aN && now.hour >= 13 && !isHolidayAn);
    if (!isValidTime) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Invalid Time"),
              content: Text(
                "Attendance cannot be submitted during this session/time.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
      );
      return;
    }
    final failedUsernames = <String>[];

    final targetUsernames = staffList.map((s) => s['username']).toSet();

    await Future.wait(
      attendanceMap.entries
          .where((entry) => targetUsernames.contains(entry.key))
          .map((entry) async {
            if (entry.value == 'NM') return;
            final result = await ApiService.postAttendance(
              username: entry.key,
              date: currentDate,
              session: sessionKey.toUpperCase(),
              status: entry.value,
              schoolId: widget.schoolId,
            );
            if (!result) failedUsernames.add(entry.key);
          }),
    );
    final success = failedUsernames.isEmpty;
    final message =
        success
            ? submit == 'Update'
                ? 'Attendance updated successfully'
                : 'Attendance submitted successfully'
            : submit == 'Update'
            ? 'Failed to update attendance'
            : 'Failed to submit attendance';
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (_) => StatusDialog(
              message1: message,
              isSuccess: success,
              onPressed: () {
                Navigator.of(context).pop();
                if (success) {
                  setState(() {
                    submit = 'Update';
                    originalAttendance = Map<String, String>.from(
                      attendanceMap,
                    );
                  });
                  onWillPop();
                }
              },
            ),
      );
    }
  }
}
