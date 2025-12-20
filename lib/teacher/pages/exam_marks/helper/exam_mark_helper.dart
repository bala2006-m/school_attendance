// ---------------------------
// Helper utilities
// ---------------------------
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Try parse ISO date or yyyy-MM-dd; return null on failure
DateTime? tryParseDate(String? txt) {
  if (txt == null) return null;
  final s = txt.trim();
  if (s.isEmpty) return null;
  try {
    // Try direct parse (handles ISO etc.)
    return DateTime.parse(s);
  } catch (_) {
    // Try parsing as yyyy-MM-dd using DateFormat
    try {
      final dt = DateFormat('yyyy-MM-dd').parseLoose(s);
      return dt;
    } catch (_) {
      return null;
    }
  }
}

/// Safe formatting to yyyy-MM-dd (returns empty string if invalid)
String safeFormatToYMD(String? txt) {
  final dt = tryParseDate(txt);
  if (dt == null) return '';
  return DateFormat('yyyy-MM-dd').format(dt);
}

/// Validate date string is exactly yyyy-MM-dd (loose acceptance then format)
bool isValidYmd(String? txt) {
  final d = tryParseDate(txt);
  return d != null;
}

void showErrorDialog({
  required BuildContext context,
  required String errorMessage,
}) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void showColoredSnackBar({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
