import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ramchin Smart School',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: April 2026',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              '1. Information We Collect',
              'Personal Information: student name, date of birth, gender, and profile photo; parent or guardian contact information; teacher and staff contact details.\n\n'
                  'Attendance Data: presence/absence records, timestamps, and notes.\n\n'
                  'Device & Technical Information: device type, operating system, app version, and IP address for security purposes.',
            ),
            _buildSection(
              context,
              '2. How We Use Information',
              'We use collected data to:\n'
                  '• Manage student attendance\n'
                  '• Generate reports for schools\n'
                  '• Improve app functionality and performance',
            ),
            _buildSection(
              context,
              '3. Data Sharing',
              'We do NOT sell personal data. Data may be shared with:\n'
                  '• Schools and authorized staff\n'
                  '• Trusted service providers (hosting, analytics)\n'
                  '• Legal authorities if required by law',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'We implement appropriate security measures including encryption and access control to protect user data.',
            ),
            _buildSection(
              context,
              '5. Data Retention',
              'We retain data only as long as necessary for operational and legal purposes. Schools may configure retention policies.',
            ),
            _buildSection(
              context,
              '6. User Rights',
              'Users may request access, correction, or deletion of their data by contacting support.',
            ),
            _buildSection(
              context,
              '7. Children\'s Privacy',
              'We prioritize children\'s data protection and only collect necessary information with proper authorization from schools and guardians.',
            ),
            _buildSection(
              context,
              '8. Photo and Video Permissions',
              'Our app may request access to the device camera and media storage strictly for core functionality such as:\n\n'
                  '• Capturing student profile photos\n'
                  '• Uploading images for identification and attendance verification\n\n'
                  'We ensure:\n'
                  '• Permissions are requested only when the user performs an action (e.g., taking or uploading a photo)\n'
                  '• No background access to photos or videos\n'
                  '• No use of media for advertising or tracking\n\n'
                  'All images are securely stored and accessible only to authorized school personnel.\n\n'
                  'We do NOT:\n'
                  '• Access media without user interaction\n'
                  '• Collect unnecessary photos or videos\n'
                  '• Use media data for analytics or ads',
            ),
            _buildSection(
              context,
              '9. Contact Us',
              'For questions or concerns:\n'
                  'Email: ramchintech@gmail.com',
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We protect your privacy and comply with data protection regulations.',
                      style: TextStyle(color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
