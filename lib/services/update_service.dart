import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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
      barrierDismissible: true, // Allow them to dismiss by tapping outside
      builder: (context) => _UpdateDialog(version: version, url: url),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String url;

  const _UpdateDialog({required this.version, required this.url});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'A new version of the app (VERSION) is available. Please update to continue tracking.';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading update...';
      _progress = 0.0;
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      final http.StreamedResponse response = await http.Client().send(request);

      final contentLength = response.contentLength;

      // Save to a temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/update_${widget.version}.apk';
      final file = File(filePath);

      final sink = file.openWrite();
      int downloaded = 0;

      await response.stream.map((chunk) {
        downloaded += chunk.length;
        if (contentLength != null) {
          setState(() {
            _progress = downloaded / contentLength;
          });
        }
        return chunk;
      }).pipe(sink);

      setState(() {
        _statusMessage = 'Opening installer...';
      });

      // Trigger the Android package installer popup
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Could not open installer: ${result.message}';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _progress = 0.0;
          _statusMessage = 'Please complete the installation in the system prompt.';
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download failed. Please try again.';
      });
      debugPrint('Download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusMessage.replaceAll('VERSION', widget.version)),
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(1)}%'),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        if (!_isDownloading)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _downloadAndInstall,
            child: const Text('Download & Install'),
          ),
      ],
    );
  }
}
