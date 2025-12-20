import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/term_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';
import '../widget/admin_fee_stats.dart';

class ViewTermFeeStatus extends StatefulWidget {
  const ViewTermFeeStatus({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<ViewTermFeeStatus> createState() => _ViewTermFeeStatusState();
}

class _ViewTermFeeStatusState extends State<ViewTermFeeStatus> {
  bool isLoading = true;
  Map<String, dynamic> allTermFees = {};
  @override
  void initState() {
    super.initState();
    fetchPaidPending();
  }

  Future<void> fetchPaidPending() async {
    final allPendingTermFee = await TermFeeStructureApi.countAllPendingTermFees(
      int.parse(widget.schoolId),
    );
    setState(() {
      allTermFees = allPendingTermFee;
      // print(allTermFees);
      isLoading = false;
    });
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Fee Status',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'View Fee Status',

                    onBack: () {
                      onWillPop();
                    },
                  ),
        ),
        body:
            isLoading
                ? Center(
                  child: const SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [ClassFeeDashboard(data: allTermFees)],
                  ),
                ),
      ),
    );
  }
}
