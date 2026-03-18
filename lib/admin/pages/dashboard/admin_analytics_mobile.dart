import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/utils.dart';

class AdminAnalyticsMobile extends StatefulWidget {
  final String schoolId;
  final String username;

  const AdminAnalyticsMobile({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AdminAnalyticsMobile> createState() => _AdminAnalyticsMobileState();
}

class _AdminAnalyticsMobileState extends State<AdminAnalyticsMobile> {
  Map<String, dynamic> attendanceTrends = {};
  Map<String, dynamic> feeTrends = {};
  Map<String, dynamic> examTrends = {};
  List<dynamic> classComparisons = [];
  List<dynamic> predictiveInsights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final startDate =
        DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
    final endDate = DateTime.now().toIso8601String();

    // Fetch attendance trends
    final attendanceResponse = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/attendance-trends?school_id=${widget.schoolId}&start_date=$startDate&end_date=$endDate',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (attendanceResponse.statusCode == 200) {
      attendanceTrends = json.decode(attendanceResponse.body)['trends'];
    }

    // Fetch fee trends
    final feeResponse = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/fee-collection-trends?school_id=${widget.schoolId}&start_date=$startDate&end_date=$endDate',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (feeResponse.statusCode == 200) {
      feeTrends = json.decode(feeResponse.body)['trends'];
    }

    // Fetch exam trends
    final examResponse = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/exam-performance-trends?school_id=${widget.schoolId}&start_date=$startDate&end_date=$endDate',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (examResponse.statusCode == 200) {
      examTrends = json.decode(examResponse.body)['trends'];
    }

    // Fetch class comparisons
    final comparisonResponse = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/class-comparisons?school_id=${widget.schoolId}&date=${DateTime.now().toIso8601String().split('T')[0]}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (comparisonResponse.statusCode == 200) {
      classComparisons = json.decode(comparisonResponse.body)['comparisons'];
    }

    // Fetch predictive insights
    final insightsResponse = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/predictive-insights?school_id=${widget.schoolId}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (insightsResponse.statusCode == 200) {
      predictiveInsights = json.decode(insightsResponse.body)['insights'];
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Trends',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      attendanceTrends.entries
                          .map(
                            (e) => FlSpot(
                              double.parse(e.key.split('-')[1]),
                              e.value['present'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Fee Collection Trends',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      feeTrends.entries
                          .map(
                            (e) => FlSpot(
                              double.parse(e.key.split('-')[1]),
                              e.value['collected'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Exam Performance Trends',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      examTrends.entries
                          .map(
                            (e) => FlSpot(
                              double.parse(e.key.split('-')[1]),
                              e.value['average'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Class Comparisons',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...classComparisons.map(
          (comp) => ListTile(
            title: Text(comp['class']),
            subtitle: Text(
              'Attendance: ${comp['attendance_rate'].toStringAsFixed(2)}%, Fees: ${comp['fee_rate'].toStringAsFixed(2)}%, Avg Marks: ${comp['avg_marks'].toStringAsFixed(2)}',
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Predictive Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...predictiveInsights
            .take(10)
            .map(
              (insight) => ListTile(
                title: Text(insight['name']),
                subtitle: Text(
                  'Engagement: ${insight['engagement_score'].toStringAsFixed(2)}',
                ),
              ),
            ),
      ],
    );
  }
}
