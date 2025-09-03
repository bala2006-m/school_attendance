import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';

import '../../services/api_service.dart';
import '../services/teacher_api_service.dart';

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
  String staffName = '';
  String email = '';
  Map<String, dynamic> staff = {};
  Map<String, dynamic> schoolData = {};

  final _formKey = GlobalKey<FormState>();
  final _ticketsController = TextEditingController();

  bool _isLoading = false;
  bool _isFormValid = false;

  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _ticketsController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _ticketsController.removeListener(_validateForm);
    _ticketsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final text = _ticketsController.text.trim();
    final isValid = text.isNotEmpty && text.length >= 5;
    if (_isFormValid != isValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _loadStaffData() async {
    try {
      setState(() => _isLoading = true);

      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.username,
        schoolId: int.parse(widget.schoolId),
      );
      print(data);
      if (!mounted) return;

      setState(() {
        staff = data!;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading staff data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await _apiService.storeTickets(
          username: widget.username,
          name: staff['name'],
          email: staff['email'],
          tickets: _ticketsController.text,
          schoolId: int.parse(widget.schoolId),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ticket submitted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          _ticketsController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StaffDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
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
                  ? MobileAppbar(
                    title: 'Post Ticket',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      StaffDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StaffDashboard(
                                username: widget.username,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'Post Ticket'),
        ),
        body:
            _isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Submit a Support Ticket',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Describe the issue you are facing, and our support team will get back to you.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _ticketsController,
                              decoration: InputDecoration(
                                labelText: "Describe the issue",
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.edit_note),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please describe the issue";
                                }
                                if (value.trim().length < 5) {
                                  return "Please provide more details";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: SpinKitFadingCircle(
                                          color: Colors.blueAccent,
                                          size: 60.0,
                                        ),
                                      )
                                      : const Text("Submit Ticket"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                                backgroundColor:
                                    _isFormValid ? Colors.blue : Colors.grey,
                              ),
                              onPressed:
                                  (_isFormValid && !_isLoading)
                                      ? _submit
                                      : null,
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
}
