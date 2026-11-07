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
          appBar: AppBar(
              title: const Text('Delete account'),
              automaticallyImplyLeading: !busy,
              leading: widget.onCancel == null
                  ? null
                  : IconButton(
                      tooltip: 'Back',
                      onPressed: busy ? null : widget.onCancel,
                      icon: const Icon(Icons.arrow_back))),
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
              TextField(
                  controller: password,
                  obscureText: true,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'))
            ],
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)))),
            const SizedBox(height: 28),
            FilledButton(
                onPressed: busy ? null : remove,
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError),
                child: Text(busy ? 'Deleting account…' : 'Delete account')),
            TextButton(
                onPressed: busy
                    ? null
                    : widget.onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
          ])),
        ));
  }
}
