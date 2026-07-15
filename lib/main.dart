import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/monitor_provider.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load();
    await SupabaseService.init();
    await NotificationService.init();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      backgroundServiceEntrypoint();
    }
  } catch (e, stackTrace) {
    debugPrint('Init Error: $e\n$stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to initialize app:\n\n$e\n\n$stackTrace',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  // Request permissions safely AFTER the main init block
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.requestPermissions();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => MonitorProvider()),
      ],
      child: const App(),
    ),
  );
}
