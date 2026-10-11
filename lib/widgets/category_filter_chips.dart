import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ExpenseFilter { all, fixed, variable }

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ExpenseFilter selected;
  final ValueChanged<ExpenseFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final filter in ExpenseFilter.values) ...[
          _Chip(
            label: switch (filter) {
              ExpenseFilter.all => 'Todas',
              ExpenseFilter.fixed => 'Fixas',
              ExpenseFilter.variable => 'Variáveis',
            },
            selected: selected == filter,
            onTap: () => onSelect(filter),
          ),
          if (filter != ExpenseFilter.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.borderAccent : AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}