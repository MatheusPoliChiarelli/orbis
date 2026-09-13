import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => const ChangePasswordDialog(),
  );
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _error = 'Informe a senha atual');
      _currentFocus.requestFocus();
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'A nova senha precisa ter pelo menos 6 caracteres');
      _newFocus.requestFocus();
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'A confirmação não confere');
      _confirmFocus.requestFocus();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AuthService.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AuthService.messageForError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Container(
        width: 420,
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
            const Text(
              'Alterar senha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _Field(
              label: 'Senha atual',
              controller: _currentController,
              focusNode: _currentFocus,
              onSubmitted: () => _newFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Nova senha',
              controller: _newController,
              focusNode: _newFocus,
              onSubmitted: () => _confirmFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Confirme a nova senha',
              controller: _confirmController,
              focusNode: _confirmFocus,
              onSubmitted: _save,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(
                    color: AppColors.expense.withValues(alpha: 0.35),
                    width: AppBorders.normal,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 15,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                _SaveButton(loading: _saving, onPressed: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          onSubmitted: (_) => widget.onSubmitted(),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              splashRadius: 18,
            ),
            filled: true,
            fillColor: AppColors.bg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: AppBorders.normal,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: AppBorders.normal,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: AppBorders.selected,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.loading, required this.onPressed});

  final bool loading;
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
            color: _hover ? AppColors.accentHover : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
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