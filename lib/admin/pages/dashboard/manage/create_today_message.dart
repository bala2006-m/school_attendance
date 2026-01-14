import 'package:flutter/material.dart';

import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../admin_dashboard.dart';

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
  bool isLoading = true;

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    init();

    message.addListener(() {
      final notEmpty = message.text.trim().isNotEmpty;
      if (notEmpty != isMessageNotEmpty) {
        setState(() => isMessageNotEmpty = notEmpty);
      }
    });
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    messages = await AdminApiService.fetchAllMessage(widget.schoolId);
    print(messages);
    setState(() => isLoading = false);
  }

  Future<void> deleteMessage(String id) async {
    await AdminApiService.deleteMessage(id);
    await init();
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
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
                    title: 'Create Today Message',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Create Today Message',
                    onBack: onWillPop,
                  ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                buildAnimatedField(label: 'Message', controller: message),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed:
                        isMessageNotEmpty
                            ? () async {
                              final result = await AdminApiService.postMessage(
                                message.text.trim(),
                                int.parse(widget.schoolId),
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(result)));
                              }

                              message.clear();
                              setState(() => isMessageNotEmpty = false);
                              await init();
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isMessageNotEmpty ? Colors.blueAccent : Colors.grey,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 30),

                /// MESSAGE LIST
                if (isLoading)
                  const CircularProgressIndicator()
                else if (messages.isEmpty)
                  const Text(
                    'No messages found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            msg['messages'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            msg['date'],
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await deleteMessage(msg['id'].toString());
                            },
                          ),
                        ),
                      );
                    },
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
      padding: const EdgeInsets.all(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
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
            labelStyle: const TextStyle(fontSize: 20),
          ),
          style: const TextStyle(fontSize: 18),
          maxLines: null,
        ),
      ),
    );
  }
}
