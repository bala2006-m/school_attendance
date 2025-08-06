import 'package:flutter/material.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class CreateTodayMessage extends StatefulWidget {
  final String schoolId;
  final String username;

  const CreateTodayMessage({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<CreateTodayMessage> createState() => _CreateTodayMessageState();
}

class _CreateTodayMessageState extends State<CreateTodayMessage> {
  final TextEditingController message = TextEditingController();
  bool isMessageNotEmpty = false;

  @override
  void initState() {
    super.initState();
    message.addListener(() {
      final isNotEmpty = message.text.trim().isNotEmpty;
      if (isNotEmpty != isMessageNotEmpty) {
        setState(() {
          isMessageNotEmpty = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
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

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'Create Today Message',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Create Today Message'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildAnimatedField(label: 'Message', controller: message),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed:
                        isMessageNotEmpty
                            ? () async {
                              isMessageNotEmpty = false;
                              final result = await AdminApiService.postMessage(
                                message.text.trim(),
                                int.parse(widget.schoolId),
                              );

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(result)));
                              message.text = '';
                              setState(() {
                                isMessageNotEmpty = false;
                              });
                            }
                            : null, // disables button when false
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isMessageNotEmpty ? Colors.blueAccent : Colors.grey,
                      foregroundColor:
                          isMessageNotEmpty ? Colors.white : Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAnimatedField({
    required String label,
    required TextEditingController controller,
    String hintText = '',
  }) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: InputBorder.none,
            labelStyle: const TextStyle(fontSize: 20, color: Colors.black),
          ),
          style: const TextStyle(fontSize: 18),
          maxLines: null,
        ),
      ),
    );
  }
}
