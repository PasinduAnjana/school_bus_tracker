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
    return MaterialApp(
      title: 'School Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthProvider>(
        builder: (_, auth, _) {
          if (auth.status == AuthStatus.authenticated) {
            final user = auth.currentUser!;
            switch (user.role) {
              case UserRole.admin:
                return const AdminShell();
              case UserRole.driver:
                return const DriverShell();
              case UserRole.parent:
                return const ParentShell();
            }
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
