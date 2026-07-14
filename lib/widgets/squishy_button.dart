import 'package:flutter/material.dart';
import '../config/app_theme.dart';

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
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
    this.width = double.infinity,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  State<SquishyButton> createState() => _SquishyButtonState();
}

class _SquishyButtonState extends State<SquishyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _elevationAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _elevationAnim = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    _isPressed = true;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
    widget.onTap!();
  }

  void _onTapCancel() {
    _isPressed = false;
    _controller.reverse();
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8 + _elevationAnim.value * 4,
                    offset: Offset(0, 2 + _elevationAnim.value * 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: widget.foregroundColor,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.foregroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
