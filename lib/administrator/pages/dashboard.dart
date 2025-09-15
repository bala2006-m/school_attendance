import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_desktop.dart';
import 'package:school_attendance/administrator/appbar/administrator_appbar_mobile.dart';

import '../../services/api_service.dart';
import '../services/administrator_api_service.dart';
import '../widget/mobile_drawer.dart';
import '../widget/school_registration.dart';
import './first_page.dart';

class AdministratorDashboard extends StatefulWidget {
  final String userName;

  const AdministratorDashboard({super.key, required this.userName});

  @override
  AdministratorDashboardState createState() => AdministratorDashboardState();
}

class AdministratorDashboardState extends State<AdministratorDashboard> {
  List<Map<String, dynamic>> schools = [];
  int admins = 0;
  int administrators = 0;
  int staffs = 0;
  int students = 0;
  bool isLoading = true;
  bool showRegister = false;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final res = await AdministratorApiService.fetchAllSchools();
    final ad = await ApiService.getUsersByRoleAll(role: 'admin');
    final administrator = await ApiService.getUsersByRoleAll(
      role: 'administrator',
    );
    final sd = await ApiService.getUsersByRoleAll(role: 'student');
    final st = await ApiService.getUsersByRoleAll(role: 'staff');
    setState(() {
      schools = res;
      isLoading = false;
      staffs = st.length;
      admins = ad.length;
      administrators = administrator.length;
      students = sd.length;
    });
  }

  ImageProvider _getSchoolImage(dynamic photo) {
    if (photo == null) {
      return const NetworkImage(
        'https://i.pinimg.com/originals/71/ca/c8/71cac8ecb9cec3704f6dc163f3b5fc6f.png',
      );
    }
    try {
      return MemoryImage(base64Decode(photo));
    } catch (_) {
      return const NetworkImage(
        'https://i.pinimg.com/originals/71/ca/c8/71cac8ecb9cec3704f6dc163f3b5fc6f.png',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: RefreshIndicator(
        onRefresh: init,
        child: Scaffold(
          backgroundColor: Colors.blue.shade50,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 190 : 150),
            child:
                isMobile
                    ? AdministratorAppbarMobile(
                      title: 'Administrator Dashboard',
                      enableDrawer: true,
                      enableBack: false,
                      onBack: () {},
                    )
                    : const AdministratorAppbarDesktop(
                      title: 'Administrator Dashboard',
                    ),
          ),
          drawer: Drawer(
            child: MobileDrawer(username: widget.userName, schoolId: 1),
          ),
          body:
              isLoading
                  ? const Center(
                    child: SpinKitFadingCircle(
                      color: Colors.blueAccent,
                      size: 60.0,
                    ),
                  )
                  : schools.isNotEmpty
                  ? CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child:
                            showRegister
                                ? SizedBox(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.56,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors
                                                .white, // add background color for better contrast
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(2, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Close button on top right
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  showRegister = false;
                                                });
                                              },
                                            ),
                                          ),

                                          // Form inside with padding
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                // const Text(
                                                //   "Register a New School",
                                                //   style: TextStyle(
                                                //     fontSize: 18,
                                                //     fontWeight: FontWeight.bold,
                                                //     color: Colors.teal,
                                                //   ),
                                                // ),
                                                // const SizedBox(height: 12),
                                                Expanded(
                                                  child: SchoolRegistration(
                                                    onRegister: init,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                : Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        showRegister = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.school,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Register School',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatCard(
                                    title: "Schools",
                                    count: schools.length,
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    title: "Administrators",
                                    count: administrators, // Example value
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    title: "Admins",
                                    count: admins, // Example value
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  _StatCard(
                                    title: "Staffs",
                                    count: staffs, // Example value
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    title: "Students",
                                    count: students, // Example value
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Registered Schools',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: _getSchoolImage(
                                  schools[i]['photo'],
                                ),
                              ),
                              title: Text(
                                schools[i]['name'] ?? 'Unknown School',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                schools[i]['address'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FirstPage(
                                          username: widget.userName,
                                          schoolName: schools[i]['name'],
                                          schoolAddress: schools[i]['address'],
                                          schoolId: '${schools[i]['id']}',
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: schools.length),
                      ),
                    ],
                  )
                  : const Center(child: Text('No Schools Found')),
        ),
      ),
    );
  }
}

// Custom stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
