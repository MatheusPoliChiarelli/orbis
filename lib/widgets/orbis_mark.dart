import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

class OrbisMark extends StatefulWidget {
  const OrbisMark({
    super.key,
    this.size = 96,
    this.animate = true,
  });

  final double size;

  final bool animate;

  @override
  State<OrbisMark> createState() => _OrbisMarkState();
}

class _OrbisMarkState extends State<OrbisMark>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1000000;
    });
    if (widget.animate) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ValueListenableBuilder<double>(
        valueListenable: _seconds,
        builder: (context, seconds, _) {
          return CustomPaint(
            painter: _OrbisPainter(seconds: seconds),
          );
        },
      ),
    );
  }
}

class _Orbit {
  const _Orbit({
    required this.radius,
    required this.period,
    required this.phase,
    required this.dotScale,
    required this.strokeAlpha,
    required this.trailAlpha,
    required this.color,
  });

  final double radius;
  final double period;
  final double phase;
  final double dotScale;
  final double strokeAlpha;
  final double trailAlpha;
  final Color color;
}

class _OrbisPainter extends CustomPainter {
  _OrbisPainter({required this.seconds});

  final double seconds;

  static const _orbits = <_Orbit>[
    _Orbit(
      radius: 0.47,
      period: 7.0,
      phase: 0.0,
      dotScale: 1.0,
      strokeAlpha: 1.0,
      trailAlpha: 0.60,
      color: AppColors.accent,
    ),
    _Orbit(
      radius: 0.29,
      period: -4.6,
      phase: 0.35,
      dotScale: 0.62,
      strokeAlpha: 0.70,
      trailAlpha: 0.38,
      color: AppColors.accentHover,
    ),
    _Orbit(
      radius: 0.11,
      period: 3.0,
      phase: 0.7,
      dotScale: 0.42,
      strokeAlpha: 0.45,
      trailAlpha: 0.26,
      color: AppColors.accentHover,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width;
    final stroke = math.max(1.0, unit * 0.013);

    for (final orbit in _orbits) {
      final radius = unit * orbit.radius;
      final dotRadius = unit * 0.052 * orbit.dotScale;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = const Color(0xFF3A434C)
              .withValues(alpha: orbit.strokeAlpha),
      );

      final turns = seconds / orbit.period + orbit.phase;
      final angle = turns * 2 * math.pi - math.pi / 2;

      final rect = Rect.fromCircle(center: center, radius: radius);
      const segments = 20;
      const trailSweep = math.pi * 0.9;
      const step = trailSweep / segments;
      final direction = orbit.period.isNegative ? -1.0 : 1.0;

      for (var i = 0; i < segments; i++) {
        final t = i / segments;
        canvas.drawArc(
          rect,
          angle - direction * step * (i + 1),
          direction * step * 1.08,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = orbit.color
                .withValues(alpha: (1 - t) * (1 - t) * orbit.trailAlpha),
        );
      }

      final dotCenter =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);

      canvas.drawCircle(
        dotCenter,
        dotRadius * 2.2,
        Paint()
          ..color = orbit.color.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.045),
      );
      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()..color = orbit.color,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbisPainter oldDelegate) {
    return oldDelegate.seconds != seconds;
  }
}