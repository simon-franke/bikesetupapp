import 'strava_settings.dart';
import 'account_settings.dart';
import 'package:bikesetupapp/features/auth/ui/delete_account_page.dart';
import 'package:bikesetupapp/features/auth/ui/privacy_page.dart';
import 'package:flutter/cupertino.dart';
import 'theme_selector.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/settings_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/auth/ui/auth_alert_dialogs.dart';
import 'package:bikesetupapp/features/strava/ui/bike_matching_page.dart';
import 'package:bikesetupapp/features/auth/ui/login_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  final String bikeName;

  final String chosenSetup;

  const SettingsPage({
    super.key,
    required this.bikeName,
    required this.chosenSetup,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;

  User? get user => _controller.user;
  bool get _isStravaConnected => _controller.connected;
  int get _stravaBikeCount => _controller.bikeCount;

  @override
  void initState() {
    super.initState();
    final dependencies = AppDependencies.of(context);
    _controller = SettingsController(dependencies.auth,
        dependencies.stravaConnection, (id) => dependencies.forUser(id).strava)
      ..addListener(_changed);
    presentCommand(context, _controller.load);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connectStrava() async {
    await presentCommand(context, _controller.connect);
  }

  Future<void> _disconnectStrava() async {
    await presentCommand(context, _controller.disconnect);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: buildDetailAppBar(context, title: 'Settings'),
      body: SafeArea(
          top: false,
          child: SizedBox(
              width: double.infinity,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  AppSectionLabel('Appearance'),
                  _SettingsCard(child: _ThemePreferences()),
                  AppSectionLabel('Account'),
                  _SettingsCard(
                      child: AccountSettings(
                    user: user,
                    onSignOut: _onSignOut,
                    onSignIn: _onSignIn,
                  )),
                  if (user?.isAnonymous == true)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _onSignOut,
                            child: const Text('Leave guest session'))),
                  AppSectionLabel('Integrations'),
                  _SettingsCard(
                    child: user == null || user!.isAnonymous
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                const Text('Track mileage automatically',
                                    style: AppTextStyles.label),
                                const SizedBox(height: 8),
                                const Text(
                                    'Save your bikes to an account, then connect Strava to sync ride distances.'),
                                const SizedBox(height: 12),
                                AppActionButton(
                                    label: 'Save to an account',
                                    onPressed: _onSignIn),
                              ])
                        : StravaSettings(
                            isConnected: _isStravaConnected,
                            bikeCount: _stravaBikeCount,
                            onConnect: _connectStrava,
                            onDisconnect: _disconnectStrava,
                            onManageBikes: () {
                              if (user != null) {
                                Navigator.of(context).push(
                                  AppRoutes.fadeSlide(
                                      BikeMatchingPage(user: user!)),
                                );
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Privacy policy'),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                      onTap: () => Navigator.of(context)
                          .push(AppRoutes.fadeSlide(const PrivacyPage()))),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Delete account',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      onTap: _controller.isBusy
                          ? null
                          : () => Navigator.of(context).push(
                              AppRoutes.fadeSlide(const DeleteAccountPage()))),
                ],
              ))),
    );
  }

  Future<void> _onSignOut() async {
    if (user != null && user!.isAnonymous) {
      bool? wantsToSignOut = await AuthAlerts.signOutAnonymous(context, user!);
      if (wantsToSignOut == null || !wantsToSignOut) return;
    }
    if (!mounted) return;
    await presentCommand(context, _controller.signOut);
    if (!mounted) return;
  }

  void _onSignIn() {
    Navigator.of(context, rootNavigator: true).push(
        AppRoutes.fadeSlide(LoginPage(upgrade: user?.isAnonymous == true)));
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _ThemePreferences extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<AppStateNotifier>(context);
    return ThemeSelector(
        selected: notifier.themeMode,
        onChanged: notifier.isBusy
            ? null
            : (mode) =>
                presentCommand(context, () => notifier.updateTheme(mode)));
  }
}
