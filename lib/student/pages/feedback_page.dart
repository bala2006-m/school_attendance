import 'package:flutter/material.dart' hide TextField;

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../components/text_fields.dart';
import '../services/student_api_services.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({
    super.key,
    required this.schoolId,
    required this.classId,
  });
  final String schoolId;
  final String classId;
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      try {
        await StudentApiServices.storeFeedback(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          feedback: messageController.text.trim(),
          schoolId: widget.schoolId,
          classId: widget.classId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Feedback submitted successfully!")),
        );
        nameController.clear();
        emailController.clear();
        messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.of(context).size.width > 600
              ? StudentAppbarDesktop(title: 'Send Feedback')
              : StudentAppbarMobile(title: 'Send Feedback'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField.buildTextField(
                label: "Name",
                controller: nameController,
                icon: Icons.person_outline,
                hint: "Optional",
              ),
              TextField.buildTextField(
                label: "Email",
                controller: emailController,
                icon: Icons.email_outlined,
                hint: "Optional, for follow-up",
                keyboardType: TextInputType.emailAddress,
              ),
              TextField.buildTextField(
                label: "Your Feedback",
                controller: messageController,
                icon: Icons.feedback_outlined,
                hint: "Let us know how we’re doing",
                maxLines: 5,
                required: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send),
                  label: const Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,

                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
