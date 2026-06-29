import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_field.dart';
import '../widgets/squishy_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  bool _verifying = false;

  Future<void> _onVerify() async {
    if (_code.length != 6 || _verifying) return;
    _verifying = true;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_code);
    _verifying = false;

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Verify your\nnumber',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${auth.phoneNumber}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const Spacer(),
              OtpField(
                onCompleted: (code) => setState(() => _code = code),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => auth.sendOtp(),
                child: const Text('Resend code'),
              ),
              const Spacer(flex: 2),
              SquishyButton(
                label: 'VERIFY',
                isLoading: auth.isLoading,
                onTap: _onVerify,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
