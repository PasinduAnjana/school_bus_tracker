import 'package:flutter/material.dart';
import '../models/halt.dart';
import 'frosted_card.dart';

class HaltTile extends StatelessWidget {
  final Halt halt;
  final bool isDone;
  final bool isNext;
  final bool isTripActive;
  final VoidCallback? onTap;
  final DateTime? completedAt;

  const HaltTile({
    super.key,
    required this.halt,
    required this.isDone,
    required this.isNext,
    this.isTripActive = true,
    this.onTap,
    this.completedAt,
  });

  String _getTimingStatus(String arrivalTime, bool isDone, bool isTripActive) {
    if (isDone) return 'Completed';
    if (!isTripActive) return 'Expected $arrivalTime';
    
    try {
      final now = DateTime.now();
      final parts = arrivalTime.split(':');
      final target = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final diff = now.difference(target).inMinutes;

      if (diff > 0) {
        return '$diff mins late';
      } else if (diff < 0) {
        return 'in ${-diff} mins';
      } else {
        return 'Due now';
      }
    } catch (_) {
      return 'Expected $arrivalTime';
    }
  }

  Color _getStatusColor(ThemeData theme, String status) {
    if (status == 'Completed') return theme.colorScheme.tertiary;
    if (status.contains('late')) return theme.colorScheme.error;
    if (status.contains('in') || status == 'Due now') return theme.colorScheme.primary;
    return theme.colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _getTimingStatus(halt.arrivalTime, isDone, isTripActive);
    final statusColor = _getStatusColor(theme, status);

    return FrostedCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.15)
                      : isNext
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: isDone
                        ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                        : isNext
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? Icon(Icons.check, size: 24, color: theme.colorScheme.tertiary)
                    : isNext
                        ? Icon(Icons.directions_bus, size: 20, color: theme.colorScheme.primary)
                        : Text(
                            '${halt.stopOrder + 1}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
              ),
              const SizedBox(width: 16),
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      halt.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                        color: isDone ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone && completedAt != null
                              ? 'Arrived at ${completedAt!.hour.toString().padLeft(2, '0')}:${completedAt!.minute.toString().padLeft(2, '0')}'
                              : halt.arrivalTime,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
