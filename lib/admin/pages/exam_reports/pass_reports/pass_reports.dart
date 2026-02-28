import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/exam_reports/pass_reports/pass_report_page.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';

class PassReports extends StatefulWidget {
  const PassReports({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<PassReports> createState() => _PassReportsState();
}

class _PassReportsState extends State<PassReports> {
  List<dynamic> titles = [];
  bool isLoading = true;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetch();
    });
    super.initState();
  }

  Future<void> fetch() async {
    titles = await AdminApiService.fetchExamMarkSchoolTitles(
      schoolId: widget.schoolId,
    );

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
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

  Future<void> handleBuild({required String title}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PassReportPage(
              username: widget.username,
              schoolId: widget.schoolId,
              title: title,
            ),
      ),
    );
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
                    title: 'Pass Reports',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Pass Reports',
                    onBack: () {
                      onWillPop();
                    },
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
                : titles.isEmpty
                ? const Center(
                  child: Text(
                    'No exam reports available.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Available Exam Reports",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...titles.map((item) {
                        final title = item['title'] ?? 'Untitled';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              handleBuild(title: title);
                            },
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      ),
    );
  }
}
