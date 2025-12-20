import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Format numbers into K, L, C (Indian format)
String formatAmount(num value) {
  if (value >= 10000000) {
    return "${(value / 10000000).toStringAsFixed(1)}C";
  } else if (value >= 100000) {
    return "${(value / 100000).toStringAsFixed(1)}L";
  } else if (value >= 1000) {
    return "${(value / 1000).toStringAsFixed(1)}K";
  }
  return value.toString();
}

Map<String, int> safeStringMap(dynamic data) {
  if (data == null || data is! Map) return {};
  return data.map<String, int>((key, value) {
    return MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0);
  });
}

class ClassFeeDashboard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ClassFeeDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // final classStudents = safeStringMap(data["classStudent"]);
    // final paidStudents = safeStringMap(data["PaidStudents"]);
    // final pendingStudents = safeStringMap(data["pendingStudents"]);
    final classPaidAmount = safeStringMap(data["classPaidAmount"]);
    final classPendingAmount = safeStringMap(data["classPendingAmount"]);

    int totalStudents = data["totalClassStudent"] ?? 0;
    int totalPaid = data["totalPaidStudent"] ?? 0;
    int totalPending = data["totalPendingStudent"] ?? 0;

    int totalPaidAmount = data["totalPaidAmount"] ?? 0;
    int totalPendingAmount = data["totalPendingAmount"] ?? 0;

    double paidPercent = totalStudents == 0 ? 0 : (totalPaid / totalStudents);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSummary(paidPercent, totalStudents, totalPaid, totalPending),
          const SizedBox(height: 25),
          _buildTotalAmountBar(totalPaidAmount, totalPendingAmount),
          const SizedBox(height: 25),
          _buildPerClassBarChart(classPaidAmount, classPendingAmount),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

/// SUMMARY CARD
Widget _buildTopSummary(double paidPercent, int total, int paid, int pending) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Row(
      children: [
        CircularPercentIndicator(
          radius: 70,
          lineWidth: 12,
          percent: paidPercent.clamp(0, 1),
          animation: true,
          progressColor: Colors.green,
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          circularStrokeCap: CircularStrokeCap.round,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(paidPercent * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("PAID"),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _statRow("Total Students", total.toString()),
              _statRow("Paid Students", paid.toString(), Colors.green),
              _statRow("Pending Students", pending.toString(), Colors.red),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _statRow(String label, String value, [Color? color]) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// TOTAL AMOUNT (PAID VS PENDING)
Widget _buildTotalAmountBar(int paid, int pending) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Column(
      children: [
        const Text(
          "Total Paid vs Pending Amount",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget:
                        (value, _) => Text(
                          formatAmount(value),
                          style: const TextStyle(fontSize: 12),
                        ),
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget:
                        (value, _) => Text(
                          formatAmount(value),
                          style: const TextStyle(fontSize: 12),
                        ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (v, _) => Text(v == 0 ? "Paid" : "Pending"),
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: paid.toDouble(),
                      color: Colors.green,
                      width: 32,
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: pending.toDouble(),
                      color: Colors.red,
                      width: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// PER CLASS PAID VS PENDING
Widget _buildPerClassBarChart(Map<String, int> paid, Map<String, int> pending) {
  final classKeys = paid.keys.toList();

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Column(
      children: [
        const Text(
          "Per Class Paid vs Pending Amount",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget:
                        (value, _) => Text(
                          formatAmount(value),
                          style: const TextStyle(fontSize: 12),
                        ),
                  ),
                ),

                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget:
                        (value, _) => Text(
                          formatAmount(value),
                          style: const TextStyle(fontSize: 12),
                        ),
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // ⭐ FIXED (forces class label display)
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= classKeys.length) {
                        return const Text("");
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 6),
                        child: Text(
                          classKeys[index], // ⭐ NOW class-section appears
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),

              barGroups: List.generate(classKeys.length, (index) {
                final classKey = classKeys[index];

                return BarChartGroupData(
                  x: index,
                  barsSpace: 10,
                  barRods: [
                    BarChartRodData(
                      toY: (paid[classKey] ?? 0).toDouble(),
                      color: Colors.green,
                      width: 18,
                    ),
                    BarChartRodData(
                      toY: (pending[classKey] ?? 0).toDouble(),
                      color: Colors.red,
                      width: 18,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    ),
  );
}

Decoration _box() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
);

// Color _colorForIndex(int i) {
//   final colors = [
//     Colors.blue,
//     Colors.orange,
//     Colors.green,
//     Colors.indigo,
//     Colors.purple,
//     Colors.teal,
//   ];
//   return colors[i % colors.length];
// }
