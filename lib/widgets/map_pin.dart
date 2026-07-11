import 'package:flutter/material.dart';

class MapPin extends StatelessWidget {
  final Color color;
  final double size;
  final String? label;

  const MapPin({
    super.key,
    this.color = const Color(0xFFFFD700),
    this.size = 40,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.55;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              label!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ],
    );
  }
}
