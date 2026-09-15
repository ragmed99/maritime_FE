import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../application/auth_controller.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/fade_slide_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});
  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  String? _validationMessage;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final errorMessage =
        _validationMessage ??
        switch (widget.controller.error) {
          AuthError.invalidCredentials => strings.invalidCredentialsError,
          AuthError.network => strings.networkError,
          AuthError.server => strings.serverError,
          null => null,
        };
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _LoginForm(
            username: _username,
            password: _password,
            obscurePassword: _obscurePassword,
            errorMessage: errorMessage,
            isLoading: widget.controller.isLoading,
            showBranding: !wide,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmit: _submit,
          );
          if (!wide) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.08),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeSlideIn(child: Card(child: form)),
                  ),
                ),
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
                    ),
                  ),
                  child: Center(
                    child: FadeSlideIn(
                      beginOffset: const Offset(-0.06, 0),
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppLogo(size: 96),
                            const SizedBox(height: 28),
                            Text(
                              strings.appName,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 360,
                              child: Text(
                                strings.loginTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FadeSlideIn(
                        beginOffset: const Offset(0.06, 0),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit() {
    final strings = AppLocalizations.of(context);
    final username = _username.text.trim();
    if (username.isEmpty) {
      setState(() => _validationMessage = strings.usernameRequired);
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _validationMessage = strings.passwordRequired);
      return;
    }
    setState(() => _validationMessage = null);
    widget.controller.login(username, _password.text);
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.username,
    required this.password,
    required this.obscurePassword,
    required this.errorMessage,
    required this.isLoading,
    required this.showBranding,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController username;
  final TextEditingController password;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isLoading;
  final bool showBranding;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showBranding) ...[
              const Center(child: AppLogo(size: 96)),
              const SizedBox(height: 16),
              Text(
                strings.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              strings.loginTitle,
              textAlign: showBranding ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: username,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelText: strings.username,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: strings.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: obscurePassword
                      ? strings.showPassword
                      : strings.hidePassword,
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(strings.loginAction),
            ),
          ],
        ),
      ),
    );
  }
}
