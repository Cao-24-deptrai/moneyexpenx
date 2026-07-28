import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';

class CustomNumericKeypad extends StatelessWidget {
  final Function(String key) onKeyPress;
  final double buttonHeight;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CustomNumericKeypad({
    Key? key,
    required this.onKeyPress,
    this.buttonHeight = 52,
    this.fontSize = 22,
    this.padding = const EdgeInsets.all(8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return GlassContainer(
      borderRadius: 16,
      width: double.infinity,
      color: Colors.black.withOpacity(0.4),
      borderColor: Colors.white.withOpacity(0.05),
      borderWidth: 1.5,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: row.map((key) {
                final isSpecial = key == 'C' || key == '⌫';
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: buttonHeight,
                    child: GlassCardButton(
                      onTap: () => onKeyPress(key),
                      color: isSpecial ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.08),
                      borderColor: Colors.white.withOpacity(0.02),
                      borderRadius: 12,
                      child: Center(
                        child: Text(
                          key,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: isSpecial ? AppTheme.primaryYellow : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String handleNumericKeypadInput(String key, String currentAmountStr, {int maxDigits = 12}) {
  if (key == 'C') {
    return '0';
  } else if (key == '⌫') {
    if (currentAmountStr.length > 1) {
      return currentAmountStr.substring(0, currentAmountStr.length - 1);
    } else {
      return '0';
    }
  } else {
    if (currentAmountStr == '0' || currentAmountStr.isEmpty) {
      return key;
    } else {
      if (currentAmountStr.length < maxDigits) {
        return currentAmountStr + key;
      }
    }
  }
  return currentAmountStr;
}
