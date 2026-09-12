import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'orbis_mark.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const _TempHome();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: OrbisMark(size: 96)),
    );
  }
}

class _TempHome extends StatelessWidget {
  const _TempHome();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OrbisMark(size: 96),
            const SizedBox(height: 24),
            Text(
              'Olá, ${user?.displayName ?? user?.email ?? ''}',
              style: AppText.serif(size: 30),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: AuthService.signOut,
              child: const Text(
                'Sair',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}