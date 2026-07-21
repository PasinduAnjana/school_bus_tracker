import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SwipeToDeleteTile extends StatefulWidget {
  final String itemKey;
  final Widget child;
  final Future<bool> Function() onConfirmDelete;

  const SwipeToDeleteTile({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onConfirmDelete,
  });

  @override
  State<SwipeToDeleteTile> createState() => _SwipeToDeleteTileState();
}

class _SwipeToDeleteTileState extends State<SwipeToDeleteTile> {
  bool _hapticPlayed = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.itemKey),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      onUpdate: (details) {
        if (details.progress > 0.4 && !_hapticPlayed) {
          HapticFeedback.mediumImpact();
          setState(() => _hapticPlayed = true);
        } else if (details.progress <= 0.4 && _hapticPlayed) {
          setState(() => _hapticPlayed = false);
        }
      },
      confirmDismiss: (direction) async {
        // Trigger a final haptic on release
        HapticFeedback.heavyImpact();
        
        // Show confirmation dialog
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this item? This cannot be undone.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          return await widget.onConfirmDelete();
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28)
            .animate(target: _hapticPlayed ? 1 : 0)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.15, 1.15),
              duration: 200.ms,
              curve: Curves.easeOutBack,
            )
            .tint(
              color: Colors.white.withValues(alpha: 0.5),
              duration: 100.ms,
            )
            .then()
            .shake(
              hz: 3,
              duration: 300.ms,
            ),
      ),
      child: widget.child,
    );
  }
}
