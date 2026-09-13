import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../theme/app_theme.dart';

class BankLogo extends StatelessWidget {
  const BankLogo({
    super.key,
    required this.accountId,
    this.size = 30,
  });

  final String accountId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final account = accountById(accountId);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: account.hasLogo ? Colors.transparent : account.color,
        shape: BoxShape.circle,
      ),
      child: account.hasLogo
          ? Image.asset(
              account.logo!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Icon(
                Icons.account_balance,
                size: size * 0.5,
                color: AppColors.textMuted,
              ),
            )
          : Text(
              'R\$',
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: account.onColor,
              ),
            ),
    );
  }
}