import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/PasinduAnjana/school_bus_tracker/releases/latest';

  static Future<void> checkForUpdates(BuildContext context) async {
    // Only prompt for updates on Android where we use APKs.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final String latestVersionTag = data['tag_name'] ?? ''; // e.g. 'v1.0.1'
      final String latestVersion = latestVersionTag.replaceAll('v', '');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        // Look for the APK file in the release assets
        final assets = data['assets'] as List;
        String? downloadUrl;
        for (final asset in assets) {
          final name = (asset['name'] as String).toLowerCase();
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        if (downloadUrl != null && context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to update
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: Text(
            'A new version of the app ($version) is available. Please update to continue tracking.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }
}
