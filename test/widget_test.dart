import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:school_bus_tracker/providers/auth_provider.dart';
import 'package:school_bus_tracker/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders phone input and button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('NID Express'), findsOneWidget);
    expect(find.text('Enter your phone number to get started'), findsOneWidget);
  });
}
