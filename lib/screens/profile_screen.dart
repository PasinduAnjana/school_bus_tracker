import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../widgets/frosted_card.dart';
import '../widgets/squishy_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: AppColors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.phoneNumber ?? '',
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
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
              ),
            ),
            const SizedBox(height: 24),
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

  const _SettingItem({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
