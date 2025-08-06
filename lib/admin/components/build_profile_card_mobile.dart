import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../color/admin_custom_color.dart';

class BuildProfileCard extends StatefulWidget {
  const BuildProfileCard({
    super.key,
    required this.schoolName,
    required this.schoolAddress,
    this.heroTag = '',
    this.useHero = false,
    required this.schoolPhoto,
  });

  final String schoolName;
  final String schoolAddress;
  final bool useHero;
  final String heroTag;
  final Image? schoolPhoto;
  @override
  State<BuildProfileCard> createState() => _BuildProfileCardState();
}

class _BuildProfileCardState extends State<BuildProfileCard> {
  ImageProvider? adminPhoto;

  @override
  void initState() {
    super.initState();
    fetchPhoto();
  }

  Future<void> fetchPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final base64 = prefs.getString('schoolPhoto');
    if (base64 != null && base64.isNotEmpty) {
      try {
        final clean = base64.contains(',') ? base64.split(',').last : base64;

        Uint8List bytes = base64Decode(clean);
        setState(() {
          adminPhoto = MemoryImage(bytes);
        });
      } catch (e) {
        print('Failed to decode base64 image: $e');
        setState(() {
          adminPhoto = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      backgroundImage: adminPhoto,
      child:
          adminPhoto == null
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminCustomColor.profileCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.useHero ? Hero(tag: widget.heroTag, child: avatar) : avatar,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  '${widget.schoolName}\n${widget.schoolAddress}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
