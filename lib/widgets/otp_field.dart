import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

class SmsRetrieverImpl implements SmsRetriever {
  const SmsRetrieverImpl(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() {
    return smartAuth.removeUserConsentApiListener();
  }

  @override
  Future<String?> getSmsCode() async {
    final res = await smartAuth.getSmsWithUserConsentApi();
    if (res.hasData) {
      return res.requireData.code;
    }
    return null;
  }

  @override
  bool get listenForMultipleSms => false;
}

class OtpField extends StatefulWidget {
  final ValueChanged<String> onCompleted;

  const OtpField({super.key, required this.onCompleted});

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _smartAuth = SmartAuth.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 64,
      height: 72,
      textStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
    );

    return Pinput(
      length: 6,
      autofocus: true,
      smsRetriever: SmsRetrieverImpl(_smartAuth),
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      cursor: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 24,
            height: 2,
            color: colorScheme.primary,
          ),
        ],
      ),
      onCompleted: widget.onCompleted,
    );
  }
}
