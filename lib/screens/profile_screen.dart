import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/app_theme.dart';
import '../widgets/frosted_card.dart';
import '../widgets/squishy_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            FrostedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: (user?.name != null && user!.name!.isNotEmpty)
                          ? Text(
                              user.name![0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (user?.name != null && user!.name!.isNotEmpty)
                          ? user.name!
                          : (user?.phoneNumber ?? ''),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Chip(label: Text(user?.role.name.toUpperCase() ?? '')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FrostedCard(
              child: Column(
                children: [
                  _SettingItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    subtitle: user?.phoneNumber,
                  ),
                  Divider(
                    indent: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  _SettingItem(
                    icon: Icons.badge_outlined,
                    title: 'Role',
                    subtitle: user?.role.name.toUpperCase(),
                  ),
                  Divider(
                    indent: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  _SettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark || 
                             (themeProvider.themeMode == ThemeMode.system && 
                              MediaQuery.platformBrightnessOf(context) == Brightness.dark),
                      onChanged: (isDark) {
                        themeProvider.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: SquishyButton(
                onTap: () => auth.signOut(),
                icon: Icons.logout_rounded,
                label: 'Logout',
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
