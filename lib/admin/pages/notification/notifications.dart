import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';

class Notifications extends StatefulWidget {
  const Notifications({
    super.key,
    required this.schoolId,
    required this.username,
  });

  final String schoolId;
  final String username;

  @override
  State<Notifications> createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> {
  List<Map<String, dynamic>> schoolDatas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      setState(() {
        schoolDatas = schoolData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load school info")),
        );
      }
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dateFormat = DateFormat('MMM d, yyyy');
    final today = DateTime.now();

    // Filter schools that actually have notifications
    final filteredSchools =
        schoolDatas.where((school) {
          if (school['dueDate'] == null) return false;
          try {
            final dueDate = DateTime.parse(school['dueDate']);
            final diffDays = dueDate.difference(today).inDays;
            return diffDays < 0 || (diffDays >= 0 && diffDays <= 5);
          } catch (_) {
            return false;
          }
        }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Notifications',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Notifications',
                    onBack: () => onWillPop(),
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
                : filteredSchools.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 90,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No new notifications",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredSchools.length,
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    final dueDate = DateTime.parse(school['dueDate']);
                    final diffDays = dueDate.difference(today).inDays;

                    String message = '';
                    Color bgColor = Colors.white;
                    Color textColor = Colors.black87;
                    IconData icon = Icons.notifications_active_rounded;

                    // Define color schemes for clarity
                    if (dueDate.isBefore(today)) {
                      final daysOverdue =
                          DateTime.now().difference(dueDate).inDays;
                      message =
                          "Your payment is overdue by $daysOverdue days.\nIt was due on ${dateFormat.format(dueDate)}.\nPlease make the payment as soon as possible.";

                      bgColor = const Color(0xFFFFE5E5);
                      textColor = const Color(0xFFD32F2F);
                      icon = Icons.warning_amber_rounded;
                    } else if (diffDays >= 0 && diffDays <= 5) {
                      message =
                          "Only $diffDays days remaining before the due date.\nPlease ensure payment by ${dateFormat.format(dueDate)}.";
                      bgColor = const Color(0xFFFFF4E5);
                      textColor = const Color(0xFFF57C00);
                      icon = Icons.hourglass_top_rounded;
                    }

                    return InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      splashColor: textColor.withValues(alpha: 0.1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              bgColor.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.25),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: textColor.withValues(alpha: 0.15),
                            child: Icon(icon, color: textColor, size: 26),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Reminder',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              if (school['city'] != null)
                                Text(
                                  school['city'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RichText(
                              text: TextSpan(
                                text: message.split('(').first,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                                children: [
                                  if (message.contains('('))
                                    TextSpan(
                                      text: '(${message.split('(').last}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor.withValues(alpha: 0.9),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // trailing: Column(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     Icon(
                          //       Icons.calendar_today_rounded,
                          //       color: textColor.withOpacity(0.8),
                          //       size: 20,
                          //     ),
                          //     const SizedBox(height: 4),
                          //     Text(
                          //       dateFormat.format(dueDate),
                          //       style: TextStyle(
                          //         fontSize: 12,
                          //         color: textColor.withOpacity(0.8),
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
