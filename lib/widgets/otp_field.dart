import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpField extends StatelessWidget {
  final ValueChanged<String> onCompleted;

  const OtpField({super.key, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 72,
      textStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E1E1E),
      ),
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 2),
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
          border: const Border(
            bottom: BorderSide(color: Color(0xFFFFD700), width: 3),
          ),
        ),
      ),
      onCompleted: onCompleted,
    );
  }
}
