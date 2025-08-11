import 'package:flutter/material.dart';

import '../../admin/components/build_profile_card_mobile.dart';
import '../../admin/components/message_box.dart';
import '../pages/holiday_page.dart';
class StudentManagePage extends StatelessWidget {
  const StudentManagePage({super.key, required this.schoolId, required this.classId, required this.username, required this.schoolName, required this.schoolAddress, required this.message, this.schoolPhoto});
  final String schoolId;
  final String classId;
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String message;
  final Image? schoolPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: BuildProfileCard(
          schoolPhoto: schoolPhoto,
          schoolAddress: schoolAddress,
          schoolName: schoolName,
        ),
      ),
      ElevatedButton(onPressed: (){
      Navigator.push(context, MaterialPageRoute(builder: (_)=>
HolidayPage(schoolId: schoolId, classId: classId, username: username,),));
},child: Text("School Attendance"),)]));
  }
}
