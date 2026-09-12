import 'package:flutter/material.dart';

import '../data/nav_items.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';

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
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _Placeholder(key: ValueKey(item.id), item: item),
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