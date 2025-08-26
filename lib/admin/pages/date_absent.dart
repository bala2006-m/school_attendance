import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/date_button.dart';
import 'admin_dashboard.dart';
import 'date_wise_absentees.dart';

class DateAbsent extends StatefulWidget {
  final String date;
  final String className;
  final String section;
  final String classId;
  final String schoolId;
  final String username;
  const DateAbsent({
    super.key,
    required this.date,
    required this.className,
    required this.section,
    required this.classId,
    required this.schoolId,
    required this.username,
  });

  @override
  State<DateAbsent> createState() => _DateAbsentState();
}

class _DateAbsentState extends State<DateAbsent> {
  List<String> _forenoonAbsentees = [];
  List<Map<String, String>> _forenoonAbsenteesDetails = [];
  List<String> _afternoonAbsentees = [];
  List<Map<String, String>> _afternoonAbsenteesDetails = [];
  bool _showForenoon = true; // Initially show forenoon absentees
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final absentees = await ApiService.fetchTodayStudentAbsentees(
      widget.date,
      widget.schoolId,
      widget.classId,
    );

    setState(() {
      _forenoonAbsentees = List<String>.from(absentees['fn'] ?? []);
      _afternoonAbsentees = List<String>.from(absentees['an'] ?? []);
    });
    await _loadAbsenteesDetails();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAbsenteesDetails() async {
    _forenoonAbsenteesDetails = await _fetchStudentDetailsForList(
      _forenoonAbsentees,
    );
    _afternoonAbsenteesDetails = await _fetchStudentDetailsForList(
      _afternoonAbsentees,
    );
  }

  Future<List<Map<String, String>>> _fetchStudentDetailsForList(
    List<String> usernames,
  ) async {
    List<Map<String, String>> detailsList = [];
    for (String username in usernames) {
      final studentDetails = await ApiService.fetchStudentDetails(
        widget.schoolId,
        widget.classId,
        username,
      );
      if (studentDetails.isNotEmpty) {
        detailsList.add({
          'username': username,
          'name': studentDetails['name'] ?? 'N/A',
          'gender': studentDetails['gender'] ?? 'N/A',
          'email': studentDetails['email'] ?? 'N/A',
          'mobile': studentDetails['mobile'] ?? 'N/A',
        });
      } else {
        detailsList.add({
          'username': username,
          'name': 'Details not found',
          'gender': 'N/A',
          'email': 'N/A',
          'mobile': 'N/A',
        });
      }
    }
    return detailsList;
  }

  void loadStudent(String username, String classId, String schoolId) async {
    final student = await ApiService.fetchStudentDetails(
      schoolId,
      classId,
      username,
    );

    if (student.isNotEmpty) {
      // print("Name: ${student['name']}");
      // print("Gender: ${student['gender']}");
      // print("Email: ${student['email']}");
      // print("Mobile: ${student['mobile']}");
    } else {
      print("Student not found or error occurred.");
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  void _openWhatsApp(String phoneNumber) async {
    String url = "https://wa.me/$phoneNumber";
    if (await canLaunch(url)) await launch(url);
  }

  Future<bool> onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => DateWiseAbsentees(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: ' Absentees',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdminDashboard(
                                schoolId: widget.schoolId,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                  )
                  : const AdminAppbarDesktop(title: 'Absentees'),
        ),
        body:
            _isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.topLeft,
                        child: isMobile ? dateBuilder(widget.date) : null,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showForenoon = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _showForenoon ? Colors.cyan : Colors.grey,
                              ),
                              child: const Text('Forenoon'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showForenoon = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    !_showForenoon ? Colors.cyan : Colors.grey,
                              ),
                              child: const Text('Afternoon'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if ((_showForenoon &&
                              _forenoonAbsenteesDetails.isEmpty) ||
                          (!_showForenoon &&
                              _afternoonAbsenteesDetails.isEmpty))
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No absentees for ${_showForenoon ? "Forenoon" : "Afternoon"} on ${widget.date}',
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                _showForenoon
                                    ? _forenoonAbsenteesDetails.length
                                    : _afternoonAbsenteesDetails.length,
                            itemBuilder: (context, index) {
                              final studentDetails =
                                  _showForenoon
                                      ? _forenoonAbsenteesDetails[index]
                                      : _afternoonAbsenteesDetails[index];
                              final gender = studentDetails['gender'] ?? 'N/A';
                              final isMale =
                                  gender.toLowerCase() == 'male' ||
                                  gender.toLowerCase() == 'm';
                              final textColor =
                                  isMale ? Colors.blue : Colors.red;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Text(
                                        "${studentDetails['name']}",
                                        style: TextStyle(color: textColor),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Username: ${studentDetails['username']}",
                                        style: TextStyle(color: textColor),
                                      ),
                                      // Text("Gender: ${studentDetails['gender']}"), // Removed as it's shown with icon
                                      // Text("Email: ${studentDetails['email']}"), // Uncomment if needed
                                      // Text("Mobile: ${studentDetails['mobile']}"), // Uncomment if needed
                                    ],
                                  ),
                                  trailing: IconButton(
                                    // Call button moved to trailing
                                    icon: Icon(Icons.call, color: Colors.green),
                                    onPressed: () {
                                      final mobileNumber =
                                          studentDetails['mobile'] ?? '';
                                      if (mobileNumber.isNotEmpty) {
                                        if (kIsWeb) {
                                          _openWhatsApp(mobileNumber);
                                        } else {
                                          _makePhoneCall(mobileNumber);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
