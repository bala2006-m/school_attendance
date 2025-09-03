import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/pages/real_time_mesage/message_class_list.dart';

import '../../appbar/desktop_appbar.dart';
import '../../appbar/mobile_appbar.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    required this.username,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
  });
  final String username;
  final String schoolId;
  final String classId;
  final String className;
  final String section;
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Post Message',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MessageClassList(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Post Message'),
      ),
    );
  }
}
