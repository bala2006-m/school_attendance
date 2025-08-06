import 'package:flutter/material.dart';

class StatusDialog extends StatelessWidget {
  final bool isSuccess;
  final VoidCallback onPressed;
  final String message1;

  const StatusDialog({
    Key? key,
    required this.isSuccess,
    required this.onPressed,
    required this.message1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isSuccess ? Colors.greenAccent.shade100 : Colors.redAccent.shade100;
    final face = isSuccess ? '✅' : '❌';
    final title = isSuccess ? 'SUCCESS!' : 'ERROR!';
    final buttonText = isSuccess ? 'OK' : 'TRY AGAIN';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(face, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
