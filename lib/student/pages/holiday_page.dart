import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';

class HolidayPage extends StatefulWidget {
  final String schoolId;
  final String classId;

  const HolidayPage({super.key, required this.schoolId, required this.classId});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  List<Map<String, dynamic>> holidays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final fetched = await StudentApiServices.fetchHolidaysClasses(
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      setState(() {
        holidays = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        holidays = [];
        isLoading = false;
      });
    }
  }

  String formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  String buildFnAnText(String fn, String an) {
    String fnText = fn == 'H' ? 'Holiday' : 'Working Day';
    String anText = an == 'H' ? 'Holiday' : 'Working Day';
    return 'FN: $fnText | AN: $anText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.of(context).size.width > 600
              ? StudentAppbarDesktop(title: 'Holidays')
              : StudentAppbarMobile(title: 'Holidays'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            isLoading
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : holidays.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No holidays available at the moment.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : ListView.separated(
                  itemCount: holidays.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final holiday = holidays[index];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.indigo.shade400,
                        ),
                        title: Text(
                          holiday["reason"] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          formatDate(holiday["date"] ?? ''),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          buildFnAnText(
                            holiday['fn'] ?? '-',
                            holiday['an'] ?? '-',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
