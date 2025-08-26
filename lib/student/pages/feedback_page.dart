import 'package:flutter/material.dart' hide TextField;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../components/text_fields.dart';
import '../services/student_api_services.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.username,
  });

  final String schoolId;
  final String classId;
  final String username;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? studentData;
  final TextEditingController messageController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    init();
    messageController.addListener(_checkFormFilled);
  }

  Future<void> init() async {
    final data = await StudentApiServices.fetchStudentDataUsername(
      username: widget.username,
      schoolId: int.parse(widget.schoolId),
    );
    setState(() {
      studentData = data;
    });
  }

  void _checkFormFilled() {
    setState(() {
      isButtonEnabled = messageController.text.trim().isNotEmpty;
    });
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await StudentApiServices.storeFeedback(
          name: studentData?['name'],
          email: studentData?['email'],
          feedback: messageController.text.trim(),
          schoolId: widget.schoolId,
          classId: widget.classId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Feedback submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Feedback',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 1;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : const StudentAppbarDesktop(title: 'Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "We value your feedback",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Please share your thoughts to help us improve your experience.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField.buildTextField(
                    label: "Your Feedback",
                    controller: messageController,
                    icon: Icons.feedback_outlined,
                    hint: "Let us know how we’re doing…",
                    maxLines: 8,
                    required: true,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isButtonEnabled && !isLoading ? _submitFeedback : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                        isButtonEnabled ? Colors.blueAccent : Colors.grey[400],
                    elevation: 3,
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: SpinKitFadingCircle(
                              color: Colors.blueAccent,
                              size: 60.0,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Submit Feedback",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
