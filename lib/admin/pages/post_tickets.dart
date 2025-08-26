import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import 'admin_dashboard.dart';

class PostTickets extends StatefulWidget {
  const PostTickets({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;
  @override
  State<PostTickets> createState() => _PostTicketsState();
}

class _PostTicketsState extends State<PostTickets> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ticketsController = TextEditingController();
  final _schoolIdController = TextEditingController();

  bool _isLoading = false;
  final _apiService = ApiService();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await _apiService.storeTickets(
          username: _usernameController.text,
          name: _nameController.text,
          email: _emailController.text,
          tickets: int.parse(_ticketsController.text),
          schoolId: _schoolIdController.text,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Success: ${result['status']}")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
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
                    title: 'View Feedback',
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
                  : const AdminAppbarDesktop(title: 'View Feedback'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  validator: (v) => v!.isEmpty ? "Enter username" : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (v) =>
                          v!.isEmpty || !v.contains('@')
                              ? "Enter valid email"
                              : null,
                ),
                TextFormField(
                  controller: _ticketsController,
                  decoration: const InputDecoration(labelText: "Tickets"),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Enter ticket count" : null,
                ),
                TextFormField(
                  controller: _schoolIdController,
                  decoration: const InputDecoration(labelText: "School ID"),
                  validator: (v) => v!.isEmpty ? "Enter school ID" : null,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Submit"),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
