import 'package:flutter/material.dart';

import '../../admin/components/build_profile_card_mobile.dart';
import '../../admin/components/message_box.dart';
import '../pages/attendance_page.dart';
class StudentAttendancePage extends StatelessWidget {

  final String username;
  final String name;
  final String email;
  final String schoolId;
  final String classId;
  final String gender;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final String message;

  const StudentAttendancePage({super.key, required this.username, required this.name, required this.email, required this.schoolId, required this.classId, required this.gender, this.schoolPhoto, required this.schoolName, required this.schoolAddress, required this.message,});
  @override
  Widget build(BuildContext context) {
    return Container(
        child:Column(children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: BuildProfileCard(
              schoolPhoto: schoolPhoto,
              schoolAddress: schoolAddress,
              schoolName: schoolName,
            ),
          ),
          ElevatedButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AttendancePage(
            username: username,
            name: name,
            schoolId: schoolId,
            classId: classId,
            email: email,
            gender: gender,
            schoolPhoto: schoolPhoto,
            schoolName: schoolName,
            schoolAddress: schoolAddress,
            message: message,
          ),));
        }, child: Text("Attendance"))],)
    );
  }
}
