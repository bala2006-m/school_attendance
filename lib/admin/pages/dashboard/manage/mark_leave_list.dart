import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/api_service.dart';
import '../admin_dashboard.dart';

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
  DateTime _getValidInitialDate(Set<String> markedDates) {
    DateTime candidate = DateTime.now();

    while (true) {
      final formatted =
          "${candidate.year.toString().padLeft(4, '0')}-${candidate.month.toString().padLeft(2, '0')}-${candidate.day.toString().padLeft(2, '0')}";

      // Must not be Sunday and not already marked
      if (candidate.weekday != DateTime.sunday &&
          !markedDates.contains(formatted)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
  }

  @override
  void initState() {
    super.initState();
    loadHolidays();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('adminName');
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
          bytes.length < 5 ? adminPhoto = null : null;
        } catch (e) {
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
    Navigator.push(
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
    final classes = getClassNames(h['class_ids']).split(", ");

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            h['reason'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.cyan.shade700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(h['date']),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'FN: $fn | AN: $an',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Classes:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.cyan.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    classes.map((cls) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          cls,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blueAccent,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Holiday',
            splashRadius: 24,
            onPressed: () => confirmDelete(h['date']),
          ),
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

    final initial = _getValidInitialDate(markedDates);

    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: (day) {
        final formatted =
            "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        return day.weekday != DateTime.sunday &&
            !markedDates.contains(formatted);
      },
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, res) {},
          child: child!,
        );
      },
    ).then((p) {
      if (p != null && p.weekday == DateTime.sunday) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot mark on Sunday")),
          );
        }
        return null;
      }
      return p != null
          ? "${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}"
          : null;
    });
  }

  Future<String?> pickReason(BuildContext context) async {
    String? sel;
    String comment = '';
    final reasons = [
      {'label': 'Local Holiday', 'icon': Icons.beach_access},
      {'label': 'Natural Disaster', 'icon': Icons.waves},
      {'label': 'Public Holiday', 'icon': Icons.celebration},
      {'label': 'Custom', 'icon': Icons.edit},
    ];

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder: (_, st) {
              final size = MediaQuery.of(context).size;
              bool isOkEnabled =
                  sel != null && (sel != 'Custom' || comment.trim().isNotEmpty);

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                title: Text(
                  'Select Reason',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.cyan.shade700,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                content: SizedBox(
                  width: size.width * 0.75,
                  height: size.height / 2.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemCount: reasons.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final reason = reasons[index];
                              return RadioListTile<String>(
                                title: Text(reason['label'].toString()),
                                secondary: Icon(
                                  reason['icon'] as IconData,
                                  color:
                                      sel == reason['label']
                                          ? Colors.blue
                                          : null,
                                ),
                                value: reason['label'].toString(),
                                groupValue: sel,
                                onChanged: (v) {
                                  st(() {
                                    sel = v;
                                    comment = '';
                                  });
                                },
                                selected: sel == reason['label']!,
                                activeColor: Colors.blue,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor:
                                    sel == reason['label']
                                        ? Colors.blue.shade50
                                        : null,
                              );
                            },
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            sel != null
                                ? Padding(
                                  key: ValueKey(sel),
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextField(
                                    autofocus: sel == 'Custom',
                                    maxLines: 2,
                                    onChanged: (v) => st(() => comment = v),
                                    decoration: InputDecoration(
                                      labelText:
                                          sel == 'Custom'
                                              ? 'Enter Custom Reason'
                                              : 'Additional Info (optional)',
                                      hintText:
                                          sel == 'Custom'
                                              ? 'Type your reason here...'
                                              : 'Any extra details',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        isOkEnabled
                            ? () {
                              Navigator.pop(
                                context,
                                sel == 'Custom'
                                    ? comment.trim()
                                    : (comment.trim().isEmpty
                                        ? sel!
                                        : '$sel ($comment)'),
                              );
                            }
                            : null,
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: isOkEnabled ? Colors.blue : Colors.black,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<Map<String, String>?> pickSessions(BuildContext context) async {
    String fnValue = 'H';
    String anValue = 'H';

    Widget sessionToggle(
      String label,
      String groupValue,
      ValueChanged<String> onChanged,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            constraints: const BoxConstraints(minHeight: 38, minWidth: 100),
            isSelected: [groupValue == 'H', groupValue == 'W'],
            onPressed: (index) {
              onChanged(index == 0 ? 'H' : 'W');
            },
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access, size: 18),
                  SizedBox(width: 6),
                  Text('Holiday'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 18),
                  SizedBox(width: 6),
                  Text('Working'),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 12,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Sessions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "At least one session must be a Holiday",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sessionToggle(
                    'FN (Forenoon)',
                    fnValue,
                    (val) => setState(() => fnValue = val),
                  ),
                  const SizedBox(height: 20),
                  sessionToggle(
                    'AN (Afternoon)',
                    anValue,
                    (val) => setState(() => anValue = val),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.pop(ctx, null),
                ),
                ElevatedButton(
                  onPressed:
                      fnValue == 'W' && anValue == 'W'
                          ? () {}
                          : () {
                            if (fnValue == 'W' && anValue == 'W') {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'At least one session must be holiday',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx, {'fn': fnValue, 'an': anValue});
                          },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color:
                          fnValue == 'W' && anValue == 'W'
                              ? Colors.black
                              : Colors.blue,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<int>?> pickClasses({
    required BuildContext context,
    required String schoolId,
  }) async {
    final classList = await AdminApiService.fetchAllClasses(schoolId);
    final selected = <int>{};
    bool selectAll = false;
    String searchQuery = '';

    List<Map<String, dynamic>> filterClasses() {
      if (searchQuery.trim().isEmpty) return classList;
      return classList.where((c) {
        final label = "${c['class']}-${c['section']}".toLowerCase();
        return label.contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (context.mounted) {
      return showDialog<List<int>>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => StatefulBuilder(
              builder: (_, st) {
                final filteredClasses = filterClasses();
                bool isNextEnabled = selected.isNotEmpty;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Classes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                      ),
                      if (selected.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selected.length} selected',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search classes...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                          onChanged:
                              (val) => st(() {
                                searchQuery = val;
                              }),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          tileColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: const Text(
                            'Select All',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          value: selectAll,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged:
                              (val) => st(() {
                                selectAll = val ?? false;
                                selected.clear();
                                if (selectAll) {
                                  selected.addAll(
                                    filteredClasses.map((c) => c['id'] as int),
                                  );
                                }
                              }),
                        ),
                        const Divider(),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child:
                                filteredClasses.isEmpty
                                    ? const Center(
                                      child: Text('No classes found.'),
                                    )
                                    : ListView.separated(
                                      itemCount: filteredClasses.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 6),
                                      itemBuilder: (_, index) {
                                        final c = filteredClasses[index];
                                        final id = c['id'] as int;
                                        final label =
                                            "${c['class']}-${c['section']}";
                                        return CheckboxListTile(
                                          title: Text(label),
                                          value: selected.contains(id),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          onChanged:
                                              (val) => st(() {
                                                if (val == true) {
                                                  selected.add(id);
                                                } else {
                                                  selected.remove(id);
                                                }
                                                // Update selectAll only for filtered visible items
                                                final allFilteredIds =
                                                    filteredClasses
                                                        .map(
                                                          (e) => e['id'] as int,
                                                        )
                                                        .toSet();
                                                selectAll =
                                                    allFilteredIds
                                                        .difference(selected)
                                                        .isEmpty &&
                                                    allFilteredIds.isNotEmpty;
                                              }),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          tileColor:
                                              selected.contains(id)
                                                  ? Colors.blue.shade50
                                                  : null,
                                        );
                                      },
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null), // Cancel
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isNextEnabled
                              ? () async {
                                final result = selected.toList();
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) {
                                    final selectedNames = classList
                                        .where((c) => result.contains(c['id']))
                                        .map(
                                          (c) =>
                                              "${c['class']}-${c['section']}",
                                        )
                                        .join(", ");
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 10,
                                      title: Text(
                                        'Confirm Selection',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          color: Colors.cyan.shade700,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Text(
                                          "Selected Classes:\n$selectedNames",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text(
                                            'Back',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            'Confirm',
                                            style: TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed == true) {
                                  if (context.mounted) {
                                    Navigator.pop(context, result);
                                  }
                                }
                              }
                              : null,
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: isNextEnabled ? Colors.blue : Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      );
    }
    return null;
  }

  Future<void> confirmDelete(String date) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text(
              'Confirm Deletion',
              style: TextStyle(
                color: Colors.cyan.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text('Remove holiday on ${_formatDate(date)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
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
        String? reason;
        if (mounted) {
          reason = await pickReason(context);
        }
        if (reason == null) {
          break;
        }

        while (true) {
          List<int>? classIds;
          if (mounted) {
            classIds = await pickClasses(
              context: context,
              schoolId: widget.schoolId,
            );
          }
          if (classIds == null || classIds.isEmpty) {
            break;
          }

          Map<String, String>? sessions;
          if (mounted) {
            sessions = await pickSessions(context);
          }
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
    String formatCustomDate(DateTime date) {
      final monthMap = {
        "Jan": "Jan",
        "Feb": "Feb",
        "Mar": "Mar",
        "Apr": "Apr",
        "May": "May",
        "Jun": "Jun",
        "Jul": "Jul",
        "Aug": "Aug",
        "Sep": "Sept",
        "Oct": "Oct",
        "Nov": "Nov",
        "Dec": "Dec",
      };

      final month = DateFormat('MMM').format(date);
      final day = DateFormat('d').format(date);
      final year = DateFormat('y').format(date);

      return "${monthMap[month]} $day $year";
    }

    // Usage
    final formattedDate = formatCustomDate(DateTime.now());
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    final list = showAll ? allHolidays : allHolidays.take(10).toList();
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF2B7CA8),
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
                                Navigator.push(
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
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Create Holiday List',
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
                          (username.length < 10
                              ? username
                              : '${username.substring(0, 10)}...'),
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
