import 'package:flutter/services.dart';

/// Groups digits using spaces: 1000000 -> 1 000 000.
/// Keeps fractional part (after dot or comma) untouched.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    // Keep only digits/spaces/dot/comma.
    final sanitized = raw.replaceAll(RegExp(r'[^0-9\s\.,]'), '');
    final parts = sanitized.split(RegExp(r'[.,]'));
    final intPartRaw = parts.isNotEmpty ? parts.first : '';
    final fracPart = parts.length > 1 ? parts.sublist(1).join() : null;

    final digits = intPartRaw.replaceAll(RegExp(r'[\s\u00A0]'), '');
    final grouped = _groupDigits(digits);
    final decimalSep = sanitized.contains(',') ? ',' : '.';
    final formatted = fracPart == null || fracPart.isEmpty
        ? grouped
        : '$grouped$decimalSep$fracPart';

    // Compute cursor based on digit count to the right.
    final oldCursor = newValue.selection.baseOffset.clamp(0, raw.length);
    final rightRaw = raw.substring(oldCursor);
    final rightDigits = rightRaw.replaceAll(RegExp(r'[^0-9]'), '').length;
    final newCursor = _cursorFromRightDigitCount(formatted, rightDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  String _groupDigits(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write(' ');
      }
    }
    return buf.toString();
  }

  int _cursorFromRightDigitCount(String formatted, int rightDigits) {
    if (rightDigits <= 0) return formatted.length;
    var count = 0;
    for (var i = formatted.length - 1; i >= 0; i--) {
      final ch = formatted[i];
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        count++;
        if (count == rightDigits) return i;
      }
    }
    return 0;
  }
}

