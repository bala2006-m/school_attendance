import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/administrator/services/administrator_api_service.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import 'admin_dashboard.dart';

class EditPassword extends StatefulWidget {
  const EditPassword({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final int schoolId;

  @override
  State<EditPassword> createState() => _EditPasswordState();
}

class _EditPasswordState extends State<EditPassword> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isChanged = false; // 🔹 Track changes
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    // 🔹 Add listeners to detect changes
    _oldPasswordController.addListener(_onChanged);
    _newPasswordController.addListener(_onChanged);
    _confirmPasswordController.addListener(_onChanged);
  }

  void _onChanged() {
    final hasChanges =
        _oldPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;

    if (hasChanges != isChanged) {
      setState(() => isChanged = hasChanges);
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await AdministratorApiService.editPassword(
        username: widget.username,
        role: "admin",
        schoolId: widget.schoolId,
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["message"] ?? "Password updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required Function() toggle,
    String? Function(String?)? validator,
    int limit = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => AdminDashboard(
                  username: widget.username,
                  schoolId: '${widget.schoolId}',
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
                  ? AdminAppbarMobile(
                    username: widget.username,
                    schoolId: '${widget.schoolId}',
                    title: 'Change Password',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminDashboard(
                                username: widget.username,
                                schoolId: '${widget.schoolId}',
                              ),
                        ),
                      );
                    },
                  )
                  : AdminAppbarDesktop(title: 'Change Password'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Secure your account by updating your password.",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildPasswordField(
                  controller: _oldPasswordController,
                  label: "Old Password",
                  obscure: _obscureOld,
                  toggle: () => setState(() => _obscureOld = !_obscureOld),
                  validator:
                      (v) =>
                          v == null || v.isEmpty ? "Enter old password" : null,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: "New Password",
                  obscure: _obscureNew,
                  toggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? "Enter new password"
                              : v.length < 6
                              ? "Password must be at least 6 characters long"
                              : null,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: "Confirm New Password",
                  obscure: _obscureConfirm,
                  toggle:
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? "Confirm new password"
                              : v.length < 6
                              ? "Password must be at least 6 characters long"
                              : null,
                ),
                const SizedBox(height: 40),
                isLoading
                    ? Center(
                      child: SpinKitFadingCircle(
                        color: Colors.blueAccent,
                        size: 80.0,
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed:
                          isChanged ? _submit : null, // ✅ Enabled only if valid
                      icon: const Icon(Icons.save_alt_outlined, size: 20),
                      label: const Text("Update Password"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey, // 🔹 Grey when disabled
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
