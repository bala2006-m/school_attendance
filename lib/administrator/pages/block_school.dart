import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../appbar/administrator_appbar_desktop.dart';
import '../appbar/administrator_appbar_mobile.dart';
import '../services/administrator_api_service.dart';
import 'first_page.dart';

class BlockSchool extends StatefulWidget {
  const BlockSchool({
    super.key,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
  });

  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;

  @override
  State<BlockSchool> createState() => _BlockSchoolState();
}

class _BlockSchoolState extends State<BlockSchool> {
  bool isLoading = true;
  bool actionLoading = false;
  List<dynamic> blockedSchools = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final blocked = await AdministratorApiService.getBlockedSchools();
      setState(() {
        blockedSchools = blocked;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching blocked schools: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _blockSchool(int schoolId) async {
    final TextEditingController reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Block School"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: "Enter reason",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final reasonText = reasonController.text.trim();
                if (reasonText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reason cannot be empty")),
                  );
                  return;
                }
                Navigator.pop(ctx, reasonText);
              },
              child: const Text("Block"),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        setState(() => actionLoading = true);

        await AdministratorApiService.createBlockedSchool(schoolId, reason);

        await _init();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("School blocked successfully")),
          );
        }
      } catch (e) {
        debugPrint("Error blocking school: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to block school: $e")));
        }
      } finally {
        if (mounted) {
          setState(() => actionLoading = false);
        }
      }
    }
  }

  Future<void> _unblockSchool(int schoolId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Unblock School"),
          content: const Text("Are you sure you want to unblock this school?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Unblock"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() => actionLoading = true);

      await AdministratorApiService.deleteBlockedSchool(schoolId);

      await _init();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("School unblocked successfully")),
        );
      }
    } catch (e) {
      debugPrint("Error unblocking school: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to unblock school: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    final isBlocked = blockedSchools.any(
      (school) => school['school_id'] == int.parse(widget.schoolId),
    );

    final int? blockId =
        isBlocked
            ? blockedSchools.firstWhere(
                  (s) => s['school_id'] == int.parse(widget.schoolId),
                )['id']
                as int?
            : null;

    final blockReason =
        isBlocked
            ? blockedSchools.firstWhere(
              (s) => s['school_id'] == int.parse(widget.schoolId),
              orElse: () => {'reason': 'No reason provided'},
            )['reason']
            : null;

    return WillPopScope(
      onWillPop: () async {
        FirstPageState.selectedIndex = 1;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FirstPage(
                  username: widget.username,
                  schoolName: widget.schoolName,
                  schoolAddress: widget.schoolAddress,
                  schoolId: widget.schoolId,
                ),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdministratorAppbarMobile(
                    title: 'Block School',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      FirstPageState.selectedIndex = 1;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FirstPage(
                                username: widget.username,
                                schoolName: widget.schoolName,
                                schoolAddress: widget.schoolAddress,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdministratorAppbarDesktop(title: 'Block School'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("School ID :", widget.schoolId),
                            const SizedBox(height: 10),
                            _infoRow("School Name :", widget.schoolName),
                            const SizedBox(height: 10),
                            _infoRow("School Address :", widget.schoolAddress),
                            const SizedBox(height: 20),
                            Center(
                              child:
                                  actionLoading
                                      ? SpinKitFadingCircle(
                                        color: Colors.blueAccent,
                                        size: 60.0,
                                      )
                                      : isBlocked
                                      ? _blockedInfo(blockReason, blockId)
                                      : _blockButton(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _blockedInfo(String? blockReason, int? blockId) {
    return Column(
      children: [
        const Text(
          '🚫 This school is blocked',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (blockReason != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Reason: $blockReason",
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () async {
            if (blockId != null) await _unblockSchool(blockId);
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text("Unblock School"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blockButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        await _blockSchool(int.parse(widget.schoolId));
      },
      icon: const Icon(Icons.block),
      label: const Text("Block School"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
