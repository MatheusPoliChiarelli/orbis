import 'package:flutter/material.dart';

class AccountInfo {
  const AccountInfo({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

const kGeneralAccountId = 'geral';

const accounts = <AccountInfo>[
  AccountInfo(
    id: kGeneralAccountId,
    name: 'Geral',
    color: Color(0xFF4DA3FF),
  ),
  AccountInfo(
    id: 'nubank',
    name: 'Nubank',
    color: Color(0xFF8A05BE),
  ),
  AccountInfo(
    id: 'bradesco',
    name: 'Bradesco',
    color: Color(0xFFCC092F),
  ),
];

const realAccountIds = <String>['nubank', 'bradesco'];

AccountInfo accountById(String id) {
  return accounts.firstWhere(
    (a) => a.id == id,
    orElse: () => accounts.first,
  );
}