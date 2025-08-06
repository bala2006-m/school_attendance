import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../teacher/color/teacher_custom_color.dart' as AdminCustomColor;
import './admin_dashboard.dart';

class MarkLeaveList extends StatefulWidget {
  final String schoolId;
  final String username;
  const MarkLeaveList({
    super.key,
    required this.schoolId,
    required this.username,
  });
  @override
  State<MarkLeaveList> createState() => _MarkLeaveListState();
}

class _MarkLeaveListState extends State<MarkLeaveList> {
  String username = 'Admin';
  ImageProvider? adminPhoto;
  int _selectedIndex = 0;

  final ImageProvider defaultImage = const NetworkImage(
    'https://th.bing.com/th?q=Admin+Icon.png&w=120&h=120&c=1&rs=1&qlt=70&r=0&o=7&cb=1&pid=InlineBlock&rm=3&mkt=en-IN&cc=IN&setlang=en&adlt=moderate&t=1&mw=247',
  );
  List<Map<String, dynamic>> allHolidays = [];
  bool showAll = false, isLoading = true, hasError = false;
  String errorMessage = '';
  Map<int, String> classNamesById = {};

  @override
  void initState() {
    super.initState();
    loadHolidays();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('username');
    final photoBase64 = prefs.getString('adminPhoto');
    setState(() {
      username =
          (storedUsername!.length < 15
              ? storedUsername
              : '${storedUsername.substring(0, 15)}...');
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        try {
          Uint8List bytes = base64Decode(photoBase64);
          adminPhoto = MemoryImage(bytes);
        } catch (e) {
          debugPrint('Failed to decode base64 image: $e');
          adminPhoto = null;
        }
      }
    });
  }

  Future<void> loadHolidays() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final holidays = await ApiService.fetchHolidays(widget.schoolId);
      await fetchClassNames(holidays);
      setState(() {
        allHolidays = holidays.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> fetchClassNames(List<Map<String, dynamic>> list) async {
    final schoolId = int.tryParse(widget.schoolId) ?? 0;
    classNamesById.clear();
    final ids = <int>{};
    for (var h in list) {
      final raw = h['class_ids'];
      if (raw is List) {
        ids.addAll(raw.cast<int>());
      } else if (raw is String) {
        try {
          final parsed = jsonDecode(raw);
          if (parsed is List) ids.addAll(parsed.cast<int>());
        } catch (_) {}
      }
    }
    await Future.wait(
      ids.map((cid) async {
        try {
          final info = await AdminApiService.fetchClassInfo(
            classId: cid,
            schoolId: schoolId,
          );
          classNamesById[cid] = "${info['class']}-${info['section']}";
        } catch (_) {}
      }),
    );
  }

  String getClassNames(dynamic raw) {
    final ids =
        raw is List
            ? raw.cast<int>()
            : (jsonDecode(raw.toString()) as List<dynamic>).cast<int>();
    return ids.map((i) => classNamesById[i] ?? 'Class $i').join(', ');
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Widget buildHoliday(Map<String, dynamic> h) {
    final fn = h['fn'] ?? '-';
    final an = h['an'] ?? '-';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          h['reason'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(h['date'])),
            Text('FN: $fn | AN: $an'),
            Text('Classes: ${getClassNames(h['class_ids'])}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => confirmDelete(h['date']),
        ),
      ),
    );
  }

  String _formatDate(String ds) {
    try {
      final d = DateTime.parse(ds);
      final wd =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ($wd)";
    } catch (_) {
      return ds;
    }
  }

  Future<String?> pickDate() async {
    final markedDates = allHolidays.map((h) => h['date'] as String).toSet();

    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: (day) {
        // Format day to 'yyyy-MM-dd' string to match your data
        final formatted =
            "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

        // Disable Sundays and already marked holidays
        return day.weekday != DateTime.sunday &&
            !markedDates.contains(formatted);
      },
      builder: (context, child) {
        return WillPopScope(onWillPop: () async => false, child: child!);
      },
    ).then((p) {
      if (p != null && p.weekday == DateTime.sunday) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot mark on Sunday")));
        return null;
      }
      return p != null
          ? "${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}"
          : null;
    });
  }

  Future<String?> pickReason() async {
    String? sel;
    String comment = '';
    final reasons = [
      'Local Holiday',
      'Natural Disaster',
      'Public Holiday',
      'Custom',
    ];

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder: (_, st) {
              final size = MediaQuery.of(context).size;
              return AlertDialog(
                title: const Text('Select Reason'),
                content: SizedBox(
                  width: size.width * 0.75,
                  height: size.height / 2.5,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children:
                              reasons.map((r) {
                                return RadioListTile<String>(
                                  title: Text(r),
                                  value: r,
                                  groupValue: sel,
                                  onChanged:
                                      (v) => st(() {
                                        sel = v;
                                        comment = '';
                                      }),
                                );
                              }).toList(),
                        ),
                      ),
                      if (sel != null)
                        TextField(
                          onChanged: (v) => comment = v,
                          decoration: InputDecoration(
                            labelText:
                                sel == 'Custom'
                                    ? 'Enter Custom Reason'
                                    : 'Additional Info (optional)',
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (sel == null) return;
                      if (sel == 'Custom' && comment.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a custom reason.'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                        context,
                        sel == 'Custom'
                            ? comment.trim()
                            : (comment.trim().isEmpty
                                ? sel!
                                : '$sel ($comment)'),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<Map<String, String>?> pickSessions() async {
    String fnValue = 'H';
    String anValue = 'H';

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: const Text("Select Sessions"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('FN (Forenoon)'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'H',
                          groupValue: fnValue,
                          onChanged: (val) => setState(() => fnValue = val!),
                        ),
                        const Text('Holiday'),
                        Radio<String>(
                          value: 'W',
                          groupValue: fnValue,
                          onChanged: (val) => setState(() => fnValue = val!),
                        ),
                        const Text('Working'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('AN (Afternoon)'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'H',
                          groupValue: anValue,
                          onChanged: (val) => setState(() => anValue = val!),
                        ),
                        const Text('Holiday'),
                        Radio<String>(
                          value: 'W',
                          groupValue: anValue,
                          onChanged: (val) => setState(() => anValue = val!),
                        ),
                        const Text('Working'),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                  ElevatedButton(
                    child: const Text('OK'),
                    onPressed: () {
                      if (fnValue == 'W' && anValue == 'W') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'At least one session must be holiday',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {'fn': fnValue, 'an': anValue});
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<List<int>?> pickClasses() async {
    final classList = await AdminApiService.fetchAllClasses(widget.schoolId);
    final selected = <int>{};
    bool selectAll = false;

    // Step 1: Class selection dialog
    final result = await showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder: (_, st) {
              return AlertDialog(
                title: const Text('Select Classes'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Select All'),
                          value: selectAll,
                          onChanged:
                              (val) => st(() {
                                selectAll = val ?? false;
                                selected.clear();
                                if (selectAll) {
                                  selected.addAll(
                                    classList.map((c) => c['id'] as int),
                                  );
                                }
                              }),
                        ),
                        const Divider(),
                        ...classList.map((c) {
                          final id = c['id'] as int;
                          final label = "${c['class']}-${c['section']}";
                          return CheckboxListTile(
                            title: Text(label),
                            value: selected.contains(id),
                            onChanged:
                                (val) => st(() {
                                  if (val == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                  selectAll =
                                      selected.length == classList.length;
                                }),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null), // Cancel
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one class'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, selected.toList());
                    },
                    child: const Text('Next'),
                  ),
                ],
              );
            },
          ),
    );

    if (result == null || result.isEmpty) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final selectedNames = classList
            .where((c) => result.contains(c['id']))
            .map((c) => "${c['class']}-${c['section']}")
            .join(", ");
        return AlertDialog(
          title: const Text('Confirm Selection'),
          content: Text("Selected Classes:\n$selectedNames"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return confirmed == true ? result : await pickClasses(); // Retry or return
  }

  Future<void> confirmDelete(String date) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text('Remove holiday on ${_formatDate(date)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );
    if (ok == true) {
      setState(() => isLoading = true);
      try {
        await ApiService.deleteHoliday(date, widget.schoolId);
        await loadHolidays();
      } catch (e) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> addHoliday() async {
    while (true) {
      final date = await pickDate();
      if (date == null) return;

      while (true) {
        final reason = await pickReason();
        if (reason == null) {
          break;
        }

        while (true) {
          final classIds = await pickClasses();
          if (classIds == null || classIds.isEmpty) {
            break;
          }

          final sessions = await pickSessions();
          if (sessions == null) break;

          setState(() => isLoading = true);
          try {
            await ApiService.addHoliday(
              date: date,
              reason: reason,
              schoolId: widget.schoolId,
              classIds: classIds,
              fn: sessions['fn']!,
              an: sessions['an']!,
            );
            await loadHolidays();
          } catch (e) {
            setState(() {
              isLoading = false;
              hasError = true;
              errorMessage = e.toString();
            });
          }
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final formattedDate = DateFormat('MMMM d, y').format(DateTime.now());

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    final list = showAll ? allHolidays : allHolidays.take(10).toList();
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AdminCustomColor.appbar,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30, left: 10),
                      child: Builder(
                        builder:
                            (context) => InkWell(
                              onTap: () async {
                                AdminDashboardState.selectedIndex = 2;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AdminDashboard(
                                          schoolId: widget.schoolId,
                                          username: widget.username,
                                        ),
                                  ),
                                );
                              },
                              child: Icon(
                                size: 40,
                                Icons.arrow_back,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Mark Leave List',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: IconButton(
                        onPressed: () => loadHolidays(),
                        icon: Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: adminPhoto ?? defaultImage,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
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
                : hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage, textAlign: TextAlign.center),
                      ElevatedButton(
                        onPressed: loadHolidays,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : allHolidays.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('No holidays found'),
                      ElevatedButton(
                        onPressed: loadHolidays,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: loadHolidays,
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) => buildHoliday(list[i]),
                        ),
                      ),
                    ),
                    if (!showAll && allHolidays.length > 10)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          child: const Text('Show All Holidays'),
                          onPressed: () => setState(() => showAll = true),
                        ),
                      ),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 1) {
                addHoliday();
              }
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add, size: 30),
              label: 'Add Holidays',
            ),
          ],
        ),
      ),
    );
  }
}
