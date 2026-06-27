import 'package:flutter/material.dart';

class SquishyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final double width;
  final double height;
  final bool isLoading;

  const SquishyButton({
    super.key,
    required this.label,
    this.onTap,
    this.backgroundColor = const Color(0xFFFFD700),
    this.foregroundColor = const Color(0xFF1E1E1E),
    this.width = double.infinity,
    this.height = 60,
    this.isLoading = false,
  });

  @override
  State<SquishyButton> createState() => _SquishyButtonState();
}

class _SquishyButtonState extends State<SquishyButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _scale = 0.94);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    setState(() => _scale = 1.0);
    widget.onTap!();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(
        ignoring: widget.isLoading,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1E1E1E),
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
