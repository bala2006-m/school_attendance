import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardInfographic extends StatelessWidget {
  final Map data;
  const CardInfographic({super.key, required this.data});

  double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final total = _toDouble(data["totalStudents"]);
    final paid = _toDouble(data["totalPaidStudents"]);
    final pending = _toDouble(data["totalPendingStudents"]);
    final totalAmt = _toDouble(data["totalAmount"]);
    final paidAmt = _toDouble(data["totalPaidAmount"]);
    final pendingAmt = _toDouble(data["totalPendingAmount"]);

    final paidPct = (total == 0) ? 0.0 : (paid / total);
    final paidAmtPct = (totalAmt == 0) ? 0.0 : (paidAmt / totalAmt);

    return SizedBox(
      height: 1000,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // top row - 3 big cards
            Row(
              children: [
                Expanded(
                  child: BigInfoCard(
                    title: "Total Students",
                    value: total.toStringAsFixed(0),
                    icon: Icons.groups,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BigInfoCard(
                    title: "Paid",
                    value: paid.toStringAsFixed(0),
                    subtitle: "${(paidPct * 100).toStringAsFixed(0)}% Paid",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BigInfoCard(
                    title: "Pending",
                    value: pending.toStringAsFixed(0),
                    subtitle:
                        "${(100 - paidPct * 100).toStringAsFixed(0)}% Pending",
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // amount cards
            Row(
              children: [
                Expanded(
                  child: AmountCard(title: "Total Amount", amount: totalAmt),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AmountCard(
                    title: "Paid Amount",
                    amount: paidAmt,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AmountCard(
                    title: "Pending Amount",
                    amount: pendingAmt,
                    accent: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // progress bars with labels
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Progress Overview",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProgressRow(
                      label: "Students Paid",
                      pct: paidPct,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    ProgressRow(
                      label: "Amount Collected",
                      pct: paidAmtPct,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BigInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const BigInfoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color.darken(0.2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color.darken(0.2),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(color: color.darken(0.35))),
          ],
        ],
      ),
    );
  }
}

class AmountCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool highlight;
  final Color? accent;
  const AmountCard({
    super.key,
    required this.title,
    required this.amount,
    this.highlight = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? (highlight ? Colors.green : Colors.indigo);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: c.darken(0.2), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: c.darken(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRow extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const ProgressRow({
    super.key,
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayPct = (pct * 100).clamp(0.0, 100.0);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: pct, minHeight: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text("${displayPct.toStringAsFixed(0)}%"),
      ],
    );
  }
}

// small color helper extension
extension ColorX on Color {
  Color darken([double amount = .1]) {
    final f = 1 - amount;
    return Color.fromARGB(
      (a * 255.0).round(),
      (r * f).round(),
      (g * f).round(),
      (b * f).round(),
    );
  }
}

class GraphicalDashboard extends StatelessWidget {
  final Map data;
  const GraphicalDashboard({super.key, required this.data});

  double _toDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final total = _toDouble(data["totalStudents"]);
    final paid = _toDouble(data["totalPaidStudents"]);
    final pending = _toDouble(data["totalPendingStudents"]);
    final paidAmt = _toDouble(data["totalPaidAmount"]);
    final pendingAmt = _toDouble(data["totalPendingAmount"]);
    final paidPct = (total == 0) ? 0.0 : (paid / total);

    return SizedBox(
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // top: ring + key stats
            Row(
              children: [
                // ring
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  percent: paidPct.clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(paidPct * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text("Paid", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  progressColor: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      StatTile(
                        label: "Total Students",
                        value: total.toStringAsFixed(0),
                      ),
                      const SizedBox(height: 8),
                      StatTile(
                        label: "Paid Students",
                        value: paid.toStringAsFixed(0),
                        accent: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      StatTile(
                        label: "Pending Students",
                        value: pending.toStringAsFixed(0),
                        accent: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // pie chart for amounts
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Amount Distribution",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          // Pie
                          Expanded(
                            flex: 5,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: paidAmt,
                                    color: Colors.blue,
                                    title: "Paid",
                                  ),
                                  PieChartSectionData(
                                    value: pendingAmt,
                                    color: Colors.orange,
                                    title: "Pending",
                                  ),
                                ],
                                centerSpaceRadius: 40,
                                sectionsSpace: 4,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Legend & small bar comparison
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LegendDot(
                                  color: Colors.blue,
                                  text: "Paid: ₹${paidAmt.toStringAsFixed(0)}",
                                ),
                                const SizedBox(height: 8),
                                LegendDot(
                                  color: Colors.orange,
                                  text:
                                      "Pending: ₹${pendingAmt.toStringAsFixed(0)}",
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Amount Comparison",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // small bars
                                MiniBar(
                                  label: "Paid Amount",
                                  value: paidAmt,
                                  max: paidAmt + pendingAmt,
                                ),
                                const SizedBox(height: 8),
                                MiniBar(
                                  label: "Pending Amount",
                                  value: pendingAmt,
                                  max: paidAmt + pendingAmt,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  const MiniBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (max <= 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(label), Text("₹${value.toStringAsFixed(0)}")],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: pct, minHeight: 10),
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c)),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const LegendDot({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
