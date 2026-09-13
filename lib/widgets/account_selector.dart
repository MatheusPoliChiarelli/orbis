import 'package:flutter/material.dart';

import '../data/accounts.dart';
import '../theme/app_theme.dart';
import 'bank_logo.dart';

class AccountSelector extends StatelessWidget {
  const AccountSelector({
    super.key,
    required this.selectedId,
    required this.onSelect,
    required this.balances,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;
  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final account in accounts) ...[
          _AccountChip(
            account: account,
            selected: account.id == selectedId,
            onTap: () => onSelect(account.id),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _AccountChip extends StatefulWidget {
  const _AccountChip({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final AccountInfo account;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccountChip> createState() => _AccountChipState();
}

class _AccountChipState extends State<_AccountChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final brand = widget.account.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(9, 7, 18, 7),
          decoration: BoxDecoration(
            color: selected
                ? brand.withValues(alpha: 0.14)
                : (_hover ? AppColors.surfaceRaised : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected
                  ? brand.withValues(alpha: 0.55)
                  : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: brand.withValues(alpha: 0.22),
                      blurRadius: 22,
                      spreadRadius: -6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankLogo(accountId: widget.account.id, size: 30),
              const SizedBox(width: 11),
              Text(
                widget.account.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}