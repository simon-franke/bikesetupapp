import 'privacy_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/failure_message.dart';

String _authMessage(AppFailure failure, bool upgrade) => upgrade &&
        failure.code == FailureCode.emailInUse
    ? 'That account already exists. Your guest bikes are still here. Use a different account to save them.'
    : failureMessage(failure);

/// Authentication only. The app's session gate owns all successful navigation.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.upgrade = false});
  final bool upgrade;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool busy = false;
  String? error;

  Future<void> authenticate(
      Future<CommandResult<UserCredential>> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      (await action()).requireValue();
    } on CommandAborted {
      // Closing the provider prompt leaves the current page intact.
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => error = _authMessage(failure, widget.upgrade));
      }
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
      if (mounted) setState(() => error = 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appleFirst = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    Widget provider(bool apple) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: apple ? Colors.black : Colors.white,
              foregroundColor: apple ? Colors.white : const Color(0xFF424242),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onPressed: busy
                ? null
                : () => authenticate(apple
                    ? AppDependencies.of(context).auth.signInWithApple
                    : AppDependencies.of(context).auth.signInWithGoogle),
            icon: Image.asset(
                apple ? 'assets/apple_icon.png' : 'assets/google_icon.png',
                height: 22,
                color: apple ? Colors.white : null),
            label: Text('Continue with ${apple ? 'Apple' : 'Google'}',
                textAlign: TextAlign.center),
          ),
        );
    return Scaffold(
      appBar: widget.upgrade ? AppBar(title: const Text('Save account')) : null,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      Image.asset('assets/app-icon/logo.png',
                          width: 104, height: 104, excludeFromSemantics: true),
                      const SizedBox(height: 12),
                      Text('Clickwise',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading),
                      if (widget.upgrade) ...[
                        const SizedBox(height: 12),
                        Text('Create an account to keep your existing bikes.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body
                                .copyWith(color: context.palette.inkMuted)),
                      ],
                      const SizedBox(height: 48),
                      const Text('Sign in or create an account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label),
                      const SizedBox(height: 20),
                      if (appleFirst) provider(true),
                      provider(false),
                      TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => showAppSheet<void>(
                                  context: context,
                                  builder: (_) => _EmailSignInSheet(
                                      upgrade: widget.upgrade)),
                          icon: const Icon(Icons.mail_outline, size: 20),
                          label: const Text('Continue with email')),
                      if (busy)
                        const Center(
                            child: CircularProgressIndicator.adaptive()),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 16),
                    child: TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: context.palette.inkMuted,
                            textStyle: AppTextStyles.caption),
                        onPressed: () => Navigator.of(context)
                            .push(AppRoutes.fadeSlide(const PrivacyPage())),
                        child: const Text('Privacy policy')),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmailSignInSheet extends StatefulWidget {
  const _EmailSignInSheet({required this.upgrade});
  final bool upgrade;
  @override
  State<_EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<_EmailSignInSheet> {
  final email = TextEditingController();
  final password = TextEditingController();
  late bool signUp = widget.upgrade;
  bool busy = false;
  bool resetting = false;
  bool resetSent = false;
  bool showPassword = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (!email.text.trim().contains('@') ||
        (!resetting && password.text.isEmpty)) {
      setState(() => error = resetting
          ? 'Enter a valid email address.'
          : 'Enter a valid email address and password.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    resetSent = false;
    final auth = AppDependencies.of(context).auth;
    try {
      if (resetting) {
        (await auth.resetPassword(email.text.trim())).requireValue();
        if (mounted) setState(() => resetSent = true);
        return;
      }
      final result = signUp
          ? await auth.signUpWithEmail(email.text.trim(), password.text)
          : await auth.signInWithEmail(email.text.trim(), password.text);
      result.requireValue();
    } on CommandAborted {
      // The session gate handles successful authentication.
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => error = _authMessage(failure, widget.upgrade));
      }
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
      if (mounted) setState(() => error = 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: AutofillGroup(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const AppSheetHandle(),
                const SizedBox(height: 20),
                Text(
                    resetting
                        ? 'Reset password'
                        : signUp
                            ? 'Create account'
                            : 'Sign in with email',
                    style: AppTextStyles.heading),
                const SizedBox(height: 20),
                Text('Email',
                    style: AppTextStyles.caption
                        .copyWith(color: context.palette.inkMuted)),
                const SizedBox(height: 8),
                Semantics(
                    label: 'Email',
                    child: TextField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: resetting
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: resetting ? (_) => submit() : null,
                        decoration: const InputDecoration())),
                const SizedBox(height: 16),
                if (!resetting) ...[
                  Text('Password',
                      style: AppTextStyles.caption
                          .copyWith(color: context.palette.inkMuted)),
                  const SizedBox(height: 8),
                  Semantics(
                      label: 'Password',
                      child: TextField(
                          controller: password,
                          enabled: !busy,
                          obscureText: !showPassword,
                          autofillHints: [
                            signUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password
                          ],
                          onSubmitted: (_) => submit(),
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  tooltip: showPassword
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: () => setState(
                                      () => showPassword = !showPassword),
                                  icon: Icon(showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined))))),
                ],
                if (!signUp && !resetting && !widget.upgrade)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: AppTextStyles.caption,
                        foregroundColor: context.palette.inkMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 12),
                      ),
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                resetting = true;
                                error = null;
                              }),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (resetSent)
                  const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                          'If an account uses this email, a reset link has been sent.')),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                SizedBox(
                    height: !signUp && !resetting && !widget.upgrade ? 12 : 24),
                ElevatedButton(
                    onPressed: busy ? null : submit,
                    child: Text(busy
                        ? 'Please wait…'
                        : resetting
                            ? 'Send reset link'
                            : signUp
                                ? 'Create account'
                                : 'Sign in')),
                if (resetting)
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                resetting = false;
                                resetSent = false;
                                error = null;
                              }),
                      child: const Text('Back to sign in')),
                if (!widget.upgrade && !resetting) ...[
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                signUp = !signUp;
                                error = null;
                              }),
                      child: Text.rich(
                          TextSpan(
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(
                                text: signUp
                                    ? 'Already have an account? '
                                    : 'New here? ',
                                style:
                                    TextStyle(color: context.palette.inkMuted),
                              ),
                              TextSpan(
                                  text:
                                      signUp ? 'Sign in' : 'Create an account'),
                            ],
                          ),
                          textAlign: TextAlign.center)),
                ],
              ])),
        ),
      );
}
