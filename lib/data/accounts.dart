import 'package:flutter/material.dart';

class AccountInfo {
  const AccountInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.onColor,
    this.logo,
  });

  final String id;
  final String name;
  final Color color;

  /// Cor do conteúdo desenhado sobre a cor da marca.
  final Color onColor;

  /// Caminho do PNG. Nulo no Geral, que usa o cifrão.
  final String? logo;

  bool get hasLogo => logo != null;
}

const kGeneralAccountId = 'geral';

const accounts = <AccountInfo>[
  AccountInfo(
    id: kGeneralAccountId,
    name: 'Geral',
    color: Color(0xFF4DA3FF),
    onColor: Color(0xFF08121F),
  ),
  AccountInfo(
    id: 'nubank',
    name: 'Nubank',
    color: Color(0xFF8A05BE),
    onColor: Color(0xFFFFFFFF),
    logo: 'assets/banks/nubank.png',
  ),
  AccountInfo(
    id: 'bradesco',
    name: 'Bradesco',
    color: Color(0xFFCC092F),
    onColor: Color(0xFFFFFFFF),
    logo: 'assets/banks/bradesco.png',
  ),
];

const realAccountIds = <String>['nubank', 'bradesco'];

AccountInfo accountById(String id) {
  return accounts.firstWhere(
    (a) => a.id == id,
    orElse: () => accounts.first,
  );
}