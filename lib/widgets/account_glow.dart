import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../theme/app_theme.dart';

class AccountGlow extends StatelessWidget {
  const AccountGlow({
    super.key,
    required this.accountId,
    required this.child,
  });

  final String accountId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isGeneral = accountId == kGeneralAccountId;
    final brand = accountById(accountId).color;
    final target = isGeneral ? brand.withValues(alpha: 0) : brand;

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      tween: ColorTween(end: target),
      builder: (context, animated, inner) {
        final color = animated ?? Colors.transparent;
        final intensity = color.a;
        final base = color.withValues(alpha: 1);

        return Stack(
          fit: StackFit.expand,
          children: [
            inner!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BorderPainter(
                    color: base.withValues(alpha: 0.55 * intensity),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}