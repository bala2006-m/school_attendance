import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../widget/admin_registration_deskop.dart';
import '../widget/admin_registration_mobile.dart';
import 'admin_dashboard.dart';

class AddOrRemoveAdmin extends StatefulWidget {
  final String schoolId;
  final String username;

  const AddOrRemoveAdmin({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AddOrRemoveAdmin> createState() => _AddOrRemoveAdminState();
}

class _AddOrRemoveAdminState extends State<AddOrRemoveAdmin> {
  final GlobalKey _formKey = GlobalKey();
  final GlobalKey _formKey1 = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController(
    text: 'admin',
  );
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController(
    text: '+91',
  );
  final TextEditingController _searchController = TextEditingController();

  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  late FocusNode _mobileFocus;
  late FocusNode _countryCodeFocus;

  List<dynamic> admin = [];
  Map<String, dynamic> adminData = {};
  List<dynamic> filteredAdmins = []; // 🔹 For search results

  bool showForm = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
    _usernameFocus = FocusNode();
    _passwordFocus = FocusNode();
    _mobileFocus = FocusNode();
    _countryCodeFocus = FocusNode();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    _countryCodeController.dispose();
    _searchController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _mobileFocus.dispose();
    _countryCodeFocus.dispose();
    super.dispose();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    final admin1 = await ApiService.getUsersByRole(
      schoolId: int.parse(widget.schoolId),
      role: 'admin',
    );

    admin =
        admin1
            .where((e) => e["school_id"] == int.parse(widget.schoolId))
            .toList();

    List<Future<void>> futures = [];
    adminData.clear();

    for (var user in admin) {
      final username = user['username'];
      futures.add(
        AdminApiService.fetchAdminData(
          username: username,
          schoolId: widget.schoolId,
        ).then((data) {
          adminData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;

    filteredAdmins = List.from(admin); // Initially all
    setState(() => isLoading = false);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredAdmins =
          admin.where((adminUser) {
            final username = adminUser['username'].toString().toLowerCase();
            final name =
                (adminData[adminUser['username']]?['name'] ?? '')
                    .toString()
                    .toLowerCase();
            final mobile =
                (adminData[adminUser['username']]?['mobile'] ?? '')
                    .toString()
                    .toLowerCase();

            return username.contains(query) ||
                name.contains(query) ||
                mobile.contains(query);
          }).toList();
    });
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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Admin',
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
                  : const AdminAppbarDesktop(title: 'Add Or Remove Admin'),
        ),
        body:
            isLoading
                ? const Center(
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
                              ? AdminRegistrationMobile(
                                passwordController: _passwordController,
                                designationController: _designationController,
                                mobileController: _mobileController,
                                countryCodeController: _countryCodeController,
                                passwordFocus: _passwordFocus,
                                mobileFocus: _mobileFocus,
                                countryCodeFocus: _countryCodeFocus,
                                isMobile: isMobile,
                                schoolId: widget.schoolId,
                                onRegistered: init,
                              )
                              : AdminRegistrationDesktop(
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

                    // 🔹 Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Search by name, username, or mobile",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: const Text(
                        'Registered Admins',
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
                          'Total : ${filteredAdmins.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Show "No results found" if search is empty
                    if (filteredAdmins.isEmpty)
                      const Center(
                        child: Text(
                          "No results found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),

                    ...filteredAdmins.map((adminUser) {
                      final username = adminUser['username'];
                      final data = adminData[username] ?? {};

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
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.blue,
                          ),
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
                                      title: const Text('Delete Admin'),
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
                                  role: 'admin',
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
}
