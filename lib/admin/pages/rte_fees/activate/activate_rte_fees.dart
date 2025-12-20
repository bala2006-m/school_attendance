import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../services/rte_fees_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../dashboard/admin_dashboard.dart';

class ActivateRteFees extends StatefulWidget {
  const ActivateRteFees({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<ActivateRteFees> createState() => _ActivateRteFeesState();
}

class _ActivateRteFeesState extends State<ActivateRteFees> {
  bool isLoading = true;
  List<dynamic> allTermFees = [];
  final RteFeesService api = RteFeesService();

  @override
  void initState() {
    super.initState();
    fetchPaidPending();
  }

  Future<void> fetchPaidPending() async {
    final data = await api.getAllStructuresBySchool(int.parse(widget.schoolId));
    setState(() {
      allTermFees = data!;
      isLoading = false;
    });
  }

  Future<void> toggleStatusForFee(int feeId, bool newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: SpinKitFadingCircle(color: Colors.blue, size: 55),
          ),
    );

    final success = await api.toggleStatusById(
      feeId,
      newStatus ? 'active' : 'inactive',
      widget.username,
    );

    if (mounted) {
      Navigator.pop(context);
      if (success != null) {
        fetchPaidPending();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Fee status set to ${newStatus ? 'ACTIVE' : 'INACTIVE'}",
            ),
            backgroundColor: newStatus ? Colors.green : Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update status"),
            backgroundColor: Colors.red,
          ),
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
        backgroundColor: const Color(0xfff5f7fa),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Activate RTE Fees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Activate RTE Fees',
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
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allTermFees.length,
                  itemBuilder: (context, index) {
                    final fee = allTermFees[index];
                    final isActive = fee['status'] == 'active';
                    final descriptions = fee['descriptions'] as List;
                    final amounts = fee['amounts'] as List;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class: ${fee['class']['class']}-${fee['class']['section']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Total Amount: ₹${fee['total_amount']}'),
                            const SizedBox(height: 8),
                            Text('Status: ${fee['status'].toUpperCase()}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: List.generate(descriptions.length, (i) {
                                return Chip(
                                  label: Text(
                                    '${descriptions[i]}: ₹${amounts[i]}',
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeColor: Colors.green,
                                  onChanged:
                                      (value) =>
                                          toggleStatusForFee(fee['id'], value),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
