import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/slide_to_end.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final theme = Theme.of(context);

    if (driver.routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 20),
              Text(
                'No route assigned',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask an admin to assign a route to your account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _BackgroundGradient(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: driver.tripActive
                  ? _ActiveTripContent(
                      key: const ValueKey('active'),
                      driver: driver,
                    )
                  : _IdleContent(key: const ValueKey('idle'), driver: driver),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(Theme.of(context).colorScheme.primary),
      child: const SizedBox.expand(),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color primaryColor;
  _BackgroundPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor.withValues(alpha: 0.07), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final circlePaint = Paint()..color = primaryColor.withValues(alpha: 0.04);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * -0.1),
      size.width * 0.4,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.5),
      size.width * 0.25,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IdleContent extends StatelessWidget {
  final DriverProvider driver;
  const _IdleContent({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (driver.assignedBusName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Assigned to: ${driver.assignedBusName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (driver.routes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownMenu<String>(
              label: const Text('Select route'),
              initialSelection: driver.selectedRouteId,
              expandedInsets: EdgeInsets.zero,
              onSelected: (v) {
                if (v != null) driver.selectRoute(v);
              },
              dropdownMenuEntries: driver.routes
                  .map(
                    (r) => DropdownMenuEntry(
                      value: r['id'] as String,
                      label: r['name'] as String,
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FrostedCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          size: 30,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        driver.routes.isEmpty
                            ? 'No route assigned'
                            : driver.selectedRouteId == null
                                ? 'Select a Route'
                                : 'Ready to go',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        driver.routes.isEmpty
                            ? 'Please contact your administrator'
                            : driver.selectedRouteId == null
                                ? 'Choose a route from below to begin'
                                : 'Press start to begin your trip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _BigTripButton(driver: driver),
              ],
            ),
          ),
        ),
        if (!driver.gpsReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gps_off, size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Text(
                  'Enable GPS to start a trip',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActiveTripContent extends StatelessWidget {
  final DriverProvider driver;
  const _ActiveTripContent({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        _StatusBanner(driver: driver),
        const SizedBox(height: 20),
        FrostedCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          child: _NextHaltContent(driver: driver, theme: theme),
        ),
        const SizedBox(height: 16),
        FrostedCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: _ProgressContent(driver: driver),
        ),
        Expanded(
          child: Center(child: _BigTripButton(driver: driver)),
        ),
        if (driver.lastPing != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Last updated: ${driver.lastPing!.hour.toString().padLeft(2, '0')}:${driver.lastPing!.minute.toString().padLeft(2, '0')}:${driver.lastPing!.second.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DriverProvider driver;
  const _StatusBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary.withValues(alpha: 0.12),
            theme.colorScheme.tertiary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          _PulseDot(color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Active',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              Text(
                driver.selectedRouteName ?? 'Unknown',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextHaltContent extends StatelessWidget {
  final DriverProvider driver;
  final ThemeData theme;
  const _NextHaltContent({required this.driver, required this.theme});

  String _timeToArrive(String arrivalTime) {
    final parts = arrivalTime.split(':');
    if (parts.length != 2) return '--';
    try {
      final now = DateTime.now();
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final diff = scheduled.difference(now);
      if (diff.isNegative) return 'Overdue';
      if (diff.inHours > 0) {
        return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      }
      return '${diff.inMinutes}m';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final halts = driver.halts;
    final nextHalt = halts.isNotEmpty
        ? halts.where((h) => !driver.completedHalts.contains(h.id)).firstOrNull
        : null;

    if (nextHalt == null) {
      return Column(
        children: [
          Icon(Icons.check_circle, size: 40, color: theme.colorScheme.tertiary),
          const SizedBox(height: 8),
          Text(
            halts.isEmpty ? 'No halts on this route' : 'All halts completed!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final eta = _timeToArrive(nextHalt.arrivalTime);
    final isOverdue = eta == 'Overdue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tour_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Next stop',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                nextHalt.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOverdue
                    ? theme.colorScheme.error.withValues(alpha: 0.1)
                    : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                eta,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              isOverdue ? Icons.access_alarm : Icons.schedule,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Scheduled ${nextHalt.arrivalTime}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final DriverProvider driver;
  const _ProgressContent({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = driver.completedHalts.length;
    final total = driver.halts.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
              Row(
                children: [
                  Text(
                    'Halts completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completed / $total',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigTripButton extends StatefulWidget {
  final DriverProvider driver;
  const _BigTripButton({required this.driver});

  @override
  State<_BigTripButton> createState() => _BigTripButtonState();
}

class _BigTripButtonState extends State<_BigTripButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnim;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _maybeStartPulse();
  }

  void _maybeStartPulse() {
    if (!widget.driver.tripActive &&
        widget.driver.selectedRouteId != null &&
        widget.driver.gpsReady) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_pulseController!);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.driver.tripActive;
    final canStart =
        widget.driver.selectedRouteId != null && widget.driver.gpsReady;

    if (isActive) {
      if (_starting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _starting = false);
        });
      }
      return SlideToEnd(onComplete: () => widget.driver.stopTrip());
    }

    final showPulse = canStart && _pulseAnim != null && !_starting;

    final buttonContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _starting
          ? Column(
              key: const ValueKey('loading'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'STARTING',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 56,
                ),
                const SizedBox(height: 4),
                Text(
                  'START',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
    );

    Widget button = GestureDetector(
      onTap: (canStart && !_starting)
          ? () {
              setState(() => _starting = true);
              widget.driver.startTrip(
                context.read<AuthProvider>().currentUser!.id,
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: _starting ? 160 : 200,
        height: _starting ? 160 : 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: _starting ? 0.9 : 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: _starting ? 0.15 : (showPulse ? 0.5 : 0.3),
                  ),
              blurRadius: _starting ? 8 : (showPulse ? 28 : 20),
              offset: Offset(0, _starting ? 2 : 8),
            ),
          ],
        ),
        child: buttonContent,
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        if (canStart && _pulseAnim != null)
          AnimatedBuilder(
            animation: _pulseAnim!,
            builder: (_, _) {
              final pulseValue = _pulseAnim!.value;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _starting ? 0.0 : 1.0,
                child: Transform.scale(
                  scale: 1.0 + pulseValue * 0.15,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.15 * (1.0 - pulseValue),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          const SizedBox(width: 200, height: 200),
        button,
      ],
    );
  }
}

