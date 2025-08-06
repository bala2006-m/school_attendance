// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class AttendanceGraphBuilder {
//   static Widget buildAttendanceGraph(BuildContext context) {
//     final List<Map<String, dynamic>> attendanceData = [];
//     int dayOffset = 0;
//
//     // Generate last 7 working days
//     while (attendanceData.length < 7) {
//       final date = DateTime.now().subtract(Duration(days: dayOffset));
//       if (date.weekday != DateTime.sunday) {
//         attendanceData.add({
//           'date': date,
//           'attendance': 80 + attendanceData.length * 2, // Dummy increasing
//         });
//       }
//       dayOffset++;
//     }
//
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Container(
//           width: constraints.maxWidth,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Attendance Over Last 7 Working Days',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.3,
//                 child: LineChart(
//                   LineChartData(
//                     lineTouchData: LineTouchData(
//                       enabled: true,
//                       touchTooltipData: LineTouchTooltipData(
//                         tooltipBgColor: Colors.white,
//                         tooltipRoundedRadius: 8,
//                         getTooltipItems: (List<LineBarSpot> touchedSpots) {
//                           return touchedSpots.map((spot) {
//                             final date =
//                                 attendanceData[spot.x.toInt()]['date']
//                                     as DateTime;
//                             return LineTooltipItem(
//                               '${DateFormat('EEEE').format(date)}\n${spot.y.toInt()}%',
//                               const TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             );
//                           }).toList();
//                         },
//                       ),
//                     ),
//                     gridData: FlGridData(
//                       show: true,
//                       drawVerticalLine: false,
//                       horizontalInterval: 10,
//                       getDrawingHorizontalLine:
//                           (value) => FlLine(
//                             color: Colors.grey.withOpacity(0.2),
//                             strokeWidth: 1,
//                           ),
//                     ),
//                     titlesData: FlTitlesData(
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           interval: 20,
//                           getTitlesWidget:
//                               (value, _) => Text(
//                                 '${value.toInt()}%',
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                           reservedSize: 32,
//                         ),
//                       ),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, _) {
//                             int index = value.toInt();
//                             if (index < 0 || index >= attendanceData.length) {
//                               return const SizedBox.shrink();
//                             }
//                             final date =
//                                 attendanceData[index]['date'] as DateTime;
//                             return Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Text(
//                                 DateFormat('E').format(date), // Short weekday
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       rightTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       topTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     borderData: FlBorderData(
//                       show: true,
//                       border: const Border(
//                         bottom: BorderSide(color: Colors.grey),
//                         left: BorderSide(color: Colors.grey),
//                       ),
//                     ),
//                     minY: 0,
//                     maxY: 100,
//                     lineBarsData: [
//                       LineChartBarData(
//                         isCurved: true,
//                         curveSmoothness: 0.25,
//                         spots:
//                             attendanceData.asMap().entries.map((e) {
//                               return FlSpot(
//                                 e.key.toDouble(),
//                                 e.value['attendance'].toDouble(),
//                               );
//                             }).toList(),
//                         barWidth: 3,
//                         isStrokeCapRound: true,
//                         color: Colors.blueAccent,
//                         belowBarData: BarAreaData(
//                           show: true,
//                           color: Colors.blueAccent.withOpacity(0.2),
//                         ),
//                         dotData: FlDotData(show: true),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
