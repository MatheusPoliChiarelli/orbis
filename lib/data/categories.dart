import 'package:flutter/material.dart';

class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.isIncome,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final bool isIncome;
}

const expenseCategories = <CategoryInfo>[
  CategoryInfo(
    id: 'alimentacao',
    name: 'Alimentação',
    color: Color(0xFFE0785F),
    icon: Icons.restaurant_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'mercado',
    name: 'Mercado',
    color: Color(0xFFE8A15F),
    icon: Icons.shopping_cart_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'transporte',
    name: 'Transporte',
    color: Color(0xFF7CC5FF),
    icon: Icons.directions_car_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'moradia',
    name: 'Moradia',
    color: Color(0xFF9B8CFF),
    icon: Icons.home_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'saude',
    name: 'Saúde',
    color: Color(0xFF5FD4A0),
    icon: Icons.favorite_outline,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'educacao',
    name: 'Educação',
    color: Color(0xFF4DA3FF),
    icon: Icons.school_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'lazer',
    name: 'Lazer',
    color: Color(0xFFE85FA0),
    icon: Icons.sports_esports_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'assinaturas',
    name: 'Assinaturas',
    color: Color(0xFF5FC9D4),
    icon: Icons.subscriptions_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'academia',
    name: 'Academia',
    color: Color(0xFF8FD45F),
    icon: Icons.fitness_center_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'vestuario',
    name: 'Vestuário',
    color: Color(0xFFD45F8F),
    icon: Icons.checkroom_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'presentes',
    name: 'Presentes',
    color: Color(0xFFFFB35F),
    icon: Icons.card_giftcard_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'investimentos',
    name: 'Investimentos',
    color: Color(0xFF6BD4C4),
    icon: Icons.trending_up_outlined,
    isIncome: false,
  ),
  CategoryInfo(
    id: 'outros',
    name: 'Outros',
    color: Color(0xFF9AA1A8),
    icon: Icons.more_horiz_outlined,
    isIncome: false,
  ),
];

const incomeCategories = <CategoryInfo>[
  CategoryInfo(
    id: 'salario',
    name: 'Salário',
    color: Color(0xFF5FD4A0),
    icon: Icons.payments_outlined,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'freelance',
    name: 'Freelance',
    color: Color(0xFF6BD4C4),
    icon: Icons.work_outline,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'empresas',
    name: 'Empresas',
    color: Color(0xFF8FD45F),
    icon: Icons.storefront_outlined,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'rendimentos',
    name: 'Rendimentos',
    color: Color(0xFF4DA3FF),
    icon: Icons.savings_outlined,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'bolsa',
    name: 'Bolsa',
    color: Color(0xFF9B8CFF),
    icon: Icons.school_outlined,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'reembolso',
    name: 'Reembolso',
    color: Color(0xFF5FC9D4),
    icon: Icons.undo_outlined,
    isIncome: true,
  ),
  CategoryInfo(
    id: 'outras-entradas',
    name: 'Outras entradas',
    color: Color(0xFF9AA1A8),
    icon: Icons.more_horiz_outlined,
    isIncome: true,
  ),
];

const allCategories = <CategoryInfo>[
  ...expenseCategories,
  ...incomeCategories,
];

CategoryInfo? categoryById(String id) {
  for (final category in allCategories) {
    if (category.id == id) return category;
  }
  return null;
}