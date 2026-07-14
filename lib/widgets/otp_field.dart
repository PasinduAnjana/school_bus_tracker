import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpField extends StatelessWidget {
  final ValueChanged<String> onCompleted;

  const OtpField({super.key, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 60,
      height: 72,
      textStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.onSurface, width: 2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Pinput(
      length: 6,
      autofocus: true,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border(
            bottom: BorderSide(color: colorScheme.primary, width: 3),
          ),
        ),
      ),
      onCompleted: onCompleted,
    );
  }
}
