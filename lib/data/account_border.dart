import 'package:flutter/material.dart';

import 'accounts.dart';

/// Cor da borda dos cards conforme a conta selecionada.
/// Nulo no Geral, que mantém a borda neutra.
Color? accountBorder(String accountId) {
  if (accountId == kGeneralAccountId) return null;
  return accountById(accountId).color.withValues(alpha: 0.55);
}