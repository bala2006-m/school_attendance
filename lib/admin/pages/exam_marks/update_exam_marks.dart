import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// Import your own app bar and service files accordingly
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import 'exam_marks.dart';

class UpdateExamMarks extends StatefulWidget {
  const UpdateExamMarks({
    super.key,
    required this.username,
    required this.classId,
    required this.schoolId,
    required this.title,
    required this.className,
    required this.section,
  });

  final String username;
  final String classId;
  final String schoolId;
  final String title;
  final String className;
  final String section;

  @override
  State<UpdateExamMarks> createState() => _UpdateExamMarksState();
}

class _UpdateExamMarksState extends State<UpdateExamMarks> {
  List<dynamic> allExamMarks = [];
  List<dynamic> filteredExamMarks = [];
  bool isLoading = true;
  String filterQuery = '';
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    fetchExamMarks();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> fetchExamMarks() async {
    setState(() => isLoading = true);
    try {
      allExamMarks = await AdminApiService.fetchExamMarkClassTitle(
        schoolId: widget.schoolId,
        classId: widget.classId,
        title: widget.title,
      );
      applyFilter();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch exam marks: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => isLoading = false);
    _refreshController.refreshCompleted();
  }

  void applyFilter() {
    if (filterQuery.isEmpty) {
      filteredExamMarks = List.from(allExamMarks);
    } else {
      filteredExamMarks =
          allExamMarks
              .where(
                (mark) => mark['username'].toString().toLowerCase().contains(
                  filterQuery.toLowerCase(),
                ),
              )
              .toList();
    }
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamMarks(
              schoolId: widget.schoolId,
              username: widget.username,
              classId: widget.classId,
              className: widget.className,
              section: widget.section,
            ),
      ),
    );
    return false;
  }

  Map<String, dynamic> getSummaryInfo() {
    if (allExamMarks.isEmpty) return {};
    final subjectCount = <String, int>{};
    final statusCount = <String, int>{};
    final updatedDateCount = <String, int>{};

    for (var mark in allExamMarks) {
      if (mark['subjects'] != null) {
        for (var subject in List<String>.from(mark['subjects'])) {
          subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
        }
      }
      if (mark['status'] != null) {
        statusCount[mark['status']] = (statusCount[mark['status']] ?? 0) + 1;
      }
      if (mark['updated_at'] != null) {
        final date = mark['updated_at'].toString().split('T').first;
        updatedDateCount[date] = (updatedDateCount[date] ?? 0) + 1;
      }
    }
    return {
      'subjects': subjectCount,
      'statuses': statusCount,
      'updatedDates': updatedDateCount,
    };
  }

  Future<void> toggleSingleStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == "active" ? "inactive" : "active";
    final success = await AdminApiService.updateExamMarkStatusById(
      id: id,
      status: newStatus,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to '$newStatus'")),
        );
      }
      await fetchExamMarks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update status")),
        );
      }
    }
  }

  Future<void> bulkUpdateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Action"),
            content: Text(
              "Are you sure you want to set ALL records to '$status'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final success = await AdminApiService.updateExamMarkStatus(
      schoolId: widget.schoolId,
      classId: widget.classId,
      status: status,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("All records updated to '$status'")),
        );
      }
      await fetchExamMarks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update all statuses")),
        );
      }
    }
  }

  Widget _buildSummaryCard() {
    final summary = getSummaryInfo();
    if (summary.isEmpty) return Center(child: const Text('No data available'));

    final subjectCount = summary['subjects'] as Map<String, int>;
    final statusCount = summary['statuses'] as Map<String, int>;
    final updatedDateCount = summary['updatedDates'] as Map<String, int>;

    final activeCount = statusCount['active'] ?? 0;
    final inactiveCount = statusCount['inactive'] ?? 0;
    final toggleAction = inactiveCount >= activeCount ? 'active' : 'inactive';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.blueGrey.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Exam Summary",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await calculateAndUpdateRanks();
                    bulkUpdateStatus(toggleAction);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        toggleAction == "active" ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    toggleAction == "active"
                        ? Icons.check_circle
                        : Icons.cancel,
                  ),
                  label: Text(
                    toggleAction == "active"
                        ? "Activate All"
                        : "Inactivate All",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text("Subjects:", style: _sectionTitleStyle()),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  subjectCount.entries
                      .map(
                        (e) => Chip(
                          avatar: const Icon(
                            Icons.book,
                            size: 16,
                            color: Colors.blue,
                          ),
                          label: Text("${e.key} (${e.value})"),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            Text("Statuses:", style: _sectionTitleStyle()),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  statusCount.entries
                      .map(
                        (e) => Chip(
                          avatar: Icon(
                            e.key == "active"
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                e.key == "active" ? Colors.green : Colors.red,
                          ),
                          label: Text("${e.key.toUpperCase()} (${e.value})"),
                          backgroundColor:
                              e.key == "active"
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            Text("Updated Dates:", style: _sectionTitleStyle()),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  updatedDateCount.entries
                      .map(
                        (e) => Chip(
                          label: Text("${e.key} (${e.value})"),
                          backgroundColor: Colors.orange.shade50,
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle() {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.blueGrey[600],
    );
  }

  Widget _buildMarkListItem(BuildContext context, int index) {
    final mark = filteredExamMarks[index];
    final id = mark['id'];
    final status = mark['status'] ?? "inactive";

    return Dismissible(
      key: Key(id.toString()),
      background: Container(
        color: status == "active" ? Colors.red : Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Icon(
          status == "active" ? Icons.cancel : Icons.check_circle,
          color: Colors.white,
          size: 32,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await toggleSingleStatus(id, status);
        return false;
      },
      child: Card(
        elevation: status == "active" ? 4 : 0,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: status == "active" ? Colors.green : Colors.red,
            width: 1.0,
          ),
        ),
        child: ListTile(
          title: Text(
            "Student: ${mark['username'] ?? 'N/A'}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            "Marks: ${mark['marks']?.join(', ') ?? 'N/A'}",
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Tooltip(
            message: status == "active" ? "Set inactive" : "Set active",
            child: Switch(
              value: status == "active",
              onChanged: (_) => toggleSingleStatus(id, status),
              activeColor: Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> calculateAndUpdateRanks() async {
    // Split marks into valid and excluded lists
    List<dynamic> validMarks = [];
    List<dynamic> excludedMarks = [];

    for (var mark in allExamMarks) {
      var subjectRankList = mark['subject_rank'] as List<dynamic>?;
      var marksList = mark['marks'] as List<dynamic>?;

      if (subjectRankList == null || marksList == null) {
        excludedMarks.add(mark);
        continue;
      }

      // ❌ Exclude if ANY subject rank <= 0
      bool hasInvalidRank = subjectRankList.any((rank) => rank <= 0);

      // ❌ Exclude if ANY mark is "AA"
      bool hasAbsent = marksList.any(
        (m) => m.toString().trim().toUpperCase() == "AA",
      );

      if (hasInvalidRank || hasAbsent) {
        excludedMarks.add(mark);
      } else {
        validMarks.add(mark);
      }
    }

    // 2. Compute total marks for valid students
    Map<String, int> totalMarksMap = {};
    for (var mark in validMarks) {
      final username = mark['username'].toString();
      final marksRaw = (mark['marks'] as List<dynamic>? ?? []);

      final total = marksRaw.fold<int>(0, (sum, m) {
        if (m is num) return sum + m.toInt();
        if (m is String) {
          final parsed = int.tryParse(m);
          return sum + (parsed ?? 0);
        }
        return sum;
      });

      totalMarksMap[username] = total;
    }

    // 3. Sort by total marks (descending)
    List<MapEntry<String, int>> sortedEntries =
        totalMarksMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // 4. Assign competition ranks
    int currentRank = 1;
    int prevTotal = -1;
    int rankToAssign = 1;
    List<MapEntry<String, int>> rankedEntries = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      if (entry.value != prevTotal) {
        rankToAssign = currentRank;
      }
      prevTotal = entry.value;
      rankedEntries.add(MapEntry(entry.key, rankToAssign));
      currentRank++;
    }

    // 5. Update ranked students with their rank
    for (final entry in rankedEntries) {
      final username = entry.key;
      final rank = entry.value;

      final updateSuccess = await AdminApiService.updateExamMarksByUsername(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
        username: username,
        title: widget.title,
        updateData: {'rank': rank.toString()},
      );

      if (!updateSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update rank for $username')),
          );
        }
      }
    }

    // 6. Update excluded students with rank = -1
    for (final mark in excludedMarks) {
      final username = mark['username'].toString();

      final updateSuccess = await AdminApiService.updateExamMarksByUsername(
        schoolId: int.parse(widget.schoolId),
        classId: int.parse(widget.classId),
        username: username,
        title: widget.title,
        updateData: {'rank': '-1'},
      );

      if (!updateSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set -1 rank for $username')),
          );
        }
      }
    }

    // 7. Final message
    // if (allSuccess) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Ranks updated successfully')),
    //   );
    // }

    await fetchExamMarks();
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
                    title: widget.title,
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: widget.title,
                    onBack: onWillPop,
                  ),
        ),
        body: SmartRefresher(
          enablePullDown: true,
          controller: _refreshController,
          header: const WaterDropHeader(),
          onRefresh: fetchExamMarks,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSummaryCard(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 4,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    labelText: 'Search student',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (query) {
                    setState(() {
                      filterQuery = query;
                      applyFilter();
                    });
                  },
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 15,
              //     vertical: 8,
              //   ),
              //   child: ElevatedButton.icon(
              //     onPressed: () async {
              //       await calculateAndUpdateRanks();
              //     },
              //     icon: const Icon(Icons.stars_rounded, color: Colors.white),
              //     label: const Text(
              //       'Calculate & Update Ranks',
              //       style: TextStyle(color: Colors.white, fontSize: 18),
              //     ),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.blue,
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 16,
              //         vertical: 12,
              //       ),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(14),
              //       ),
              //     ),
              //   ),
              // ),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (filteredExamMarks.isEmpty
                      ? SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.list_alt_rounded,
                                size: 52,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No records found.",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12, top: 0),
                          itemCount: filteredExamMarks.length,
                          itemBuilder: _buildMarkListItem,
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
