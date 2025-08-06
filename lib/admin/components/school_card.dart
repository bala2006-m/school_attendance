import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class SchoolCard extends StatefulWidget {
  final String schoolId;
  const SchoolCard({super.key, required this.schoolId});

  @override
  State<SchoolCard> createState() => _SchoolCardState();
}

class _SchoolCardState extends State<SchoolCard> {
  String? schoolName;
  String? schoolAddress;
  Image? schoolPhoto;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.wait([fetchSchoolInfo()]);
  }

  Future<void> fetchSchoolInfo() async {
    final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
    schoolName = schoolData[0]['name'];
    schoolAddress = schoolData[0]['address'];

    try {
      if (schoolData[0]['photo'] != null) {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        schoolPhoto = Image.memory(
          imageBytes,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Image decode error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            schoolName ?? 'bala',
            style: const TextStyle(
              color: Colors.teal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
