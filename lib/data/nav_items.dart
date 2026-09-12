import 'package:flutter/material.dart';

enum NavSection { rotina, habitos, financas }

class NavItem {
  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.section,
  });

  final String id;
  final String label;
  final IconData icon;
  final NavSection section;
}

const navItems = <NavItem>[
  NavItem(
    id: 'variaveis',
    label: 'Gastos variáveis',
    icon: Icons.receipt_long_outlined,
    section: NavSection.financas,
  ),
  NavItem(
    id: 'resumo-mes',
    label: 'Resumo do mês',
    icon: Icons.donut_small_outlined,
    section: NavSection.financas,
  ),
  NavItem(
    id: 'resumo-ano',
    label: 'Resumo do ano',
    icon: Icons.calendar_view_month_outlined,
    section: NavSection.financas,
  ),
  NavItem(
    id: 'fixos',
    label: 'Gastos fixos',
    icon: Icons.push_pin_outlined,
    section: NavSection.financas,
  ),
  NavItem(
    id: 'habitos',
    label: 'Hábitos',
    icon: Icons.grid_on_outlined,
    section: NavSection.habitos,
  ),
  NavItem(
    id: 'rotina',
    label: 'Rotina',
    icon: Icons.schedule_outlined,
    section: NavSection.rotina,
  ),
];

const sectionLabels = <NavSection, String>{
  NavSection.financas: 'Finanças',
  NavSection.habitos: 'Hábitos',
  NavSection.rotina: 'Rotina',
};

const sectionOrder = <NavSection>[
  NavSection.financas,
  NavSection.habitos,
  NavSection.rotina,
];