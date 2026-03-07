import 'dart:io';

import 'package:bikesetupapp/alert_dialogs/auth_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';
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
    } catch (e) {
      if (!context.mounted) return;
      AuthAlerts.generalError(context, 'Error: $e');
      return;
    }
    if (!context.mounted) return;
    AuthAlerts.handleAuthentication(userCredential, context);
  }

  void _showEmailSignIn(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EmailSignInSheet(
        onSignIn: (signInFn) => _handleSignIn(context, signInFn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(primaryColor: theme.primaryColor),
                const SizedBox(height: 40),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SignInButton(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF424242),
                          borderColor: const Color(0xFFDDDDDD),
                          icon: Image.asset(_googleIconPath, height: 22),
                          label: 'Sign in with Google',
                          onPressed: () => _handleSignIn(
                            context,
                            () => AuthService().signInWithGoogle(),
                          ),
                        ),
                        if (_showAppleSignIn) ...[
                          const SizedBox(height: 12),
                          _SignInButton(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            icon: Image.asset(_appleIconPath, height: 22, color: Colors.white, colorBlendMode: BlendMode.srcIn),
                            label: 'Sign in with Apple',
                            onPressed: () => _handleSignIn(
                              context,
                              () => AuthService().signInWithApple(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SignInButton(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.email_outlined,
                              size: 22, color: Colors.white),
                          label: 'Sign in with Email',
                          onPressed: () => _showEmailSignIn(context),
                        ),
                        const SizedBox(height: 12),
                        _SignInButton(
                          backgroundColor: const Color(0xFF3A546D),
                          foregroundColor: Colors.white,
                          icon: Image.asset(_incognitoIconPath, height: 22),
                          label: 'Continue anonymously',
                          onPressed: () => _handleSignIn(
                            context,
                            () => FirebaseAuth.instance.signInAnonymously(),
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
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bike, size: 80, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Bike Setup',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 32),
          ),
        ],
      ),
    );
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
        await AuthService().signUpWithEmail(email, password);
        if (mounted) {
          setState(() {
            _isSignUp = false;
            _accountCreated = true;
            _passwordController.clear();
          });
        }
      } else {
        await widget.onSignIn(
          () => AuthService().signInWithEmail(email, password),
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
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
          borderRadius: BorderRadius.circular(30),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 28, child: Center(child: icon)),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
