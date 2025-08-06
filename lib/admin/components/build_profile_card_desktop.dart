import 'package:flutter/material.dart';

import '../color/admin_custom_color.dart';

class BuildProfileCardDesktop {
  static Widget buildProfileCardDesktop({
    required String adminName,
    required String adminDesignation,
    required Image? adminPhoto,
    required String schoolName,
    required String schoolAddress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminCustomColor.profileCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Add navigation or action for profile card tap
          },
          child: Padding(
            padding: const EdgeInsets.all(
              8.0,
            ), // Add padding for better touch area
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                adminPhoto != null
                    ? CircleAvatar(
                      radius: 35,
                      backgroundImage: adminPhoto.image,
                    )
                    : CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person_outline,
                        size: 45,
                        color: Colors.grey[600],
                      ),
                    ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Increased font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      adminDesignation,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 18,
                      ), // Slightly more opaque
                    ),
                    Text(
                      '$schoolName\n$schoolAddress',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
