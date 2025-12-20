import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/bus_fee_structure_api.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class ActivateBusFees extends StatefulWidget {
  const ActivateBusFees({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<ActivateBusFees> createState() => _ActivateBusFeesState();
}

class _ActivateBusFeesState extends State<ActivateBusFees> {
  bool isLoading = true;
  List<dynamic> allTermFees = [];
  final BusFeeStructureApi api = BusFeeStructureApi();
  @override
  void initState() {
    super.initState();
    fetchPaidPending();
  }

  Future<void> fetchPaidPending() async {
    final data = await BusFeeStructureApi.getStructuresBySchool(
      int.parse(widget.schoolId),
    );
    setState(() {
      allTermFees = data;
      isLoading = false;
    });
  }

  Future<void> toggleAllForTerm(String term, bool newStatus) async {
    final feesToUpdate = allTermFees.where((e) => e['term'] == term).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: SpinKitFadingCircle(color: Colors.blue, size: 55),
          ),
    );

    setState(() {
      for (var f in feesToUpdate) {
        f['status'] = newStatus ? 'active' : 'inactive';
      }
    });

    for (var f in feesToUpdate) {
      await api.toggleStatusById(
        int.parse(f['id'].toString()),
        newStatus ? 'active' : 'inactive',
        widget.username,
      );
    }
    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "All fees under $term set to ${newStatus ? 'ACTIVE' : 'INACTIVE'}",
          ),
          backgroundColor: newStatus ? Colors.green : Colors.red,
        ),
      );
    }
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

    final terms = allTermFees.map((e) => e['term'].toString()).toSet().toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fa),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Activate Bus Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Activate Bus Fees',
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
                    size: 60,
                  ),
                )
                : DefaultTabController(
                  length: terms.length,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TabBar(
                          isScrollable: true,
                          indicator: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          tabs: [for (var t in terms) Tab(text: t)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TabBarView(
                          children: [for (var t in terms) buildTabContent(t)],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget buildTabContent(String term) {
    final fees = allTermFees.where((e) => e['term'] == term).toList();
    final allActive =
        fees.isNotEmpty && fees.every((e) => e['status'] == 'active');

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: allActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            icon: Icon(
              allActive ? Icons.power_settings_new : Icons.check_circle,
            ),
            label: Text(allActive ? "Deactivate All" : "Activate All"),
            onPressed: () => toggleAllForTerm(term, !allActive),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: buildFeeList(fees)),
      ],
    );
  }

  Widget buildFeeList(List<dynamic> fees) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        final isActive = fee['status'] == 'active';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isActive ? Colors.green : Colors.red,
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overflow: TextOverflow.ellipsis,
                      fee['route'].toString().length > 16
                          ? '${fee['route'].toString().substring(0, 16)}...'
                          : fee['route'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Total Amount: ₹${fee['total_amount']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Term: ${fee['term']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Switch(
                      value: isActive,
                      activeColor: Colors.green,
                      onChanged: (value) async {
                        setState(() {
                          fee['status'] = value ? 'active' : 'inactive';
                        });

                        // Call your API to update the status for this single fee
                        final success = await api.toggleStatusById(
                          int.parse(fee['id'].toString()),
                          value ? 'active' : 'inactive',
                          widget.username,
                        );

                        if (success != null && context.mounted) {
                          setState(() {
                            fee['status'] = value ? 'inactive' : 'active';
                          });
                          fetchPaidPending();
                        } else if (context.mounted) {
                          fetchPaidPending();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to update status"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
