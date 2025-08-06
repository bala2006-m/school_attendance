import 'dart:io';

import 'package:flutter/material.dart';

class Uploads {
  static Widget buildStudentUpload({
    required File? selectedExcelFile,
    context,
    required Future<void> Function() downloadTemplateStudent,
    required Future<void> Function() pickExcelFileStudent,
    required Future<void> Function() uploadFileStudent,
    required List<dynamic> student,
    required Map<String, dynamic> studentData,
  }) {
    final fileName = selectedExcelFile?.path.split('/').last ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: downloadTemplateStudent,
          icon: const Icon(Icons.download, color: Colors.green, size: 30),
          label: const Text(
            'Download Template',
            style: TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: pickExcelFileStudent,
          icon: const Icon(Icons.upload_file, color: Colors.blue, size: 30),
          label: const Text(
            'Select Excel File',
            style: TextStyle(color: Colors.black),
          ),
        ),
        if (selectedExcelFile != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Selected: ${fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.blue,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
              side: const BorderSide(width: 1, color: Colors.grey),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
            ),
            onPressed: uploadFileStudent,
            label: const Text(
              'Upload to Server',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Registered Students',
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
              'Total : ${student.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...student.map((adminUser) {
          final username = adminUser['username'];
          final data = studentData[username] ?? {};
          final name = data['name'] ?? 'Name not available';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(child: Text(name[0])),
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
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildStaffUpload({
    required File? selectedExcelFile,
    context,
    required Future<void> Function() downloadTemplateStaff,
    required Future<void> Function() pickExcelFileStaff,
    required Future<void> Function() uploadFileStaff,
    required List<dynamic> staff,
    required Map<String, dynamic> staffData,
  }) {
    final fileName = selectedExcelFile?.path.split('/').last ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: downloadTemplateStaff,
          icon: const Icon(Icons.download, color: Colors.green, size: 30),
          label: const Text(
            'Download Template',
            style: TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: pickExcelFileStaff,
          icon: const Icon(Icons.upload_file, color: Colors.blue, size: 30),
          label: const Text(
            'Select Excel File',
            style: TextStyle(color: Colors.black),
          ),
        ),
        if (selectedExcelFile != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Selected: ${fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.blue,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
              side: const BorderSide(width: 1, color: Colors.grey),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
            ),
            onPressed: uploadFileStaff,
            label: const Text(
              'Upload to Server',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...staff.map((staffUser) {
          final username = staffUser['username'];
          final data = staffData[username] ?? {};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              subtitle: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: $username'),
                      Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
                    ],
                  ),
                  Spacer(),
                  Column(
                    children: [
                      Text('Designation:'),
                      Text(data['designation'] ?? 'N/A'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }

  static Widget buildAdminUpload({
    context,
    required File? selectedExcelFile,
    required Future<void> Function() downloadTemplateAdmin,
    required Future<void> Function() pickExcelFileAdmin,
    required Future<void> Function() uploadFileAdmin,
    required List<dynamic> admin,
    required Map<String, dynamic> adminData,
  }) {
    final fileName = selectedExcelFile?.path.split('/').last ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: downloadTemplateAdmin,
          icon: const Icon(Icons.download, color: Colors.green, size: 30),
          label: const Text(
            'Download Template',
            style: TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.grey),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
          ),
          onPressed: pickExcelFileAdmin,
          icon: const Icon(Icons.upload_file, color: Colors.blue, size: 30),
          label: const Text(
            'Select Excel File',
            style: TextStyle(color: Colors.black),
          ),
        ),
        if (selectedExcelFile != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Selected: ${fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.blue,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
              side: const BorderSide(width: 1, color: Colors.grey),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(MediaQuery.sizeOf(context).width * 0.9, 50),
            ),
            onPressed: uploadFileAdmin,
            label: const Text(
              'Upload to Server',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
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
              'Total : ${admin.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...admin.map((adminUser) {
          final username = adminUser['username'];
          final data = adminData[username] ?? {};
          final designation = data['designation'];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              subtitle: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username: $username'),
                      Text('Mobile: ${data['mobile'] ?? 'N/A'}'),
                    ],
                  ),
                  Spacer(),
                  Column(
                    children: [
                      Text('Designation:'),
                      Text(designation ?? 'N/A'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }
}
