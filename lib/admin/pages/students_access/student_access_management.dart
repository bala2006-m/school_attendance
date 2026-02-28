import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';

class StudentAccessManagement extends StatefulWidget {
  final String schoolId;
  final String username;

  const StudentAccessManagement({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentAccessManagement> createState() =>
      _StudentAccessManagementState();
}

class _StudentAccessManagementState extends State<StudentAccessManagement> {
  bool viewHomework = false;
  bool events = false;
  bool message = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAccess();
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pop(context);
    return false;
  }

  Future<void> fetchAccess() async {
    setState(() => isLoading = true);
    final school = await StudentApiServices.fetchSchoolData(widget.schoolId);

    final Map<String, dynamic> access = school[0]['student_access'] ?? {};

    if (mounted) {
      setState(() {
        viewHomework = access['viewHomework'] ?? false;
        events = access['events'] ?? false;
        message = access['message'] ?? false;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveAccess() async {
    final success = await ApiService.updateStudentAccess(
      schoolId: int.parse(widget.schoolId),
      viewHomework: viewHomework,
      events: events,
      message: message,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success.isNotEmpty
              ? 'Access updated successfully'
              : 'Failed to update access',
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
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student Access',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pop(context);
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Student Access',
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pop(context);
                    },
                  ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child:
              isLoading
                  ? const Center(
                    child: SpinKitFadingCircle(
                      color: Colors.blueAccent,
                      size: 60.0,
                    ),
                  )
                  : SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 48,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Student Access Control',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Manage feature availability for students. Toggle the switches below to enable or disable specific features.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Switches
                              _buildSwitch(
                                title: 'View Homework',
                                subtitle:
                                    'Allow students to view assigned homework',
                                value: viewHomework,
                                icon: Icons.menu_book_rounded,
                                activeColor: Colors.purple,
                                onChanged:
                                    (v) => setState(() => viewHomework = v),
                              ),
                              const SizedBox(height: 16),
                              _buildSwitch(
                                title: 'Events & Calendar',
                                subtitle: 'Show upcoming school events',
                                value: events,
                                icon: Icons.calendar_month_rounded,
                                activeColor: Colors.orange,
                                onChanged: (v) => setState(() => events = v),
                              ),
                              const SizedBox(height: 16),
                              _buildSwitch(
                                title: 'Messaging System',
                                subtitle: 'Enable communication features',
                                value: message,
                                icon: Icons.chat_bubble_rounded,
                                activeColor: Colors.green,
                                onChanged: (v) => setState(() => message = v),
                              ),

                              const SizedBox(height: 40),

                              // Save Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: saveAccess,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Colors.blue.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              value ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        value
                            ? activeColor.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: value ? activeColor : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: value ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  activeTrackColor: activeColor.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
