import 'package:flutter/material.dart';

class SlideToEnd extends StatefulWidget {
  final VoidCallback onComplete;
  const SlideToEnd({super.key, required this.onComplete});

  @override
  State<SlideToEnd> createState() => _SlideToEndState();
}

class _SlideToEndState extends State<SlideToEnd> with SingleTickerProviderStateMixin {
  double _dragFraction = 0.0;
  bool _completed = false;
  bool _isDragging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    if (_completed) return;
    setState(() {
      _isDragging = true;
      _dragFraction = (d.localPosition.dx / width).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(double width) {
    if (_completed) return;
    setState(() {
      _isDragging = false;
    });
    if (_dragFraction >= 0.8) {
      setState(() {
        _completed = true;
        _dragFraction = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      setState(() {
        _dragFraction = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final thumbSize = 52.0;
        final maxSlide = width - thumbSize - 8;
        final thumbLeft = 4.0 + maxSlide * _dragFraction;

        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
          onHorizontalDragEnd: (_) => _onDragEnd(width),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Container(
                width: width,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.error,
                      Theme.of(context).colorScheme.error.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: thumbLeft + thumbSize / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: AnimatedSlide(
                          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                          offset: Offset(_dragFraction * 0.2, 0),
                          child: AnimatedOpacity(
                            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                            opacity: (1.0 - (_dragFraction * 2.0)).clamp(0.0, 1.0),
                            child: Text(
                              'Slide to end trip',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      left: thumbLeft,
                      top: 6,
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            if (!_isDragging && !_completed)
                              BoxShadow(
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4 * _pulseAnimation.value),
                                blurRadius: 12 + (10 * _pulseAnimation.value),
                                spreadRadius: 2 * _pulseAnimation.value,
                              ),
                          ],
                        ),
                        child: Transform.translate(
                          offset: Offset(!_isDragging && !_completed ? 4.0 * _pulseAnimation.value : 0, 0),
                          child: Icon(
                            _completed ? Icons.check_rounded : Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
