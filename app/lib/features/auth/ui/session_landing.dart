import 'package:flutter/foundation.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:flutter/cupertino.dart';
import '../../setups/models/setup_configuration.dart';
import '../../../app/routing/app_motion.dart';
import 'delete_account_page.dart';
import 'package:bikesetupapp/features/settings/ui/settings_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/app/startup/startup_controller.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/quick_bike_sheet.dart';
import 'package:bikesetupapp/features/workspace/ui/home_page.dart';
import 'google_sign_in.dart';

class SessionLanding extends StatefulWidget {
  const SessionLanding(
      {super.key,
      required this.user,
      this.deleteAccount = false,
      this.onCancelDeletion});

  final User? user;
  final bool deleteAccount;
  final VoidCallback? onCancelDeletion;

  @override
  State<SessionLanding> createState() => _SessionLandingState();
}

class _SessionLandingState extends State<SessionLanding> {
  SetupConfiguration? createdConfiguration;
  late Future<StartupSelection?> selection = load();

  Future<StartupSelection?> load() => widget.user == null
      ? Future.value(null)
      : AppDependencies.of(context)
          .forUser(widget.user!.uid)
          .startup
          .loadSelection();

  void bikeCreated(String name, String bike, String setupName, String setup,
      SetupConfiguration configuration) {
    if (!mounted) return;
    setState(() {
      createdConfiguration = configuration;
      selection = SynchronousFuture(StartupSelection(
          bikeId: bike, bikeName: name, setupId: setup, setupName: setupName));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) return const LoginPage();
    if (widget.deleteAccount) {
      return DeleteAccountPage(onCancel: widget.onCancelDeletion);
    }
    return FutureBuilder<StartupSelection?>(
        future: selection,
        builder: (context, snapshot) => AppScreenTransition(
              child: _screen(context, snapshot),
            ));
  }

  Widget _screen(
      BuildContext context, AsyncSnapshot<StartupSelection?> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Scaffold(
          key: ValueKey('loading'),
          body: Center(child: AppLoadingState(label: 'Loading your bikes…')));
    }

    final selected = snapshot.data;
    if (!snapshot.hasError && selected != null) {
      return MyHomePage(
          key: const ValueKey('workspace'),
          user: widget.user,
          initialConfiguration: createdConfiguration,
          onNoBikes: () {
            if (!mounted) return;
            setState(() {
              createdConfiguration = null;
              selection = SynchronousFuture(null);
            });
          },
          bikeName: selected.bikeName,
          uBikeID: selected.bikeId,
          setupName: selected.setupName,
          uSetupID: selected.setupId);
    }

    return Scaffold(
        key: ValueKey(snapshot.hasError ? 'error' : 'no-bikes'),
        appBar: AppBar(title: const Text('Clickwise'), actions: [
          IconButton(
              tooltip: 'Settings',
              icon: const Icon(CupertinoIcons.gear_alt,
                  size: AppIconSizes.control),
              onPressed: () => Navigator.of(context).push(AppRoutes.fadeSlide(
                  const SettingsPage(bikeName: '', chosenSetup: ''))))
        ]),
        body: SafeArea(
            child: snapshot.hasError
                ? ListView(padding: const EdgeInsets.all(24), children: [
                    const Text('Could not load your bikes',
                        style: AppTextStyles.heading),
                    const SizedBox(height: 16),
                    AppTactileButton(
                        onPressed: () => setState(() {
                              selection = load();
                            }),
                        child: const Text('Retry')),
                  ])
                : QuickBikeSheet(
                    user: widget.user!,
                    isSheet: false,
                    onCreated: bikeCreated)));
  }
}
