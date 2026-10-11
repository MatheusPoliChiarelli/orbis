import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CalculatorPanel extends StatefulWidget {
  const CalculatorPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<CalculatorPanel> createState() => _CalculatorPanelState();
}

class _CalculatorPanelState extends State<CalculatorPanel> {
  final FocusNode _focus = FocusNode();

  String _current = '0';
  double? _accumulator;
  String? _operation;
  bool _replaceOnNextDigit = true;
  String _history = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_current.replaceAll(',', '.')) ?? 0;

  String _format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }

  void _pushDigit(String digit) {
    setState(() {
      if (_replaceOnNextDigit) {
        _current = digit;
        _replaceOnNextDigit = false;
      } else {
        if (_current == '0' && digit != ',') {
          _current = digit;
        } else {
          _current += digit;
        }
      }
    });
  }

  void _pushComma() {
    if (_current.contains(',')) return;
    setState(() {
      if (_replaceOnNextDigit) {
        _current = '0,';
        _replaceOnNextDigit = false;
      } else {
        _current += ',';
      }
    });
  }

  void _setOperation(String operation) {
    setState(() {
      if (_accumulator != null && _operation != null && !_replaceOnNextDigit) {
        final result = _apply(_accumulator!, _value, _operation!);
        _accumulator = result;
        _current = _format(result);
      } else {
        _accumulator = _value;
      }
      _operation = operation;
      _replaceOnNextDigit = true;
      _history = '${_format(_accumulator!)} $operation';
    });
  }

  void _equals() {
    if (_accumulator == null || _operation == null) return;
    setState(() {
      final result = _apply(_accumulator!, _value, _operation!);
      _history = '${_format(_accumulator!)} $_operation ${_format(_value)} =';
      _current = _format(result);
      _accumulator = null;
      _operation = null;
      _replaceOnNextDigit = true;
    });
  }

  double _apply(double a, double b, String operation) {
    return switch (operation) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? 0 : a / b,
      _ => b,
    };
  }

  void _clear() {
    setState(() {
      _current = '0';
      _accumulator = null;
      _operation = null;
      _replaceOnNextDigit = true;
      _history = '';
    });
  }

  void _backspace() {
    setState(() {
      if (_replaceOnNextDigit || _current.length <= 1) {
        _current = '0';
        _replaceOnNextDigit = true;
      } else {
        _current = _current.substring(0, _current.length - 1);
      }
    });
  }

  void _negate() {
    setState(() {
      if (_current.startsWith('-')) {
        _current = _current.substring(1);
      } else if (_current != '0') {
        _current = '-$_current';
      }
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: formatMoneyPlain(_value)),
    );
    if (mounted) widget.onClose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.equal) {
      _equals();
      return;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }
    if (key == LogicalKeyboardKey.delete) {
      _clear();
      return;
    }
    if (key == LogicalKeyboardKey.comma || key == LogicalKeyboardKey.period) {
      _pushComma();
      return;
    }

    final digits = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    final digit = digits[key];
    if (digit != null) {
      _pushDigit(digit);
      return;
    }

    final operations = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.add: '+',
      LogicalKeyboardKey.numpadAdd: '+',
      LogicalKeyboardKey.minus: '−',
      LogicalKeyboardKey.numpadSubtract: '−',
      LogicalKeyboardKey.asterisk: '×',
      LogicalKeyboardKey.numpadMultiply: '×',
      LogicalKeyboardKey.slash: '÷',
      LogicalKeyboardKey.numpadDivide: '÷',
    };

    final operation = operations[key];
    if (operation != null) _setOperation(operation);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focus,
      onKeyEvent: _handleKey,
      child: Container(
        width: 286,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.borderAccent,
            width: AppBorders.selected,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calculate_outlined,
                  size: 15,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Calculadora',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(
                      Icons.close,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: AppColors.border,
                  width: AppBorders.normal,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 14,
                    child: Text(
                      _history,
                      style: AppText.money(
                        size: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _current,
                      style: AppText.money(
                        size: 28,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Row(children: [
              _Key(label: 'C', onTap: _clear, muted: true),
              _Key(label: '±', onTap: _negate, muted: true),
              _Key(label: '⌫', onTap: _backspace, muted: true),
              _Key(label: '÷', onTap: () => _setOperation('÷'), accent: true),
            ]),
            _Row(children: [
              _Key(label: '7', onTap: () => _pushDigit('7')),
              _Key(label: '8', onTap: () => _pushDigit('8')),
              _Key(label: '9', onTap: () => _pushDigit('9')),
              _Key(label: '×', onTap: () => _setOperation('×'), accent: true),
            ]),
            _Row(children: [
              _Key(label: '4', onTap: () => _pushDigit('4')),
              _Key(label: '5', onTap: () => _pushDigit('5')),
              _Key(label: '6', onTap: () => _pushDigit('6')),
              _Key(label: '−', onTap: () => _setOperation('−'), accent: true),
            ]),
            _Row(children: [
              _Key(label: '1', onTap: () => _pushDigit('1')),
              _Key(label: '2', onTap: () => _pushDigit('2')),
              _Key(label: '3', onTap: () => _pushDigit('3')),
              _Key(label: '+', onTap: () => _setOperation('+'), accent: true),
            ]),
            _Row(children: [
              _Key(label: '0', onTap: () => _pushDigit('0'), wide: true),
              _Key(label: ',', onTap: _pushComma),
              _Key(label: '=', onTap: _equals, filled: true),
            ]),
            const SizedBox(height: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _copy,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppBorders.normal,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_copy_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Copiar resultado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: children),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.accent = false,
    this.filled = false,
    this.muted = false,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;
  final bool filled;
  final bool muted;
  final bool wide;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.filled
        ? AppColors.accent
        : (_hover ? AppColors.surfaceRaised : AppColors.bg);

    final foreground = widget.filled
        ? AppColors.onAccent
        : (widget.accent
            ? AppColors.accent
            : (widget.muted
                ? AppColors.textMuted
                : AppColors.textPrimary));

    return Expanded(
      flex: widget.wide ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.only(right: 7),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: widget.filled ? AppColors.accent : AppColors.border,
                  width: AppBorders.normal,
                ),
              ),
              child: Text(
                widget.label,
                style: AppText.money(
                  size: 15,
                  weight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}