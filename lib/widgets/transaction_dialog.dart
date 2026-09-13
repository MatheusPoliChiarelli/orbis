import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/accounts.dart';
import '../data/categories.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'bank_logo.dart';

enum TxStep { category, amount, description, toAccount }

const _gridColumns = 3;

Future<void> showTransactionDialog({
  required BuildContext context,
  required DateTime date,
  required String accountId,
  required TxType type,
  Tx? existing,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => TransactionDialog(
      date: date,
      accountId: accountId,
      type: type,
      existing: existing,
    ),
  );
}

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({
    super.key,
    required this.date,
    required this.accountId,
    required this.type,
    this.existing,
  });

  final DateTime date;
  final String accountId;
  final TxType type;
  final Tx? existing;

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final FocusNode _keyboardFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late TxType _type;
  late String _accountId;
  String? _toAccountId;
  CategoryInfo? _category;

  TxStep _step = TxStep.category;
  int _listIndex = 0;
  bool _saving = false;

  List<CategoryInfo> get _categories =>
      _type == TxType.income ? incomeCategories : expenseCategories;

  List<TxStep> get _stepFlow {
    if (_type == TxType.transfer) {
      return const [TxStep.toAccount, TxStep.amount, TxStep.description];
    }
    return const [TxStep.category, TxStep.amount, TxStep.description];
  }

  List<String> get _transferTargets =>
      realAccountIds.where((id) => id != _accountId).toList();

  int get _currentListLength {
    return switch (_step) {
      TxStep.category => _categories.length,
      TxStep.toAccount => _transferTargets.length,
      TxStep.amount => 0,
      TxStep.description => 0,
    };
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _type = existing?.type ?? widget.type;
    _accountId = existing?.accountId ?? widget.accountId;
    _toAccountId = existing?.toAccountId;

    if (existing != null) {
      _category = categoryById(existing.categoryId);
      _amountController.text = formatMoneyPlain(existing.amount);
      _descriptionController.text = existing.description;
      _listIndex = _categories.indexWhere((c) => c.id == existing.categoryId);
      if (_listIndex < 0) _listIndex = 0;
    } else if (_type != TxType.transfer) {
      _category = _categories.first;
      _listIndex = 0;
    }

    _step = _stepFlow.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _amountFocus.dispose();
    _descriptionFocus.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyListIndex(int index) {
    final length = _currentListLength;
    if (length == 0) return;
    final clamped = index.clamp(0, length - 1);

    setState(() {
      _listIndex = clamped;
      switch (_step) {
        case TxStep.category:
          _category = _categories[clamped];
        case TxStep.toAccount:
          _toAccountId = _transferTargets[clamped];
        case TxStep.amount:
        case TxStep.description:
          break;
      }
    });
  }

  void _goToStep(TxStep step) {
    setState(() {
      _step = step;
      _listIndex = switch (step) {
        TxStep.category => _category == null
            ? 0
            : _categories.indexWhere((c) => c.id == _category!.id).clamp(0, 999),
        TxStep.toAccount => _toAccountId == null
            ? 0
            : _transferTargets.indexOf(_toAccountId!).clamp(0, 999),
        TxStep.amount => 0,
        TxStep.description => 0,
      };
    });

    if (step == TxStep.amount) {
      _amountFocus.requestFocus();
      _amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountController.text.length,
      );
    } else if (step == TxStep.description) {
      _descriptionFocus.requestFocus();
      _descriptionController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _descriptionController.text.length,
      );
    } else {
      _keyboardFocus.requestFocus();
    }
  }

  void _nextStep() {
    final flow = _stepFlow;
    final index = flow.indexOf(_step);

    if (_step == TxStep.category && _category == null) {
      _category = _categories[_listIndex];
    }
    if (_step == TxStep.toAccount && _toAccountId == null) {
      _toAccountId = _transferTargets[_listIndex];
    }

    if (index >= flow.length - 1) {
      _save();
      return;
    }
    _goToStep(flow[index + 1]);
  }

  void _previousStep() {
    final flow = _stepFlow;
    final index = flow.indexOf(_step);
    if (index <= 0) return;
    _goToStep(flow[index - 1]);
  }

  Future<void> _save() async {
    if (_saving) return;

    final amount = parseMoney(_amountController.text);
    if (amount <= 0) {
      _goToStep(TxStep.amount);
      return;
    }
    if (_type == TxType.transfer && _toAccountId == null) {
      _goToStep(TxStep.toAccount);
      return;
    }
    if (_type != TxType.transfer && _category == null) {
      _goToStep(TxStep.category);
      return;
    }

    setState(() => _saving = true);

    final category = _category;
    final tx = Tx(
      id: widget.existing?.id ?? '',
      amount: amount,
      type: _type,
      date: widget.date,
      description: _descriptionController.text.trim(),
      categoryId: category?.id ?? 'transferencia',
      categoryName: category?.name ?? 'Transferência',
      categoryColor: category?.color ?? AppColors.textSecondary,
      accountId: _accountId,
      toAccountId: _type == TxType.transfer ? _toAccountId : null,
      createdAt: widget.existing?.createdAt,
    );

    try {
      if (widget.existing == null) {
        await FinanceService.addTransaction(tx);
      } else {
        await FinanceService.updateTransaction(tx);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_step == TxStep.amount || _step == TxStep.description) return;
      _nextStep();
      return;
    }

    if (key == LogicalKeyboardKey.tab) {
      _previousStep();
      return;
    }

    if (_currentListLength == 0) return;

    if (key == LogicalKeyboardKey.arrowRight) {
      _applyListIndex(_listIndex + 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _applyListIndex(_listIndex - 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _applyListIndex(
        _step == TxStep.category ? _listIndex + _gridColumns : _listIndex + 1,
      );
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _applyListIndex(
        _step == TxStep.category ? _listIndex - _gridColumns : _listIndex - 1,
      );
    }
  }

  String get _title {
    if (widget.existing != null) return 'Editar lançamento';
    return switch (_type) {
      TxType.income => 'Nova entrada',
      TxType.expense => 'Nova saída',
      TxType.transfer => 'Nova transferência',
    };
  }

  Color get _accentForType {
    return switch (_type) {
      TxType.income => AppColors.income,
      TxType.expense => AppColors.expense,
      TxType.transfer => AppColors.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: _handleKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: Container(
          width: 520,
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.border,
              width: AppBorders.normal,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _accentForType,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.date.day} de ${monthLabel(widget.date).toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AccountPill(accountId: _accountId),
                ],
              ),
              const SizedBox(height: 18),
              if (_type != TxType.transfer) ...[
                _StepLabel(
                  label: 'Categoria',
                  active: _step == TxStep.category,
                  hint: 'setas navegam, enter avança',
                ),
                const SizedBox(height: 10),
                _CategoryGrid(
                  categories: _categories,
                  selected: _category,
                  onSelect: (index) {
                    setState(() => _step = TxStep.category);
                    _applyListIndex(index);
                    _keyboardFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 18),
              ] else ...[
                _StepLabel(
                  label: 'Conta de destino',
                  active: _step == TxStep.toAccount,
                  hint: 'setas navegam, enter avança',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < _transferTargets.length; i++) ...[
                      _TargetChip(
                        accountId: _transferTargets[i],
                        selected: _toAccountId == _transferTargets[i],
                        onTap: () {
                          setState(() => _step = TxStep.toAccount);
                          _applyListIndex(i);
                          _keyboardFocus.requestFocus();
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
              ],
              _StepLabel(
                label: 'Valor',
                active: _step == TxStep.amount,
                hint: 'enter avança',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                inputFormatters: [CurrencyInputFormatter()],
                onTap: () => setState(() => _step = TxStep.amount),
                onSubmitted: (_) => _nextStep(),
                style: AppText.money(
                  size: 22,
                  weight: FontWeight.w600,
                  color: _accentForType,
                ),
                decoration: _fieldDecoration(
                  prefix: 'R\$ ',
                  hint: '0,00',
                  active: _step == TxStep.amount,
                ),
              ),
              const SizedBox(height: 18),
              _StepLabel(
                label: 'Descrição',
                active: _step == TxStep.description,
                hint: 'enter salva',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                onTap: () => setState(() => _step = TxStep.description),
                onSubmitted: (_) => _nextStep(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: _fieldDecoration(
                  hint: 'Opcional',
                  active: _step == TxStep.description,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'esc fecha  ·  tab volta uma etapa',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SaveButton(
                    loading: _saving,
                    color: _accentForType,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required bool active,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: prefix == null ? 14 : 20,
        color: AppColors.textMuted,
      ),
      prefixIcon: prefix == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  prefix.trim(),
                  style: AppText.money(size: 16, color: AppColors.textMuted),
                ),
              ),
            ),
      filled: true,
      fillColor: AppColors.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: AppBorders.normal,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(
          color: active ? AppColors.accent : AppColors.border,
          width: active ? AppBorders.selected : AppBorders.normal,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: AppBorders.selected,
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.label,
    required this.active,
    required this.hint,
  });

  final String label;
  final bool active;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppColors.accent : AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 9),
          Text(
            hint,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<CategoryInfo> categories;
  final CategoryInfo? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (_gridColumns - 1)) / _gridColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < categories.length; i++)
              SizedBox(
                width: width,
                child: _CategoryTile(
                  category: categories[i],
                  selected: selected?.id == categories[i].id,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryInfo category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? category.color.withValues(alpha: 0.13)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: selected
                  ? category.color.withValues(alpha: 0.65)
                  : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 15,
                color: selected ? category.color : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.accountId,
    required this.selected,
    required this.onTap,
  });

  final String accountId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final account = accountById(accountId);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.fromLTRB(7, 6, 16, 6),
          decoration: BoxDecoration(
            color: selected
                ? account.color.withValues(alpha: 0.14)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected
                  ? account.color.withValues(alpha: 0.60)
                  : AppColors.border,
              width: selected ? AppBorders.selected : AppBorders.normal,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BankLogo(accountId: accountId, size: 22),
              const SizedBox(width: 9),
              Text(
                account.name,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPill extends StatelessWidget {
  const _AccountPill({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = accountById(accountId);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: account.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: account.color.withValues(alpha: 0.40),
          width: AppBorders.normal,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BankLogo(accountId: accountId, size: 16),
          const SizedBox(width: 7),
          Text(
            account.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: account.color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.loading,
    required this.color,
    required this.onPressed,
  });

  final bool loading;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hover ? 1 : 0.9),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.26),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : const Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onAccent,
                  ),
                ),
        ),
      ),
    );
  }
}