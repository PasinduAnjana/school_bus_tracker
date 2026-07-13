import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final theme = Theme.of(context);

    if (driver.routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 20),
              Text(
                'No route assigned',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask an admin to assign a route to your account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (driver.tripActive) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _StatusBanner(driver: driver, theme: theme),
              const SizedBox(height: 24),
              _NextHaltCard(driver: driver, theme: theme),
              const SizedBox(height: 20),
              _ProgressSection(driver: driver, theme: theme),
              const Spacer(),
              _BigTripButton(driver: driver, theme: theme),
              if (driver.lastPing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last updated: ${driver.lastPing!.hour.toString().padLeft(2, '0')}:${driver.lastPing!.minute.toString().padLeft(2, '0')}:${driver.lastPing!.second.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            if (driver.routes.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownMenu<String>(
                  label: const Text('Select route'),
                  initialSelection: driver.selectedRouteId,
                  expandedInsets: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v != null) driver.selectRoute(v);
                  },
                  dropdownMenuEntries: driver.routes
                      .map((r) => DropdownMenuEntry(
                            value: r['id'] as String,
                            label: r['name'] as String,
                          ))
                      .toList(),
                ),
              ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 48,
                      color: Color(0xFFFFD700).withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ready to go',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      driver.selectedRouteId != null
                          ? driver.selectedRouteName!
                          : 'Select a route to begin',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BigTripButton(driver: driver, theme: theme),
            if (!driver.gpsReady)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_off, size: 16, color: Color(0xFFFF5252)),
                    const SizedBox(width: 6),
                    const Text(
                      'Enable GPS to start a trip',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _StatusBanner({required this.driver, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Trip Active',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const Spacer(),
          Text(
            driver.selectedRouteName ?? 'Unknown',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextHaltCard extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _NextHaltCard({required this.driver, required this.theme});

  String _timeToArrive(String arrivalTime) {
    final parts = arrivalTime.split(':');
    if (parts.length != 2) return '--';
    try {
      final now = DateTime.now();
      final scheduled = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      final diff = scheduled.difference(now);
      if (diff.isNegative) return 'Overdue';
      if (diff.inHours > 0) {
        return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      }
      return '${diff.inMinutes}m';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final halts = driver.halts;
    final nextHalt = halts.isNotEmpty
        ? halts
            .where((h) => !driver.completedHalts.contains(h.id))
            .fold<dynamic>(null, (prev, h) {
              if (prev == null || h.stopOrder < (prev as dynamic).stopOrder) return h;
              return prev;
            })
        : null;

    if (nextHalt == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 40, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            Text(
              halts.isEmpty ? 'No halts on this route' : 'All halts completed!',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final eta = _timeToArrive(nextHalt.arrivalTime);
    final isOverdue = eta == 'Overdue';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tour_rounded,
                size: 20,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              Text(
                'Next stop',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nextHalt.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isOverdue ? Icons.access_alarm : Icons.schedule,
                size: 16,
                color: isOverdue ? const Color(0xFFFF5252) : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Scheduled ${nextHalt.arrivalTime}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFFF5252).withValues(alpha: 0.1)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  eta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? const Color(0xFFFF5252) : const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _ProgressSection({required this.driver, required this.theme});

  @override
  Widget build(BuildContext context) {
    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Halts completed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$completed / $total',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _BigTripButton extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _BigTripButton({required this.driver, required this.theme});

  void _confirmStop(BuildContext context) {
    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End trip?'),
        content: Text('$completed of $total halts completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              driver.stopTrip();
            },
            child: const Text('End trip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = driver.tripActive;
    final canStart = driver.selectedRouteId != null && driver.gpsReady;

    return GestureDetector(
      onTap: isActive
          ? () => _confirmStop(context)
          : canStart
              ? () => driver.startTrip(context.read<AuthProvider>().currentUser!.id)
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFFFF5252) : const Color(0xFFFFD700))
                  .withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF1E1E1E),
              size: 44,
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'STOP' : 'START',
              style: TextStyle(
                color: const Color(0xFF1E1E1E),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
