import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    setState(() => _verifying = true);

    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_code);
    
    if (!mounted) return;
    setState(() => _verifying = false);

    if (success) {
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid code. Try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.message_rounded,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Verify your number',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Enter the 6-digit code we sent to\n'),
                          TextSpan(
                            text: auth.phoneNumber,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    OtpField(
                      onCompleted: (code) {
                        setState(() => _code = code);
                        _onVerify(); // Auto-verify!
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            auth.sendOtp();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Code resent!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: Text(
                            'Resend',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    SquishyButton(
                      label: 'VERIFY',
                      isLoading: _verifying || auth.isLoading,
                      onTap: _onVerify,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
