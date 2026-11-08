import 'email_sign_in_sheet.dart';
import 'auth_failure_message.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'privacy_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';

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
      appBar: widget.upgrade
          ? buildDetailAppBar(context, title: 'Save account')
          : null,
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
                                  builder: (_) => EmailSignInSheet(
                                      upgrade: widget.upgrade)),
                          icon: const Icon(Icons.mail_outline, size: 20),
                          label: const Text('Continue with email')),
                      if (busy)
                        const Center(
                            child: AppLoadingContent(label: 'Signing in…')),
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
