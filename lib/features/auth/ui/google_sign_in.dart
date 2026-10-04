import 'package:bikesetupapp/common/ui/failure_message.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'dart:io';
import 'package:bikesetupapp/common/theme/theme_data.dart';

import 'package:bikesetupapp/features/auth/ui/auth_alert_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String _googleIconPath = 'assets/google_icon.png';
const String _incognitoIconPath = 'assets/incognito.png';
const String _appleIconPath = 'assets/apple_icon.png';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  bool get _showAppleSignIn => kIsWeb || Platform.isIOS || Platform.isMacOS;

  Future<void> _handleSignIn(
    BuildContext context,
    Future<UserCredential> Function() signInFn,
  ) async {
    final UserCredential userCredential;
    try {
      userCredential = await signInFn();
    } catch (e, stack) {
      if (e is! AppFailure && e is! CommandAborted) {
        FlutterError.reportError(
            FlutterErrorDetails(exception: e, stack: stack));
      }
      if (e is CommandAborted || !context.mounted) return;
      AuthAlerts.generalError(
          context,
          e is AppFailure
              ? failureMessage(e)
              : 'Could not sign in. Try again.');
      return;
    }
    if (!context.mounted) return;
    await AuthAlerts.handleAuthentication(userCredential, context);
  }

  void _showEmailSignIn(BuildContext context) {
    showAdaptiveModal<void>(
      context: context,
      builder: (_) => _EmailSignInSheet(
        onSignIn: (signInFn) => _handleSignIn(context, signInFn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: AppContentFrame(
                            maxWidth: 440,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                const _Header(),
                                const SizedBox(height: 32),
                                SafeArea(
                                  top: false,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _SignInButton(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF424242),
                                          borderColor: const Color(0xFFDDDDDD),
                                          icon: Image.asset(_googleIconPath,
                                              height: 22),
                                          label: 'Sign in with Google',
                                          onPressed: () => _handleSignIn(
                                            context,
                                            () => AppDependencies.of(context)
                                                .auth
                                                .signInWithGoogle()
                                                .orThrow(),
                                          ),
                                        ),
                                        if (_showAppleSignIn) ...[
                                          const SizedBox(height: 12),
                                          _SignInButton(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            icon: Image.asset(_appleIconPath,
                                                height: 22,
                                                color: Colors.white,
                                                colorBlendMode:
                                                    BlendMode.srcIn),
                                            label: 'Sign in with Apple',
                                            onPressed: () => _handleSignIn(
                                              context,
                                              () => AppDependencies.of(context)
                                                  .auth
                                                  .signInWithApple()
                                                  .orThrow(),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        _SignInButton(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor:
                                              theme.colorScheme.onPrimary,
                                          icon: Icon(Icons.email_outlined,
                                              size: 22,
                                              color:
                                                  theme.colorScheme.onPrimary),
                                          label: 'Sign in with Email',
                                          onPressed: () =>
                                              _showEmailSignIn(context),
                                        ),
                                        const SizedBox(height: 12),
                                        _SignInButton(
                                          backgroundColor:
                                              const Color(0xFF3A546D),
                                          foregroundColor: Colors.white,
                                          icon: Image.asset(_incognitoIconPath,
                                              height: 22,
                                              color: Colors.white,
                                              colorBlendMode: BlendMode.srcIn),
                                          label: 'Continue anonymously',
                                          onPressed: () => _handleSignIn(
                                            context,
                                            () => AppDependencies.of(context)
                                                .auth
                                                .signInAnonymously()
                                                .orThrow(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        )),
                  ))),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.directions_bike,
              size: 44, color: theme.colorScheme.onPrimary)),
      const SizedBox(height: 20),
      Text('Bike Setup',
          style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Your bikes, settings and service history.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: context.palette.inkMuted)),
    ]);
  }
}

class _EmailSignInSheet extends StatefulWidget {
  const _EmailSignInSheet({required this.onSignIn});

  final Future<void> Function(Future<UserCredential> Function()) onSignIn;

  @override
  State<_EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<_EmailSignInSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _accountCreated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await AppDependencies.of(context)
            .auth
            .signUpWithEmail(email, password)
            .orThrow();
        if (mounted) {
          setState(() {
            _isSignUp = false;
            _accountCreated = true;
            _passwordController.clear();
          });
        }
      } else {
        await widget.onSignIn(
          () => AppDependencies.of(context)
              .auth
              .signInWithEmail(email, password)
              .orThrow(),
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = failureMessage(e));
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
      if (mounted) setState(() => _error = "Could not sign in. Try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          if (_accountCreated) ...[
            const SizedBox(height: 10),
            Text('Account created! Please sign in.',
                style: TextStyle(color: theme.colorScheme.primary)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.onPrimary),
                  )
                : Text(_isSignUp ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _error = null;
              _accountCreated = false;
            }),
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryColor,
            ),
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign\u00a0in'
                  : "Don't have an account? Sign\u00a0up",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Row(children: [
        SizedBox(width: 28, child: Center(child: icon)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor))),
      ]),
    );
  }
}
