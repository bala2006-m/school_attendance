import 'package:flutter/material.dart';

import '../../admin/components/build_profile_card_mobile.dart';
import '../../admin/components/message_box.dart';
import '../pages/timetable_page.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key, required this.schoolId, required this.classId, required this.username, this.schoolPhoto, required this.schoolName, required this.schoolAddress, required this.message});
  final String schoolId;
  final String classId;
  final String username;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final String message;

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
      MessageBox(message: message),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: (){
      Navigator.push(context, MaterialPageRoute(builder: (_)=>TimeTablePage(schoolId: schoolId, classId: classId, username: username,)));
    },child:Text("Time Table"))]));
  }
}
