import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'firstPage.dart';

class AdministratorDashboard extends StatefulWidget {
  final String name;
  final String address;
  final Uint8List photo;
  final String schoolId;

  const AdministratorDashboard({
    super.key,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.photo,
  });

  @override
  _AdministratorDashboardState createState() => _AdministratorDashboardState();
}

class _AdministratorDashboardState extends State<AdministratorDashboard> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Firstpage()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          backgroundColor: Colors.deepPurple,
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: MemoryImage(widget.photo),
                  radius: 35,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.address,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              Container(
                height: 300, // Adjust height as needed
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(100),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: MemoryImage(widget.photo),
                      radius: 45, // Adjust radius as needed
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.dashboard, 'Dashboard'),
              _buildDrawerItem(Icons.people, 'Students'),
              _buildDrawerItem(Icons.person, 'Teachers'),
              _buildDrawerItem(Icons.assessment, 'Reports'),
              _buildDrawerItem(Icons.admin_panel_settings, 'Register Admin'),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    title: 'Total Students',
                    count: 350,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Present Today',
                    count: 310,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Absent Today',
                    count: 40,
                    color: Colors.red,
                  ),
                  _StatCard(title: 'Teachers', count: 22, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Attendance records will appear here.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        // Add navigation logic here, like:
        // Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsPage()));
      },
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
