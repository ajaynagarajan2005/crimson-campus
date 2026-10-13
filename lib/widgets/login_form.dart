import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'form_fields.dart';

/// Email-or-ID + password form. Used on the Login page and the landing page.
/// On success it opens the dashboard.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppState.instance.login(_identifier.text, _password.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) FormErrorBanner(message: _error!),
            CampusTextField(
              controller: _identifier,
              label: 'Email or student ID',
              icon: Icons.person_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              validator: (v) => requiredField(v, 'email or student ID'),
            ),
            CampusTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              suffix: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 4),
            PillButton(
              label: _loading ? 'Logging in…' : 'Log in',
              icon: Icons.login_rounded,
              expand: true,
              onPressed: _loading ? null : _login,
            ),
          ],
        ),
      ),
    );
  }
}
