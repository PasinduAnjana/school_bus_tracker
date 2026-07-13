import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/frosted_card.dart';

class DriverStopsPage extends StatelessWidget {
  final void Function(Halt halt)? onHaltTap;
  const DriverStopsPage({super.key, this.onHaltTap});

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final theme = Theme.of(context);

    if (driver.halts.isEmpty) {
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
              driver.routes.isEmpty
                  ? 'No route assigned'
                  : 'Select a route from the home tab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
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
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0 ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
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
                        driver.selectedRouteName ?? 'Route',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed of $total halts completed',
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
            itemCount: driver.halts.length,
            itemBuilder: (context, index) {
              final halt = driver.halts[index];
              final done = driver.completedHalts.contains(halt.id);
              final nextHalt = driver.halts.where((h) => !driver.completedHalts.contains(h.id)).firstOrNull;
              final isNext = !done && halt.id == nextHalt?.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isNext
                      ? const BorderSide(color: Color(0xFFFFD700), width: 1.5)
                      : BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: halt.latitude != null && halt.longitude != null
                      ? () => onHaltTap?.call(halt)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? const Color(0xFF4CAF50)
                                : isNext
                                    ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                    : theme.colorScheme.surfaceContainerHighest,
                          ),
                          alignment: Alignment.center,
                          child: done
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isNext
                                        ? const Color(0xFFFFD700)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                halt.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    halt.arrivalTime,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: done
                              ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22)
                              : isNext
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'NEXT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E1E1E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Color(0xFFFFD700),
                                      size: 22,
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
