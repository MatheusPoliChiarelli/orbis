import 'package:flutter/material.dart';

import '../data/nav_items.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'orbis_mark.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?.displayName?.trim();
    final label = (name != null && name.isNotEmpty) ? name : (user?.email ?? '');

    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: AppBorders.normal,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Row(
              children: [
                const OrbisMark(size: 30),
                const SizedBox(width: 11),
                Text('Orbis', style: AppText.serif(size: 22)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final section in sectionOrder) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                    child: Text(
                      sectionLabels[section]!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  for (final item
                      in navItems.where((i) => i.section == section))
                    _NavTile(
                      item: item,
                      selected: item.id == selectedId,
                      onTap: () => onSelect(item.id),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: AppBorders.normal),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: AppColors.borderAccent,
                      width: AppBorders.normal,
                    ),
                  ),
                  child: Text(
                    label.isNotEmpty ? label[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: AuthService.signOut,
                  icon: const Icon(
                    Icons.logout,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Sair',
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected
        ? AppColors.accent
        : (_hover ? AppColors.textPrimary : AppColors.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentSoft
                : (_hover ? AppColors.surfaceRaised : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected ? AppColors.borderAccent : Colors.transparent,
              width: AppBorders.normal,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 17, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}