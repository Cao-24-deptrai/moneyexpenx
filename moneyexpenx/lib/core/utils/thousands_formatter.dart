import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digits
    String cleanString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Remove leading zeros, e.g. "05" -> "5", except if it is just "0"
    if (cleanString.length > 1 && cleanString.startsWith('0')) {
      cleanString = cleanString.replaceFirst(RegExp(r'^0+'), '');
    }

    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double? number = double.tryParse(cleanString);
    if (number == null) {
      return oldValue;
    }

    String formattedString = _formatter.format(number);

    // Calculate cursor selection
    int selectionIndex = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionIndex; i++) {
      if (i < newValue.text.length &&
          RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Special case: if we removed a leading zero, we might need to adjust digitsBeforeCursor
    int cleanDigitsCount = newValue.text
        .replaceAll(RegExp(r'[^\d]'), '')
        .length;
    int actualDigitsCount = cleanString.length;
    if (cleanDigitsCount > actualDigitsCount) {
      digitsBeforeCursor -= (cleanDigitsCount - actualDigitsCount);
      if (digitsBeforeCursor < 0) digitsBeforeCursor = 0;
    }

    int newSelectionIndex = 0;
    int digitsSeen = 0;
    while (digitsSeen < digitsBeforeCursor &&
        newSelectionIndex < formattedString.length) {
      if (RegExp(r'\d').hasMatch(formattedString[newSelectionIndex])) {
        digitsSeen++;
      }
      newSelectionIndex++;
    }

    newSelectionIndex = newSelectionIndex.clamp(0, formattedString.length);

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
