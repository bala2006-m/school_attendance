import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';

import '../../../services/api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../widget/staff_registration_desktop.dart';
import '../../widget/staff_registration_mobile.dart';
import '../dashboard/admin_dashboard.dart';

class AddOrRemoveStaff extends StatefulWidget {
  final String schoolId;
  final String username;

  const AddOrRemoveStaff({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<AddOrRemoveStaff> createState() => AddOrRemoveStaffState();
}

class AddOrRemoveStaffState extends State<AddOrRemoveStaff> {
  final GlobalKey _formKey = GlobalKey();
  final GlobalKey _formKey1 = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController(
    text: '+91',
  );
  final TextEditingController _searchController = TextEditingController();

  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  late FocusNode _mobileFocus;
  late FocusNode _countryCodeFocus;
  static int selectedIndex = 0;
  List<dynamic> filteredStaff = [];
  List<Map<String, dynamic>> staffData = [];
  bool showForm = false;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    init();
    _searchController.addListener(_filterStaff);
    _usernameFocus = FocusNode();
    _passwordFocus = FocusNode();
    _mobileFocus = FocusNode();
    _countryCodeFocus = FocusNode();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    staffData = await AdminApiService.fetchStaffData(widget.schoolId);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      filteredStaff = List.from(staffData);
    });
  }

  void _filterStaff() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredStaff =
          staffData.where((staffUser) {
            final username =
                staffUser['username']?.toString().toLowerCase() ?? '';
            final name = staffUser['name']?.toString().toLowerCase() ?? '';
            final mobile = staffUser['mobile']?.toString().toLowerCase() ?? '';
            return username.contains(query) ||
                name.contains(query) ||
                mobile.contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    _countryCodeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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

  // --- Improved function: group and sort by gender and name ---
  List<Map<String, dynamic>> groupAndSortStaffByGender(
    List<Map<String, dynamic>> staff,
  ) {
    List<Map<String, dynamic>> males =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'M')
            .toList();
    List<Map<String, dynamic>> females =
        staff
            .where((data) => (data['gender'] ?? '').toUpperCase() == 'F')
            .toList();

    int nameComparator(a, b) => (a['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['name'] ?? '').toString().toLowerCase());

    males.sort(nameComparator);
    females.sort(nameComparator);

    return [...males, ...females];
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Staff',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Add/Remove Staff',
                    onBack: () {
                      onWillPop();
                    },
                  ),
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(key: _formKey1, height: 10),
                    if (showForm)
                      Column(
                        children: [
                          SizedBox(key: _formKey, height: 10),
                          isMobile
                              ? StaffRegistrationMobile(
                                passwordController: _passwordController,
                                mobileController: _mobileController,
                                countryCodeController: _countryCodeController,
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
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, user Id, or mobile',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    IndexedStack(
                      index: selectedIndex,
                      children: [teachingStaffStack(), nonTeachingStaffStack()],
                    ),
                    const SizedBox(height: 90),
                    const Divider(),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
              Future.delayed(Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              label: 'Teaching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 30),
              label: 'Non Teaching',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade50,
          onPressed: () {
            setState(() {
              showForm = !showForm;
            });
            if (showForm) {
              Future.delayed(Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
          child:
              showForm
                  ? Icon(Icons.close, size: 30, color: Colors.blue.shade900)
                  : Icon(Icons.add, size: 30, color: Colors.blue.shade900),
        ),
      ),
    );
  }

  // --- Improved grouping for each stack ---

  Widget teachingStaffStack() {
    final teachingStaff =
        filteredStaff
            .where((staffUser) => staffUser['faculty'] == 'teaching')
            .cast<Map<String, dynamic>>()
            .toList();
    final teachingToShow = groupAndSortStaffByGender(teachingStaff);

    return Column(
      children: [
        Center(
          child: const Text(
            'Teaching Staffs',
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
              'Total : ${teachingStaff.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...teachingToShow.map((staffUser) {
          final username = staffUser['username'];
          return staffCard(username, staffUser);
        }),
      ],
    );
  }

  Widget nonTeachingStaffStack() {
    final nonTeachingStaff =
        filteredStaff
            .where((staffUser) => staffUser['faculty'] == 'nonteaching')
            .cast<Map<String, dynamic>>()
            .toList();
    final nonTeachingToShow = groupAndSortStaffByGender(nonTeachingStaff);

    return Column(
      children: [
        Center(
          child: const Text(
            'Non Teaching Staffs',
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
              'Total : ${nonTeachingStaff.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...nonTeachingToShow.map((staffUser) {
          final username = staffUser['username'];
          return staffCard(username, staffUser);
        }),
      ],
    );
  }

  Widget staffCard(String username, Map<String, dynamic> data) {
    final gender = (data['gender'] ?? '').toUpperCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          gender == 'M'
              ? Icons.male
              : gender == 'F'
              ? Icons.female
              : Icons.person,
          color:
              gender == 'M'
                  ? Colors.blue
                  : gender == 'F'
                  ? Colors.red
                  : Colors.blue,
        ),
        title: Text(
          data['name'] ?? 'Name not available',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                gender == 'M'
                    ? Colors.blue
                    : gender == 'F'
                    ? Colors.red
                    : Colors.blue,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $username'),
            Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
            Text('Designation: ${data['designation'] ?? 'N/A'}'),
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
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
            );

            if (confirm == true) {
              final success = await ApiService.deleteUser(
                username: username,
                role: 'staff',
                schoolId: int.parse(widget.schoolId),
              );

              if (!mounted) return;

              if (success) {
                await init();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Deleted $username')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete $username\n$username is used in other services',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
