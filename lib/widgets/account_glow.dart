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
          children: [
            Positioned.fill(child: inner!),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: base.withValues(alpha: 0.55 * intensity),
                      width: AppBorders.selected,
                    ),
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