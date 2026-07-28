import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new input is empty, return empty value immediately
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String oldClean = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String newClean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Detect if deletion/backspace occurred
    bool isDeleting = oldValue.text.length > newValue.text.length;

    // When user backspaces directly on a separator (e.g. dot or comma),
    // newClean would match oldClean (no digits removed), making Backspace do nothing.
    // In this case, we manually drop the digit right before the deleted separator.
    if (isDeleting && oldValue.selection.isCollapsed && oldClean.isNotEmpty && oldClean == newClean) {
      int cursorOffset = newValue.selection.end;
      int digitsBeforeCursor = 0;
      for (int i = 0; i < cursorOffset; i++) {
        if (i < oldValue.text.length && RegExp(r'\d').hasMatch(oldValue.text[i])) {
          digitsBeforeCursor++;
        }
      }
      if (digitsBeforeCursor > 0 && digitsBeforeCursor <= newClean.length) {
        newClean = newClean.substring(0, digitsBeforeCursor - 1) +
            newClean.substring(digitsBeforeCursor);
      }
    }

    // Remove leading zeros if length > 1 (e.g. "05" -> "5")
    if (newClean.length > 1 && newClean.startsWith('0')) {
      newClean = newClean.replaceFirst(RegExp(r'^0+'), '');
    }

    // If clean string is empty or becomes zero after backspacing, clear the text field
    if (newClean.isEmpty || (isDeleting && newClean == '0')) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    double? number = double.tryParse(newClean);
    if (number == null) {
      return oldValue;
    }

    String formattedString = _formatter.format(number);

    // Calculate cursor position based on digits before cursor
    int selectionIndex = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionIndex && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Adjust for any leading zeros stripped
    int rawDigitsCount = newValue.text.replaceAll(RegExp(r'[^\d]'), '').length;
    if (rawDigitsCount > newClean.length) {
      digitsBeforeCursor -= (rawDigitsCount - newClean.length);
      if (digitsBeforeCursor < 0) digitsBeforeCursor = 0;
    }

    int newSelectionIndex = 0;
    int digitsSeen = 0;
    while (digitsSeen < digitsBeforeCursor && newSelectionIndex < formattedString.length) {
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
