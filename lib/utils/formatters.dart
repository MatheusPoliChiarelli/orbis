import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _compact = NumberFormat.currency(locale: 'pt_BR', symbol: '');

String formatMoney(double value) => _currency.format(value);

String formatMoneyPlain(double value) => _compact.format(value).trim();

String formatSigned(double value) {
  final sign = value > 0 ? '+' : (value < 0 ? '-' : '');
  return '$sign${_currency.format(value.abs())}';
}

String monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String dayKey(DateTime date) {
  return '${monthKey(date)}-${date.day.toString().padLeft(2, '0')}';
}

const monthNames = <String>[
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const weekdayShort = <String>[
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom',
];

String monthLabel(DateTime date) => monthNames[date.month - 1];

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = int.parse(digits) / 100;
    final text = formatMoneyPlain(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

double parseMoney(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits) / 100;
}