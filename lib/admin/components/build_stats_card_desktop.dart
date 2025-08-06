import 'package:flutter/material.dart';

class BuildStatsCardDesktop {
  static Widget buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmall = screenHeight < 600;

    return Container(
      width:
          isSmall
              ? MediaQuery.of(context).size.width / 2.5
              : MediaQuery.of(context).size.width * 0.9,
      height:
          isSmall
              ? MediaQuery.of(context).size.height / 2
              : MediaQuery.of(context).size.height * 0.24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // gradient: AppColors.buttonColor, // Using a solid color for better contrast or specific theme
        color: Colors.white, // A light, neutral color
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, size: 40, color: Colors.blue[900]),
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
                      // This is the part before "P:" or the whole string if "P:" is not present
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
      ),
    );
  }
}
