import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/bus_fee_payment_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';
import '../add_bus_fees/widget/stats.dart';

class ViewBusFeeStatus extends StatefulWidget {
  const ViewBusFeeStatus({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<ViewBusFeeStatus> createState() => _ViewBusFeeStatusState();
}

class _ViewBusFeeStatusState extends State<ViewBusFeeStatus> {
  Map<String, dynamic> allPaidPendingBusFee = {};
  bool isLoading = true;
  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final pendingPaid = await BusFeePaymentApi.getPaidPendingBySchoolId(
      int.parse(widget.schoolId),
    );

    setState(() {
      allPaidPendingBusFee = pendingPaid!;
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
                    title: 'Bus Fee Status',
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
                      GraphicalDashboard(data: allPaidPendingBusFee),
                    ],
                  ),
                ),
      ),
    );
  }
}
