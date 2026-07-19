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

    final maxCompletedIndex = monitor.halts
        .lastIndexWhere((h) => monitor.completedHaltIds.contains(h.id));
    final completed = maxCompletedIndex + 1;
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
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.1),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '$completed/$total',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                        'Route Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        completed == total
                            ? 'All stops completed'
                            : 'Heading to stop ${completed + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
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
              final done = index <= maxCompletedIndex;
              final isNext = index == maxCompletedIndex + 1;

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
