import 'package:flutter/material.dart';

import '../services/administrator_api_service.dart';

class BlockSchool extends StatefulWidget {
  const BlockSchool({super.key});

  @override
  State<BlockSchool> createState() => _BlockSchoolState();
}

class _BlockSchoolState extends State<BlockSchool> {
  List<Map<String, dynamic>> schools = [];
  bool isLoading = true;
  List<dynamic> blockedSchools = [];
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final res = await AdministratorApiService.fetchAllSchools();
      final blocked = await AdministratorApiService.getBlockedSchools();
      setState(() {
        schools = res;
        isLoading = false;
        blockedSchools = blocked;
      });
      print(blockedSchools[0]['school_id']);
    } catch (e) {
      debugPrint("Error fetching schools: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _blockSchool(int schoolId) async {
    final TextEditingController reasonController = TextEditingController();

    // Show reason dialog
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
              child: const Text("Block"),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await AdministratorApiService.createBlockedSchool(schoolId, reason);

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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Block Schools")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : schools.isEmpty
              ? const Center(child: Text("No schools found"))
              : ListView.builder(
                itemCount: schools.length,
                itemBuilder: (context, i) {
                  final school = schools[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.school, color: Colors.blue),
                      title: Text(
                        school["name"] ?? "Unknown School",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(school["address"] ?? ""),
                      trailing: ElevatedButton(
                        onPressed:
                            () => _blockSchool(int.parse("${school['id']}")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Block"),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
