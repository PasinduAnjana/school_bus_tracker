import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
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

  Future<void> _onVerify() async {
    if (_code.length != 4) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_code);

    if (!mounted) return;

    if (success) {
      final user = auth.currentUser!;
      Widget destination;
      switch (user.role) {
        case UserRole.admin:
          destination = const _PlaceholderScreen(title: 'Admin Dashboard');
        case UserRole.driver:
          destination = const _PlaceholderScreen(title: 'Driver Dashboard');
        case UserRole.parent:
          destination = const _PlaceholderScreen(title: 'Parent Dashboard');
      }

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => destination,
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
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
                'Enter the 4-digit code sent to\n${auth.phoneNumber}',
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title coming soon',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
