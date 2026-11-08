import 'auth_failure_message.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';

class EmailSignInSheet extends StatefulWidget {
  const EmailSignInSheet({super.key, required this.upgrade});

  final bool upgrade;

  @override
  State<EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<EmailSignInSheet> {
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
        setState(() => error = authFailureMessage(failure, widget.upgrade));
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
                AppFormField(
                  label: 'Email',
                  child: AppTextField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction:
                        resetting ? TextInputAction.done : TextInputAction.next,
                    onSubmitted: resetting ? (_) => submit() : null,
                  ),
                ),
                const SizedBox(height: 16),
                if (!resetting)
                  AppFormField(
                    label: 'Password',
                    child: AppTextField(
                      controller: password,
                      enabled: !busy,
                      obscureText: !showPassword,
                      autocorrect: false,
                      autofillHints: [
                        signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password
                      ],
                      onSubmitted: (_) => submit(),
                      suffixWidget: IconButton(
                        tooltip:
                            showPassword ? 'Hide password' : 'Show password',
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                        icon: Icon(showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      ),
                    ),
                  ),
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
                SizedBox(
                    height: !signUp && !resetting && !widget.upgrade ? 12 : 24),
                AppFormFooter(
                    error: error,
                    isLoading: busy,
                    loadingLabel: 'Please wait…',
                    onPressed: submit,
                    label: resetting
                        ? 'Send reset link'
                        : signUp
                            ? 'Create account'
                            : 'Sign in'),
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
