import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalysisCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final String totalStudents;
  final String presentStudentFN;
  final String totalStaff;
  final String presentStaffFN;
  final String presentStudentAN;
  final String presentStaffAN;
  final Map<String, dynamic> allPendingTermFees;
  final Map<String, dynamic> allPendingBusFees;
  final Map<String, dynamic> allPendingRteFees;

  const AnalysisCard({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.totalStudents,
    required this.presentStudentFN,
    required this.totalStaff,
    required this.presentStaffFN,
    required this.presentStudentAN,
    required this.presentStaffAN,
    required this.allPendingTermFees,
    required this.allPendingBusFees,
    required this.allPendingRteFees,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentages
    int totalStudentsInt = int.tryParse(totalStudents) ?? 0;
    int presentStudentFNInt = int.tryParse(presentStudentFN) ?? 0;
    int presentStudentANInt = int.tryParse(presentStudentAN) ?? 0;
    int totalStaffInt = int.tryParse(totalStaff) ?? 0;
    int presentStaffFNInt = int.tryParse(presentStaffFN) ?? 0;
    int presentStaffANInt = int.tryParse(presentStaffAN) ?? 0;

    double studentAttendancePercentFN =
        totalStudentsInt > 0
            ? (presentStudentFNInt / totalStudentsInt) * 100
            : 0;
    double studentAttendancePercentAN =
        totalStudentsInt > 0
            ? (presentStudentANInt / totalStudentsInt) * 100
            : 0;
    double staffAttendancePercentFN =
        totalStaffInt > 0 ? (presentStaffFNInt / totalStaffInt) * 100 : 0;
    double staffAttendancePercentAN =
        totalStaffInt > 0 ? (presentStaffANInt / totalStaffInt) * 100 : 0;

    // Calculate total pending fees
    double totalPendingTerm =
        double.tryParse(
          allPendingTermFees['totalPendingAmount']?.toString() ?? '0',
        ) ??
        0;
    double totalPendingBus =
        double.tryParse(
          allPendingBusFees['totalPendingAmount']?.toString() ?? '0',
        ) ??
        0;
    double totalPendingRte =
        double.tryParse(
          allPendingRteFees['totalPendingAmount']?.toString() ?? '0',
        ) ??
        0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          // Attendance Analysis
          const Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  'Students FN',
                  '${studentAttendancePercentFN.toStringAsFixed(1)}%',
                  Icons.school,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisItem(
                  'Students AN',
                  '${studentAttendancePercentAN.toStringAsFixed(1)}%',
                  Icons.school_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  'Staff FN',
                  '${staffAttendancePercentFN.toStringAsFixed(1)}%',
                  Icons.person,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisItem(
                  'Staff AN',
                  '${staffAttendancePercentAN.toStringAsFixed(1)}%',
                  Icons.person_outline,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Attendance Chart
          const Text(
            'Attendance Chart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: studentAttendancePercentFN,
                        color: Colors.green,
                        width: 20,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: studentAttendancePercentAN,
                        color: Colors.blue,
                        width: 20,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: staffAttendancePercentFN,
                        color: Colors.orange,
                        width: 20,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: staffAttendancePercentAN,
                        color: Colors.purple,
                        width: 20,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Stu FN',
                          'Stu AN',
                          'Staff FN',
                          'Staff AN',
                        ];
                        return Text(
                          titles[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // AI Insights
          const Text(
            'AI Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildAIInsights(
            studentAttendancePercentFN,
            studentAttendancePercentAN,
            staffAttendancePercentFN,
            staffAttendancePercentAN,
            totalPendingTerm,
            totalPendingBus,
            totalPendingRte,
          ),
          const Text(
            'Pending Fees Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFeeItem(
                  'Term Fees',
                  totalPendingTerm,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeeItem(
                  'Bus Fees',
                  totalPendingBus,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeeItem('RTE Fees', totalPendingRte, Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAIInsights(
    double studentFN,
    double studentAN,
    double staffFN,
    double staffAN,
    double termFees,
    double busFees,
    double rteFees,
  ) {
    List<Widget> insights = [];

    // Attendance insights
    if (studentFN < 70) {
      insights.add(
        _buildInsightItem(
          'Student attendance (FN) is low. Consider implementing attendance incentives or reminders.',
          Icons.warning,
          Colors.red,
        ),
      );
    } else if (studentFN > 90) {
      insights.add(
        _buildInsightItem(
          'Excellent student attendance (FN)! Keep up the good work.',
          Icons.thumb_up,
          Colors.green,
        ),
      );
    }

    if (studentAN < 70) {
      insights.add(
        _buildInsightItem(
          'Student attendance (AN) is low. Afternoon sessions may need more engagement.',
          Icons.warning,
          Colors.red,
        ),
      );
    }

    if (staffFN < 80) {
      insights.add(
        _buildInsightItem(
          'Staff attendance (FN) needs attention. Ensure staff well-being and motivation.',
          Icons.warning,
          Colors.orange,
        ),
      );
    }

    // Fee insights
    if (termFees > 10000) {
      insights.add(
        _buildInsightItem(
          'High pending term fees. Consider sending reminders or payment plans.',
          Icons.account_balance_wallet,
          Colors.blue,
        ),
      );
    }

    if (busFees > 5000) {
      insights.add(
        _buildInsightItem(
          'Significant bus fees pending. Review transportation fee collection.',
          Icons.directions_bus,
          Colors.purple,
        ),
      );
    }

    if (rteFees > 2000) {
      insights.add(
        _buildInsightItem(
          'RTE fees outstanding. Follow up on government scheme reimbursements.',
          Icons.school,
          Colors.teal,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        _buildInsightItem(
          'Everything looks good! Attendance and fee collection are on track.',
          Icons.check_circle,
          Colors.green,
        ),
      );
    }

    return insights;
  }

  Widget _buildInsightItem(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
