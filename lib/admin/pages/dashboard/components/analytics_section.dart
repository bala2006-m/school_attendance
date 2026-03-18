import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsSection extends StatefulWidget {
  final String schoolId;
  final String username;

  const AnalyticsSection({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  Map<String, dynamic> attendanceTrends = {};
  Map<String, dynamic> feeTrends = {};
  Map<String, dynamic> examTrends = {};
  List<dynamic> classComparisons = [];
  List<dynamic> predictiveInsights = [];

  bool isLoading = true;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime endDate = DateTime.now();

  String token = "";
  late String selectedClass;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? "";
    await fetchAnalyticsData();
  }

  String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> fetchAnalyticsData({int? classId, bool isInitial = true}) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      if (classId == null) {
        // Full Refresh
        final responses = await Future.wait([
          HybridApiService.get(
            '/dashboard/attendance-trends?school_id=${widget.schoolId}&start_date=$startDateStr&end_date=$endDateStr',
            headers: {'Authorization': 'Bearer $token'},
          ),
          HybridApiService.get(
            '/dashboard/fee-collection-trends?school_id=${widget.schoolId}&start_date=$startDateStr&end_date=$endDateStr',
            headers: {'Authorization': 'Bearer $token'},
          ),
          HybridApiService.get(
            '/dashboard/exam-performance-trends?school_id=${widget.schoolId}&start_date=$startDateStr&end_date=$endDateStr',
            headers: {'Authorization': 'Bearer $token'},
          ),
          HybridApiService.get(
            '/dashboard/class-comparisons?school_id=${widget.schoolId}&date=$today',
            headers: {'Authorization': 'Bearer $token'},
          ),
          HybridApiService.get(
            '/dashboard/predictive-insights?school_id=${widget.schoolId}',
            headers: {'Authorization': 'Bearer $token'},
          ),
        ]);

        if (responses[0].statusCode == 200) {
          attendanceTrends = json.decode(responses[0].body)['trends'] ?? {};
        }
        if (responses[1].statusCode == 200) {
          feeTrends = json.decode(responses[1].body)['trends'] ?? {};
        }
        if (responses[2].statusCode == 200) {
          examTrends = json.decode(responses[2].body)['trends'] ?? {};
        }
        if (responses[3].statusCode == 200) {
          classComparisons =
              json.decode(responses[3].body)['comparisons'] ?? [];
        }
        if (responses[4].statusCode == 200) {
          predictiveInsights = json.decode(responses[4].body)['insights'] ?? [];
        }
      } else {
        // Class-specific insights only
        final insightsResponse = await HybridApiService.get(
          '/dashboard/predictive-insights?school_id=${widget.schoolId}&class_id=$classId',
          headers: {'Authorization': 'Bearer $token'},
        );
        if (insightsResponse.statusCode == 200) {
          predictiveInsights =
              json.decode(insightsResponse.body)['insights'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Analytics Error: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
      if (classId == null && classComparisons.isNotEmpty) {
        selectedClass = classComparisons[0]['class_name'] as String;
      }
    });

    // Auto-fetch first class insights only on initial full load
    if (isInitial && classId == null && classComparisons.isNotEmpty) {
      await fetchAnalyticsData(
        classId: classComparisons[0]['class_id'],
        isInitial: false,
      );
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      startDate = picked;
      fetchAnalyticsData();
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      endDate = picked;
      fetchAnalyticsData();
    }
  }

  List<FlSpot> buildSpots(Map<String, dynamic> data, String key) {
    final entries =
        data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((e) {
      DateTime date = DateTime.parse("${e.key}-01");

      double value = double.parse(e.value[key].toString());

      return FlSpot(date.month.toDouble(), value);
    }).toList();
  }

  String formatIndianUnits(double value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(1)}Cr";
    } else if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(1)}L";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return value.toInt().toString();
    }
  }

  Widget buildChartCard(
    String title,
    String subtitle,
    Map<String, dynamic> data,
    String key,
    Color color,
    IconData icon,
  ) {
    if (data.isEmpty) {
      return const SizedBox();
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Chart Area with subtle background
                Flexible(
                  child: Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: LineChart(
                    LineChartData(
                      minX: 1,
                      maxX: 12,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  formatIndianUnits(value),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                getMonthName(value.toInt()),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: buildSpots(data, key),
                          isCurved: true,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)],
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.2),
                                color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: color,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildClassTable() {
    if (classComparisons.isEmpty) {
      return const SizedBox();
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Class Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            /// Table
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 40,
                  headingRowHeight: 56,
                  dataRowHeight: 52,
                  dividerThickness: 1,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Class",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        "Attendance",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        "Fees Paid",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        "Avg Marks",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows:
                      classComparisons.asMap().entries.map((entry) {
                        // int index = entry.key;
                        var c = entry.value;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                c["class_name"].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              _buildPercentageIndicator(
                                double.parse(c["attendance_rate"].toString()),
                              ),
                            ),
                            DataCell(
                              _buildPercentageIndicator(
                                double.parse(c["fee_rate"].toString()),
                              ),
                            ),
                            DataCell(
                              Text(
                                double.parse(
                                  c["avg_marks"].toString(),
                                ).toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageIndicator(double value) {
    Color color =
        value >= 85 ? Colors.green : (value >= 70 ? Colors.orange : Colors.red);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text("${value.toStringAsFixed(1)}%"),
      ],
    );
  }

  Widget buildStudentInsights() {
    if (predictiveInsights.isEmpty) {
      return const SizedBox();
    }

    final classes =
        classComparisons
            .map((c) => (c['class_name'] ?? c['class'] ?? 'Unknown').toString())
            .toSet()
            .toList()
          ..sort();

    if (!classes.contains(selectedClass) && classes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedClass = classes[0];
          });
        }
      });
    }

    final filteredInsights =
        predictiveInsights
            .where((s) => (s['class_name'] ?? s['class']) == selectedClass)
            .toList();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.deepPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Student Insights",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  /// Class Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClass,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedClass = newValue;
                            });
                            final comp = classComparisons.firstWhere(
                              (c) => c['class_name'] == newValue,
                              orElse: () => null,
                            );
                            if (comp != null) {
                              fetchAnalyticsData(classId: comp['class_id']);
                            }
                          }
                        },
                        items:
                            classes.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Insights Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 40,
                  horizontalMargin: 16,
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Student",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        "Engagement",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Status",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows:
                      filteredInsights.map((s) {
                        double score = double.parse(
                          s["engagement_score"].toString(),
                        );
                        Color scoreColor =
                            score >= 80
                                ? Colors.green
                                : (score >= 50 ? Colors.orange : Colors.red);

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        s["gender"] == "M"
                                            ? Colors.blue.shade100
                                            : Colors.pink.shade100,
                                    child: Text(
                                      s["name"]
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    s["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      score.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: scoreColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: score / 100,
                                      color: scoreColor,
                                      backgroundColor: scoreColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  score >= 80
                                      ? "Excellent"
                                      : (score >= 50 ? "Steady" : "At Risk"),
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        bool isTablet =
            constraints.maxWidth > 600 && constraints.maxWidth <= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Analytics Overview",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "School performance and trends",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      onPressed: fetchAnalyticsData,
                      tooltip: "Refresh Data",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// Date Pickers Section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: "Start Date",
                        date: startDate,
                        onTap: pickStartDate,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        label: "End Date",
                        date: endDate,
                        onTap: pickEndDate,
                        icon: Icons.event_available_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /// Charts Grid/List
              if (isDesktop || isTablet)
                GridView.count(
                  crossAxisCount: isDesktop ? 3 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 0.85 : 0.8,
                  children: _buildChartList(),
                )
              else
                Column(children: _buildChartList()),

              const SizedBox(height: 32),

              /// Tables Section
              if (classComparisons.isNotEmpty) ...[
                buildClassTable(),
                const SizedBox(height: 32),
              ],

              if (predictiveInsights.isNotEmpty) buildStudentInsights(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  Text(
                    date.toLocal().toString().split(' ')[0],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChartList() {
    return [
      if (attendanceTrends.isNotEmpty)
        buildChartCard(
          "Attendance",
          "Daily presence tracking",
          attendanceTrends,
          "present",
          Colors.blue,
          Icons.people_alt_rounded,
        ),
      if (feeTrends.isNotEmpty)
        buildChartCard(
          "Fee Collection",
          "Revenue and payments",
          feeTrends,
          "collected",
          Colors.green,
          Icons.account_balance_wallet_rounded,
        ),
      if (examTrends.isNotEmpty)
        buildChartCard(
          "Academic Performance",
          "Global exam averages",
          examTrends,
          "average",
          Colors.orange,
          Icons.auto_graph_rounded,
        ),
    ];
  }
}
