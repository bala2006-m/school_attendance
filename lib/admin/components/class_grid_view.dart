import 'package:flutter/material.dart';

typedef OnClassTap = void Function(Map<String, dynamic> classData);

class ClassGridView extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final Map<String, bool> attendanceStatusMap;
  final OnClassTap onClassTap;

  const ClassGridView({
    super.key,
    required this.classes,
    required this.attendanceStatusMap,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    if (classes.isEmpty) {
      return const Center(child: Text("No Classes Found"));
    }

    return GridView.builder(
      itemCount: classes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = classes[index];
        final classId = item['id'].toString();
        final isMarked = attendanceStatusMap[classId] ?? false;

        return GestureDetector(
          onTap: isMarked ? null : () => onClassTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: isMarked ? Colors.white : Colors.teal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${item['class']} Std",
                    style: TextStyle(
                      fontSize: 18,
                      color: isMarked ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${item['section']} Sec",
                    style: TextStyle(
                      color: isMarked ? Colors.black54 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
