import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/driver/driver_shell.dart';
import 'screens/parent/parent_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) {
        Widget home;
        if (auth.status == AuthStatus.authenticated) {
          final user = auth.currentUser!;
          home = switch (user.role) {
            UserRole.admin => const AdminShell(),
            UserRole.driver => const DriverShell(),
            UserRole.parent => const ParentShell(),
          };
        } else {
          home = const LoginScreen();
        }

        return MaterialApp(
          key: ValueKey(auth.status),
          title: 'School Bus Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: home,
        );
      },
    );
  }
}
