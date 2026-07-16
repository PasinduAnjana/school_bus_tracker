import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/monitor_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/halt_tile.dart';

class ParentHaltsPage extends StatelessWidget {
  final String? routeId;
  final void Function(Halt halt)? onHaltTap;
  const ParentHaltsPage({super.key, this.routeId, this.onHaltTap});

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final theme = Theme.of(context);

    final hasActiveTrip = monitor.activeTrips.any((t) => t.routeId == routeId);

    if (monitor.halts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveTrip
                  ? 'No stops on this route'
                  : 'Bus is not active right now',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final completed = monitor.completedHaltIds.length;
    final total = monitor.halts.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FrostedCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey progress',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed of $total stops completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: monitor.halts.length,
            itemBuilder: (context, index) {
              final halt = monitor.halts[index];
              final done = monitor.completedHaltIds.contains(halt.id);
              final nextHalt = monitor.halts
                  .where((h) => !monitor.completedHaltIds.contains(h.id))
                  .firstOrNull;
              final isNext = !done && halt.id == nextHalt?.id;

              return HaltTile(
                halt: halt,
                isDone: done,
                isNext: isNext,
                isTripActive: hasActiveTrip,
                onTap: halt.latitude != null && halt.longitude != null
                    ? () => onHaltTap?.call(halt)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
