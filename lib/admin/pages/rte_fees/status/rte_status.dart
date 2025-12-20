import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/rte_fees_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../bus_fees/add_bus_fees/widget/stats.dart';
import '../../dashboard/admin_dashboard.dart';

class RteStatus extends StatefulWidget {
  const RteStatus({super.key, required this.username, required this.schoolId});
  final String username;
  final String schoolId;
  @override
  State<RteStatus> createState() => _RteStatusState();
}

class _RteStatusState extends State<RteStatus> {
  final RteFeesService _service = RteFeesService();
  Map<String, dynamic> allPaidPendingRteFee = {};
  bool isLoading = true;
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final pendingPaid = await _service.countRtePaidStudents(
      int.parse(widget.schoolId),
    );

    setState(() {
      allPaidPendingRteFee = pendingPaid;
      isLoading = false;
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
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
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'RTE Fee Status',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bus Fee Status',
                    onBack: onWillPop,
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(color: Colors.blue, size: 50),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      GraphicalDashboard(data: allPaidPendingRteFee),
                    ],
                  ),
                ),
      ),
    );
  }
}
