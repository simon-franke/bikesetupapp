import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/widgets/app_components.dart';
import 'package:bikesetupapp/alert_dialogs/auth_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/bike_matching_page.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/app_state_notifier.dart';
import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/app_services/strava_sync_service.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final String bikeName;
  final BikeType bikeType;
  final String chosenSetup;
  const SettingsPage({
    super.key,
    required this.bikeName,
    required this.bikeType,
    required this.chosenSetup,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? user = FirebaseAuth.instance.currentUser;
  bool _isStravaConnected = false;
  int? _stravaAthleteId;
  int _stravaBikeCount = 0;

  @override
  void initState() {
    super.initState();
    _checkStravaConnection();
  }

  Future<void> _checkStravaConnection() async {
    final auth = await StravaTokenStorage.getAuth();
    int bikeCount = 0;
    if (auth != null && user != null) {
      try {
        final bikes =
            await ServiceDatabaseService(user!.uid).getStravaBikes().first;
        bikeCount = bikes.length;
      } catch (_) {/* count is best-effort */}
    }
    if (mounted) {
      setState(() {
        _isStravaConnected = auth != null;
        _stravaAthleteId = auth?.athleteId;
        _stravaBikeCount = bikeCount;
      });
    }
  }

  Future<void> _connectStrava() async {
    final auth = await StravaAuthService().authorize();
    if (auth != null && mounted) {
      setState(() {
        _isStravaConnected = true;
        _stravaAthleteId = auth.athleteId;
      });
      if (user != null) {
        final sync = StravaSyncService(ServiceDatabaseService(user!.uid));
        if (!await sync.sync() && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(sync.lastError ?? 'Could not sync Strava. Try again.'),
            duration: const Duration(seconds: 8),
          ));
        }
        _checkStravaConnection();
      }
    }
  }

  Future<void> _connectStravaWeb() async {
    await StravaAuthService().authorizeWeb();
  }

  Future<void> _disconnectStrava() async {
    await StravaAuthService().deauthorize();
    if (user != null) {
      await ServiceDatabaseService(user!.uid).deleteAllStravaBikes();
    }
    if (mounted) {
      setState(() {
        _isStravaConnected = false;
        _stravaAthleteId = null;
        _stravaBikeCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppContentFrame(
          maxWidth: 700,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _IconBtn(
              icon: Icons.close_rounded,
              onTap: () {
                if (user == null) {
                  Navigator.of(context)
                      .push(AppRoutes.fadeSlide(const LoginPage()));
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(width: 12),
            Text('Settings',
                style: AppTextStyles.inter(
                  size: 18,
                  weight: FontWeight.w700,
                  color: p.ink,
                  letterSpacing: -0.3,
                )),
          ]),
        ),
      ),
      body: SafeArea(
          top: false,
          child: AppContentFrame(
              maxWidth: 700,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                children: [
                  _SectionLabel('Appearance'),
                  _SettingsCard(child: _ThemeSegmented()),
                  _SectionLabel('Account'),
                  _SettingsCard(
                      child: _AccountRow(
                    user: user,
                    onSignOut: _onSignOut,
                    onSignIn: _onSignIn,
                  )),
                  _SectionLabel('Integrations'),
                  _SettingsCard(
                    child: _StravaCard(
                      isConnected: _isStravaConnected,
                      athleteId: _stravaAthleteId,
                      bikeCount: _stravaBikeCount,
                      onConnect: kIsWeb ? _connectStravaWeb : _connectStrava,
                      onDisconnect: _disconnectStrava,
                      onManageBikes: () {
                        if (user != null) {
                          Navigator.of(context).push(
                            AppRoutes.fadeSlide(BikeMatchingPage(user: user!)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ))),
    );
  }

  Future<void> _onSignOut() async {
    if (user != null && user!.isAnonymous) {
      bool? wantsToSignOut = await AuthAlerts.signOutAnonymous(context, user!);
      if (wantsToSignOut == null || !wantsToSignOut) return;
    }
    AuthService().signOut();
    setState(() => user = null);
  }

  void _onSignIn() {
    Navigator.of(context).push(AppRoutes.fadeSlide(const LoginPage()));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return AppSectionLabel(text);
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<AppStateNotifier>(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const AppFieldLabel('Theme'),
      const SizedBox(height: 10),
      SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ],
        selected: {notifier.themeMode},
        onSelectionChanged: (modes) => notifier.updateTheme(modes.single),
      ),
    ]);
  }
}

class _AccountRow extends StatelessWidget {
  final User? user;
  final Future<void> Function() onSignOut;
  final VoidCallback onSignIn;
  const _AccountRow(
      {required this.user, required this.onSignOut, required this.onSignIn});

  String _initials(User u) {
    final name = u.displayName?.trim() ?? '';
    if (name.isEmpty) return u.isAnonymous ? 'AN' : '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final u = user;
    final name = u == null
        ? 'No User'
        : (u.displayName ?? (u.isAnonymous ? 'Anonymous' : 'Signed in'));
    final email = u?.email ?? '';
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.accent,
            image: (u?.photoURL != null)
                ? DecorationImage(
                    image: NetworkImage(u!.photoURL!), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: (u?.photoURL == null)
              ? Text(
                  u == null ? '?' : _initials(u),
                  style: AppTextStyles.inter(
                    size: 13,
                    weight: FontWeight.w800,
                    color: p.accentInk,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTextStyles.inter(
                    size: 13, weight: FontWeight.w700, color: p.ink),
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: AppTextStyles.inter(size: 11, color: p.inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        _OutlineChip(
          label: u == null ? 'Sign in' : 'Sign out',
          onTap: u == null ? onSignIn : () => onSignOut(),
        ),
      ],
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppActionButton(label: label, onPressed: onTap, outlined: true);
  }
}

class _StravaCard extends StatelessWidget {
  final bool isConnected;
  final int? athleteId;
  final int bikeCount;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onManageBikes;
  const _StravaCard({
    required this.isConnected,
    required this.athleteId,
    required this.bikeCount,
    required this.onConnect,
    required this.onDisconnect,
    required this.onManageBikes,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.directions_bike_rounded,
                  size: 18, color: p.accentInk),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strava',
                    style: AppTextStyles.inter(
                      size: 13,
                      weight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    isConnected
                        ? (bikeCount > 0
                            ? 'Connected · $bikeCount bike${bikeCount == 1 ? '' : 's'} synced'
                            : 'Connected')
                        : 'Not connected',
                    style: AppTextStyles.inter(size: 10.5, color: p.inkMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isConnected ? p.green : p.inkDim,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isConnected) ...[
          _OutlineButton(
            icon: Icons.sync_alt_rounded,
            label: 'Manage Strava bikes',
            onTap: onManageBikes,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDisconnect,
              child: Text(
                'Disconnect',
                style: AppTextStyles.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: p.red,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ] else
          SizedBox(
            width: ResponsiveLayout.isWide(context) ? null : double.infinity,
            child: AppActionButton(
                label: 'Connect Strava',
                icon: Icons.directions_bike_rounded,
                onPressed: onConnect),
          ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: ResponsiveLayout.isWide(context) ? null : double.infinity,
        child: AppActionButton(
            label: label, icon: icon, onPressed: onTap, outlined: true));
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon));
  }
}
