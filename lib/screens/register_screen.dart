import 'package:flutter/material.dart';

import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../widgets/campus_themed.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import '../widgets/inti_logo.dart';

/// Sign-up form. Everything entered here is saved in the `students` table.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const CampusThemed(child: _RegisterForm());
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otherProgramme = TextEditingController();
  final _cgpa = TextEditingController();
  final _credits = TextEditingController();
  final _phone = TextEditingController();

  String? _programme;
  int _semester = 1;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _studentId, _email, _password, _confirm, _otherProgramme, _cgpa, _credits, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final programme = _programme == otherProgramme ? _otherProgramme.text.trim() : _programme!;
    final data = RegistrationData(
      fullName: _name.text.trim(),
      studentId: _studentId.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      programme: programme,
      semester: _semester,
      cgpa: double.tryParse(_cgpa.text.trim()),
      creditsEarned: int.tryParse(_credits.text.trim()) ?? 0,
      phone: _phone.text.trim(),
    );

    try {
      await AppState.instance.register(data);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      showCampusSnack(context, 'Welcome, ${data.fullName.split(' ').first}! Your account is ready.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return GlassPage(
      title: 'Create account',
      actions: const [ThemeToggleButton(), SizedBox(width: 12)],
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: IntiLogo(height: 44)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Set up your student account',
                    textAlign: TextAlign.center,
                    style: AppText.h2.copyWith(color: palette.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your details personalise every page of the app.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_error != null) FormErrorBanner(message: _error!),
                  _section(
                    title: 'Account',
                    icon: Icons.badge_rounded,
                    children: [
                      CampusTextField(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                      ),
                      CampusTextField(
                        controller: _studentId,
                        label: 'Student ID',
                        hint: 'e.g. I23012345',
                        icon: Icons.numbers_rounded,
                        textCapitalization: TextCapitalization.characters,
                        validator: validateStudentId,
                      ),
                      CampusTextField(
                        controller: _email,
                        label: 'Student email',
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                      ),
                      CampusTextField(
                        controller: _password,
                        label: 'Password',
                        hint: 'At least 6 characters',
                        icon: Icons.lock_rounded,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null,
                        suffix: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      CampusTextField(
                        controller: _confirm,
                        label: 'Confirm password',
                        icon: Icons.lock_reset_rounded,
                        obscureText: _obscure,
                        validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    title: 'Studies',
                    icon: Icons.school_rounded,
                    children: [
                      FormField<String>(
                        validator: (_) => _programme == null ? 'Choose your programme' : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CampusDropdown<String>(
                              label: 'Programme',
                              icon: Icons.menu_book_rounded,
                              value: _programme,
                              items: const [...programmeOptions, otherProgramme],
                              onChanged: (v) {
                                setState(() => _programme = v);
                                field.didChange(v);
                              },
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 10),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: palette.isDark ? AppColors.warning : Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_programme == otherProgramme)
                        CampusTextField(
                          controller: _otherProgramme,
                          label: 'Programme name',
                          icon: Icons.edit_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => requiredField(v, 'programme name'),
                        ),
                      CampusDropdown<int>(
                        label: 'Current semester',
                        icon: Icons.layers_rounded,
                        value: _semester,
                        items: const [1, 2, 3, 4, 5, 6, 7, 8],
                        itemLabel: (s) => 'Semester $s',
                        onChanged: (v) => setState(() => _semester = v ?? 1),
                      ),
                      FieldPair(
                        first: CampusTextField(
                              controller: _cgpa,
                              label: 'CGPA (optional)',
                              hint: '0.00 – 4.00',
                              icon: Icons.star_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: validateCgpa,
                            ),
                        second: CampusTextField(
                              controller: _credits,
                              label: 'Credits earned',
                              hint: 'e.g. 45',
                              icon: Icons.workspace_premium_rounded,
                              keyboardType: TextInputType.number,
                              validator: validateCredits,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    title: 'Contact (optional)',
                    icon: Icons.phone_rounded,
                    children: [
                      CampusTextField(
                        controller: _phone,
                        label: 'Phone number',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: _loading ? 'Creating account…' : 'Create account',
                    icon: Icons.person_add_alt_1_rounded,
                    expand: true,
                    onPressed: _loading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Already registered?', style: AppText.body.copyWith(color: palette.textMuted)),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.isDark ? Colors.white : AppColors.primary,
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final palette = CampusPalette.of(context);
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      tint: 0.16,
      colors: palette.isDark ? null : palette.glassStrong,
      borderColor: palette.isDark ? null : palette.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.isDark ? Colors.white : AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppText.title.copyWith(color: palette.text))),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
