import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';

class StaffAccess extends StatefulWidget {
  const StaffAccess({
    super.key,
    required this.schoolId,
    required this.username,
  });

  final String schoolId;
  final String username;

  @override
  State<StaffAccess> createState() => _StaffAccessState();
}

class _StaffAccessState extends State<StaffAccess> {
  List<Map<String, dynamic>> staffs = [];
  Map<String, Map<String, dynamic>> staffAccessData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      staffs = await AdminApiService.fetchStaffData(widget.schoolId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load Admin data")),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Fetch access for selected admin
  Future<void> fetchStaffAccess(String username) async {
    final response = await AdminApiService.fetchStaffAccess(
      schoolId: widget.schoolId,
      username: username,
    );

    if (response != null &&
        response['data'] != null &&
        response['data']['access'] != null) {
      Map<String, dynamic>? accessData;

      /// Check structure to correctly extracting the map
      if (response['data']['access'] is Map) {
        // Try to see if it's nested 'access' -> 'access' (Map)
        if (response['data']['access']['access'] is Map) {
          accessData = Map<String, dynamic>.from(
            response['data']['access']['access'],
          );
        } else {
          // Otherwise, assume 'access' is the map itself
          accessData = Map<String, dynamic>.from(response['data']['access']);
        }
      }

      if (accessData != null && mounted) {
        setState(() {
          staffAccessData[username] = accessData!;
        });
      }
    }
  }

  /// Update access in DB
  Future<void> updateAccess({
    required String username,
    required Map<String, dynamic> access,
  }) async {
    try {
      await AdminApiService.updateStaffAccess(
        schoolId: int.parse(widget.schoolId),
        username: username,
        access: access,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update access")),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) onWillPop();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Staff Access',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Staff Access',
                    onBack: onWillPop,
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
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: staffs.length,
                    itemBuilder: (context, index) {
                      final staff = staffs[index];
                      final username = staff['username'].toString();

                      final accessMap = staffAccessData[username];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  (staff['name'] ?? "A")
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              staff['name'] ?? "No Name",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "Username: $username",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            onExpansionChanged: (expanded) async {
                              if (expanded &&
                                  staffAccessData[username] == null) {
                                await fetchStaffAccess(username);
                              }
                            },
                            children:
                                accessMap == null
                                    ? [
                                      const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: SpinKitThreeBounce(
                                          color: Colors.blueAccent,
                                          size: 20.0,
                                        ),
                                      ),
                                    ]
                                    : [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          0,
                                          20,
                                          20,
                                        ),
                                        child: Column(
                                          children: [
                                            /// -------- SERVICES --------
                                            _buildSectionHeader(
                                              "ATTENDANCE",
                                              Colors.blue,
                                            ),

                                            if (accessMap.containsKey(
                                              'student',
                                            ))
                                              _buildAccessSwitch(
                                                title: "STUDENT",
                                                value:
                                                    accessMap['student'] ==
                                                    true,
                                                activeColor: Colors.blue,
                                                icon: Icons.people_alt_rounded,
                                                onChanged: (value) async {
                                                  setState(() {
                                                    accessMap['student'] =
                                                        value;
                                                  });
                                                  await updateAccess(
                                                    username: username,
                                                    access: accessMap,
                                                  );
                                                },
                                              ),

                                            if (accessMap.containsKey('myself'))
                                              _buildAccessSwitch(
                                                title: "MYSELF",
                                                value:
                                                    accessMap['myself'] == true,
                                                activeColor: Colors.blue,
                                                icon: Icons.school_rounded,
                                                onChanged: (value) async {
                                                  setState(() {
                                                    accessMap['myself'] = value;
                                                  });
                                                  await updateAccess(
                                                    username: username,
                                                    access: accessMap,
                                                  );
                                                },
                                              ),

                                            const SizedBox(height: 16),

                                            /// -------- MANAGE + OTHERS --------
                                            _buildSectionHeader(
                                              "MANAGE",
                                              Colors.green,
                                            ),

                                            ...accessMap.entries
                                                .where(
                                                  (entry) =>
                                                      entry.key != 'myself' &&
                                                      entry.key != 'student',
                                                )
                                                .map(
                                                  (entry) => _buildAccessSwitch(
                                                    title: _formatKey(
                                                      entry.key,
                                                    ),
                                                    value: entry.value == true,
                                                    activeColor: Colors.green,
                                                    icon:
                                                        Icons
                                                            .admin_panel_settings_rounded,
                                                    onChanged: (value) async {
                                                      setState(() {
                                                        accessMap[entry.key] =
                                                            value;
                                                      });
                                                      await updateAccess(
                                                        username: username,
                                                        access: accessMap,
                                                      );
                                                    },
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                    ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
        ],
      ),
    );
  }

  Widget _buildAccessSwitch({
    required String title,
    required bool value,
    required Color activeColor,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              value ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? activeColor.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? activeColor : Colors.grey.shade400,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: value ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        value: value,
        activeColor: activeColor,
        activeTrackColor: activeColor.withValues(alpha: 0.2),
        onChanged: onChanged,
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .toUpperCase();
  }
}
