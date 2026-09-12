import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/orbis_mark.dart';

enum _Mode { signIn, signUp, reset }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  _Mode _mode = _Mode.signIn;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _setMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _info = null;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Informe o e-mail');
      return;
    }
    if (_mode != _Mode.reset && password.isEmpty) {
      setState(() => _error = 'Informe a senha');
      return;
    }
    if (_mode == _Mode.signUp && name.isEmpty) {
      setState(() => _error = 'Informe o seu nome');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      switch (_mode) {
        case _Mode.signIn:
          await AuthService.signIn(email: email, password: password);
        case _Mode.signUp:
          await AuthService.signUp(
            email: email,
            password: password,
            displayName: name,
          );
        case _Mode.reset:
          await AuthService.sendPasswordReset(email);
          if (mounted) {
            setState(() => _info = 'Link de recuperação enviado para o e-mail');
          }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AuthService.messageForError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Animation<double> _fade(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _reveal({
    required double start,
    required double end,
    required Widget child,
  }) {
    final animation = _fade(start, end);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 14),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _Mode.signUp;
    final isReset = _mode == _Mode.reset;
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < 780;

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          Align(
            alignment: const Alignment(0, -0.35),
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reveal(
                    start: 0.0,
                    end: 0.45,
                    child: OrbisMark(size: compact ? 104 : 132),
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  _reveal(
                    start: 0.15,
                    end: 0.6,
                    child: Column(
                      children: [
                        Text(
                          'Orbis',
                          style: AppText.serif(size: compact ? 32 : 40),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Todo o seu planejamento em um só lugar',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 36),
                  _reveal(
                    start: 0.3,
                    end: 0.85,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        32,
                        compact ? 22 : 30,
                        32,
                        compact ? 20 : 26,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: AppColors.border,
                          width: AppBorders.normal,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            switch (_mode) {
                              _Mode.signIn => 'Entrar',
                              _Mode.signUp => 'Criar conta',
                              _Mode.reset => 'Recuperar senha',
                            },
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 22),
                          if (isSignUp) ...[
                            _Field(
                              label: 'Nome',
                              controller: _nameController,
                              focusNode: _nameFocus,
                              hint: 'Como quer ser chamado',
                              onSubmitted: () => _emailFocus.requestFocus(),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                          ],
                          _Field(
                            label: 'E-mail',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            hint: 'voce@exemplo.com',
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted: () {
                              if (isReset) {
                                _submit();
                              } else {
                                _passwordFocus.requestFocus();
                              }
                            },
                          ),
                          if (!isReset) ...[
                            SizedBox(height: compact ? 12 : 16),
                            _Field(
                              label: 'Senha',
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hint: '••••••••',
                              obscure: _obscure,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                splashRadius: 18,
                              ),
                              onSubmitted: _submit,
                            ),
                          ],
                          if (_error != null) ...[
                            SizedBox(height: compact ? 12 : 16),
                            _Banner(
                              message: _error!,
                              color: AppColors.expense,
                              icon: Icons.error_outline,
                            ),
                          ],
                          if (_info != null) ...[
                            SizedBox(height: compact ? 12 : 16),
                            _Banner(
                              message: _info!,
                              color: AppColors.income,
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                          SizedBox(height: compact ? 20 : 24),
                          _SubmitButton(
                            loading: _loading,
                            label: switch (_mode) {
                              _Mode.signIn => 'Entrar',
                              _Mode.signUp => 'Criar conta',
                              _Mode.reset => 'Enviar link',
                            },
                            onPressed: _submit,
                          ),
                          SizedBox(height: compact ? 14 : 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_mode == _Mode.signIn) ...[
                                _LinkButton(
                                  label: 'Criar conta',
                                  onPressed: () => _setMode(_Mode.signUp),
                                ),
                                const _Separator(),
                                _LinkButton(
                                  label: 'Esqueci a senha',
                                  onPressed: () => _setMode(_Mode.reset),
                                ),
                              ] else
                                _LinkButton(
                                  label: 'Voltar para o login',
                                  onPressed: () => _setMode(_Mode.signIn),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.1,
            colors: [AppColors.accentSoft, AppColors.bg],
            stops: [0.0, 0.62],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmitted,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onSubmitted;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: (_) => onSubmitted(),
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.bg,
            suffixIcon: suffix,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
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

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
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
          duration: const Duration(milliseconds: 160),
          height: 46,
          decoration: BoxDecoration(
            color: _hover ? AppColors.accentHover : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.28),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onAccent,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatefulWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12.5,
            color: _hover ? AppColors.accentHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: AppBorders.normal,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}