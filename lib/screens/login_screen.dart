import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/campus_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../widgets/campus_themed.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import '../widgets/inti_logo.dart';
import '../widgets/login_form.dart';

/// Stand-alone login page (also shown when a protected page needs login).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const CampusThemed(child: _LoginPage());
}

class _LoginPage extends StatelessWidget {
  const _LoginPage();

  @override
  Widget build(BuildContext context) {
    final api = AppState.instance.api;
    final palette = CampusPalette.of(context);
    final link = palette.isDark ? Colors.white : AppColors.primary;
    return GlassPage(
      title: 'Log in',
      actions: const [ThemeToggleButton(), SizedBox(width: 12)],
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                const Center(child: IntiLogo(height: 56)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppText.h1.copyWith(color: palette.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in with your student account to open your campus dashboard.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  colors: palette.isDark ? null : palette.glassStrong,
                  borderColor: palette.isDark ? null : palette.glassBorder,
                  tint: 0.16,
                  child: const LoginForm(),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('New to Crimson Campus?', style: AppText.body.copyWith(color: palette.textMuted)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                      style: TextButton.styleFrom(
                        foregroundColor: link,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                if (api is HttpCampusApi)
                  Text(
                    'Server: ${api.baseUrl}',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(fontSize: 11.5, color: palette.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
