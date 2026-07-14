import 'package:flutter/material.dart';

class MapPin extends StatelessWidget {
  final Color? color;
  final double size;
  final String? label;

  const MapPin({super.key, this.color, this.size = 40, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pinColor = color ?? colorScheme.primary;
    final iconSize = size * 0.55;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (label != null)
            Positioned(
              bottom: size + 4,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  label!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus,
              color: colorScheme.onPrimary,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}
