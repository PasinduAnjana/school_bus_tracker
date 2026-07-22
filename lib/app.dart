import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/driver/driver_shell.dart';
import 'screens/parent/parent_shell.dart';
import 'services/update_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) {
        Widget home;
        switch (auth.status) {
          case AuthStatus.authenticated:
            final user = auth.currentUser!;
            home = switch (user.role) {
              UserRole.admin => const AdminShell(),
              UserRole.driver => const DriverShell(),
              UserRole.parent => const ParentShell(),
            };
          case AuthStatus.uninitialized:
            home = Scaffold(
              body: Center(
                child: Lottie.asset(
                  'assets/animations/login.json',
                  width: 200,
                  height: 200,
                ),
              ),
            );
          case AuthStatus.unauthenticated:
            home = const LoginScreen();
        }

        final themeProvider = context.watch<ThemeProvider>();

        return MaterialApp(
          key: ValueKey(auth.status),
          title: 'NID Express',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: _UpdateCheckerWrapper(child: home),
        );
      },
    );
  }
}

class _UpdateCheckerWrapper extends StatefulWidget {
  final Widget child;
  const _UpdateCheckerWrapper({required this.child});

  @override
  State<_UpdateCheckerWrapper> createState() => _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends State<_UpdateCheckerWrapper> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UpdateService.checkForUpdates(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
