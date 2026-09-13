import 'package:flutter/material.dart';

import '../data/nav_items.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import 'variable_expenses_screen.dart';
import 'month_summary_screen.dart';
import 'year_summary_screen.dart';
import 'fixed_costs_screen.dart';
import 'habits_screen.dart';
import 'routine_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  String _selectedId = 'variaveis';
  



  @override
  Widget build(BuildContext context) {
    final item = navItems.firstWhere((i) => i.id == _selectedId);

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedId: _selectedId,
            onSelect: (id) => setState(() => _selectedId = id),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              layoutBuilder: (currentChild, previousChildren) {
                return currentChild ?? const SizedBox.shrink();
              },
              child: switch (item.id) {
                'variaveis' => const VariableExpensesScreen(
                    key: ValueKey('variaveis'),
                  ),
                'resumo-mes' => const MonthSummaryScreen(
                    key: ValueKey('resumo-mes'),
                  ),
                'resumo-ano' => const YearSummaryScreen(
                    key: ValueKey('resumo-ano'),
                  ),
                'fixos' => const FixedCostsScreen(
                    key: ValueKey('fixos'),
                  ),
                'habitos' => const HabitsScreen(
                    key: ValueKey('habitos'),
                  ),
                'rotina' => const RoutineScreen(
                    key: ValueKey('rotina'),
                  ),
                _ => _Placeholder(key: ValueKey(item.id), item: item),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key, required this.item});

  final NavItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 30, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(item.label, style: AppText.serif(size: 26)),
          const SizedBox(height: 6),
          const Text(
            'Em construção',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}