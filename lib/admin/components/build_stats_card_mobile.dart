import 'package:flutter/material.dart';

class BuildStatsCardMobile {
  static Widget buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // A light, neutral color
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, size: 40, color: Colors.black.withOpacity(0.7)),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 20),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children:
                  value.split('P:').expand((part) {
                    if (part.startsWith(' ')) {
                      // This is the part after "P:"
                      return [
                        const TextSpan(
                          text: 'P:',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: part,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ];
                    }
                    return [
                      TextSpan(
                        text: part,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ];
                  }).toList(),
              style: const TextStyle(
                // Default style for parts not explicitly styled
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
