import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  final double maxValue;

  DecimalTextInputFormatter({
    required this.decimalRange,
    required this.maxValue,
  }) : assert(decimalRange >= 0);

  final RegExp _decimalRegex = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    if (!_decimalRegex.hasMatch(newValue.text)) {
      return oldValue;
    }

    if (newValue.text.contains('.')) {
      final parts = newValue.text.split('.');
      if (parts.length > 2) return oldValue;
      if (parts[1].length > decimalRange) return oldValue;
    }

    try {
      final value = double.parse(newValue.text);
      if (value > maxValue) return oldValue;
    } catch (_) {
      return oldValue;
    }

    return newValue;
  }
}
