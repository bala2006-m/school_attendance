import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../widget/staff_registration_desktop.dart';
import '../widget/staff_registration_mobile.dart';
import 'admin_dashboard.dart';

class AddOrRemoveStaff extends StatefulWidget {
  final String schoolId;
  final String username;
  const AddOrRemoveStaff({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AddOrRemoveStaff> createState() => _AddOrRemoveStaffState();
}

class _AddOrRemoveStaffState extends State<AddOrRemoveStaff> {
  final GlobalKey _formKey = GlobalKey();
  final GlobalKey _formKey1 = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController(
    text: 'staff',
  );
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController(
    text: '+91',
  ); // Default to +91
  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  late FocusNode _mobileFocus;
  late FocusNode _countryCodeFocus;
  List<dynamic> staff = [];
  Map<String, dynamic> staffData = {};
  bool showForm = false;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
    _usernameFocus = FocusNode();
    _passwordFocus = FocusNode();
    _mobileFocus = FocusNode();
    _countryCodeFocus = FocusNode();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    staff = await ApiService.getUsersByRole('staff');
    List<Future<void>> futures = [];
    staffData.clear();

    for (var user in staff) {
      final username = user['username'];
      futures.add(
        TeacherApiServices.fetchStaffDataUsername(username).then((data) {
          staffData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    _countryCodeController.dispose();
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
                    title: 'Add Or Remove Staff',
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
                  : const AdminAppbarDesktop(title: 'Add Or Remove Staff'),
        ),
        body:
            isLoading
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(key: _formKey1, height: 10),
                    if (showForm)
                      Column(
                        children: [
                          SizedBox(key: _formKey, height: 10),
                          isMobile
                              ? StaffRegistrationMobile(
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                designationController: _designationController,
                                mobileController: _mobileController,
                                countryCodeController: _countryCodeController,
                                usernameFocus: _usernameFocus,
                                passwordFocus: _passwordFocus,
                                mobileFocus: _mobileFocus,
                                countryCodeFocus: _countryCodeFocus,
                                schoolId: widget.schoolId,
                                onRegistered: init,
                              )
                              : StaffRegistrationDesktop(
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                designationController: _designationController,
                                mobileController: _mobileController,
                                countryCodeController: _countryCodeController,
                                usernameFocus: _usernameFocus,
                                passwordFocus: _passwordFocus,
                                mobileFocus: _mobileFocus,
                                countryCodeFocus: _countryCodeFocus,
                                schoolId: widget.schoolId,
                                onRegistered: init,
                              ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Center(
                      child: const Text(
                        'Registered Staffs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Total : ${staff.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...staff.map((staffUser) {
                      final username = staffUser['username'];
                      final data = staffData[username] ?? {};

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.people, color: Colors.blue),
                          title: Text(
                            data['name'] ?? 'Name not available',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username: $username'),
                              Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Staff'),
                                      content: Text(
                                        'Are you sure you want to delete "$username"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                int id = int.parse(widget.schoolId);
                                final success = await ApiService.deleteUser(
                                  username: username,
                                  role: 'staff',
                                  schoolId: id,
                                );

                                if (!mounted) return;

                                if (success) {
                                  await init();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted $username'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete $username',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    const Divider(),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed: () {
            setState(() {
              showForm = !showForm;
            });
          },
          child:
              showForm
                  ? Icon(Icons.close, size: 30, color: Colors.blue.shade900)
                  : Icon(Icons.add, size: 30, color: Colors.blue.shade900),
        ),
      ),
    );
  }

  Widget buildAnimatedField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? toggleObscure,
    TextInputType? keyboardType, // Add keyboardType
  }) {
    bool isFocused = focusNode.hasFocus || controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? Colors.blue : Colors.grey.shade400,
          width: isFocused ? 2 : 1,
        ),
        boxShadow:
            isFocused
                ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: isPassword && obscureText,
              keyboardType: keyboardType, // Apply keyboardType
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                labelStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: toggleObscure,
            ),
        ],
      ),
    );
  }
}
