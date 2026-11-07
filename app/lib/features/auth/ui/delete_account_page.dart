import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.onCancel});

  final VoidCallback? onCancel;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> remove() async {
    if (busy) return;

    setState(() {
      busy = true;
      error = null;
    });
    await presentCommand(
        context,
        () => AppDependencies.of(context)
            .auth
            .deleteAccount(password: password.text),
        fallback: 'Could not finish deleting your account. Please retry.',
        onFailure: (message) {
      if (mounted) setState(() => error = message);
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppDependencies.of(context).auth.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final needsPassword =
        providers.contains('password') && !providers.contains('apple.com');

    return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: buildDetailAppBar(context,
              title: 'Delete account',
              onBack: widget.onCancel,
              backEnabled: !busy),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Delete your account?', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            const Text(
                'This permanently deletes your Clickwise account, bikes, setups, experiments, ride records and service history. This cannot be undone.'),
            const SizedBox(height: 16),
            Text(needsPassword
                ? 'Enter your password to confirm.'
                : user?.isAnonymous == true
                    ? 'Your guest data will also be deleted.'
                    : 'You’ll be asked to confirm your identity with your sign-in provider.'),
            if (needsPassword) ...[
              const SizedBox(height: 20),
              AppFormField(
                  label: 'Password',
                  child: AppTextField(
                      controller: password,
                      obscureText: true,
                      autocorrect: false,
                      enabled: !busy,
                      autofillHints: const [AutofillHints.password])),
            ],
            const SizedBox(height: 28),
            AppFormFooter(
                label: 'Delete account',
                destructive: true,
                isLoading: busy,
                loadingLabel: 'Deleting account…',
                error: error,
                onPressed: remove),
            TextButton(
                onPressed: busy
                    ? null
                    : widget.onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
          ])),
        ));
  }
}
