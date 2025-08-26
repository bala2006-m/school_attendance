import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.classes,
    required this.staffs,
    required this.students,
    required this.admins,
  });
  final List<dynamic> classes;
  final List<dynamic> staffs;
  final List<dynamic> students;
  final List<dynamic> admins;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24), // 🔹 More spacing
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800; // Desktop vs Mobile

            return isWide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pie Chart (bigger)
                    SizedBox(
                      width: constraints.maxWidth * 0.45,
                      height: 450, // 🔹 Bigger chart
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: classes.length.toDouble(),
                              color: Colors.blue.shade900,
                              title: "Cls",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // 🔹 Bigger labels
                              ),
                            ),
                            PieChartSectionData(
                              value: admins.length.toDouble(),
                              color: Colors.blue.shade700,
                              title: "Adm",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            PieChartSectionData(
                              value: staffs.length.toDouble(),
                              color: Colors.teal.shade400,
                              title: "Stf",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            PieChartSectionData(
                              value: students.length.toDouble(),
                              color: Colors.cyan.shade400,
                              title: "Stu",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          centerSpaceRadius: 0,
                          sectionsSpace: 3,
                        ),
                      ),
                    ),

                    const SizedBox(width: 40),

                    // Legends
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "School Overview",
                            style: TextStyle(
                              fontSize: 28, // 🔹 Bigger title
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Summary of classes, admins, staffs and students",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _buildLegend(
                            "Classes",
                            classes.length,
                            Colors.blue.shade900,
                          ),
                          _buildLegend(
                            "Admins",
                            admins.length,
                            Colors.blue.shade700,
                          ),
                          _buildLegend(
                            "Staffs",
                            staffs.length,
                            Colors.teal.shade400,
                          ),
                          _buildLegend(
                            "Students",
                            students.length,
                            Colors.cyan.shade400,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              radius: 100,
                              value: classes.length.toDouble(),
                              color: Colors.blue.shade900,
                              title: "Class",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              radius: 100,
                              value: admins.length.toDouble(),
                              color: Colors.blue.shade700,
                              title: "Admin",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              radius: 100,
                              value: staffs.length.toDouble(),
                              color: Colors.teal.shade400,
                              title: "Staff",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              radius: 100,
                              value: students.length.toDouble(),
                              color: Colors.cyan.shade400,
                              title: "Student",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          centerSpaceRadius: 0,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Legends stacked
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "School Overview",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Summary of classes, admins, staffs and students",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        _buildLegend(
                          "Classes",
                          classes.length,
                          Colors.blue.shade900,
                        ),
                        _buildLegend(
                          "Admins",
                          admins.length,
                          Colors.blue.shade700,
                        ),
                        _buildLegend(
                          "Staffs",
                          staffs.length,
                          Colors.teal.shade400,
                        ),
                        _buildLegend(
                          "Students",
                          students.length,
                          Colors.cyan.shade400,
                        ),
                      ],
                    ),
                  ],
                );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 18,
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
