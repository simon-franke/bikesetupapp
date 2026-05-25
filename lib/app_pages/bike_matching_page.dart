import 'package:bikesetupapp/app_services/strava_sync_service.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/bike.dart';
import 'package:bikesetupapp/models/strava_bike.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _kmFormatter = NumberFormat('#,###');

class BikeMatchingPage extends StatefulWidget {
  final User user;

  const BikeMatchingPage({super.key, required this.user});

  @override
  State<BikeMatchingPage> createState() => _BikeMatchingPageState();
}

class _BikeMatchingPageState extends State<BikeMatchingPage> {
  List<StravaBike> _stravaBikes = [];
  List<Bike> _appBikes = [];
  final Map<String, String?> _links = {};
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool syncIfEmpty = true}) async {
    final db = ServiceDatabaseService(widget.user.uid);
    final appDb = DatabaseService(widget.user.uid);

    var stravaBikes = await db.getStravaBikes().first;
    final appBikesSnap = await appDb.getBikes().first;

    final appBikes = (appBikesSnap as dynamic)
        .docs
        .map<Bike>((doc) => Bike.fromSnapshot(doc))
        .toList();

    if (stravaBikes.isEmpty && syncIfEmpty) {
      if (mounted) setState(() => _syncing = true);
      await StravaSyncService(db).sync();
      stravaBikes = await db.getStravaBikes().first;
      if (mounted) setState(() => _syncing = false);
    }

    final links = <String, String?>{};
    for (final strava in stravaBikes) {
      if (strava.linkedBikeId != null) {
        links[strava.stravaGearId] = strava.linkedBikeId;
      } else {
        final stravaLower = strava.name.toLowerCase();
        for (final app in appBikes) {
          if (app.name.toLowerCase().contains(stravaLower) ||
              stravaLower.contains(app.name.toLowerCase())) {
            links[strava.stravaGearId] = app.id;
            break;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _stravaBikes = stravaBikes;
        _appBikes = appBikes;
        _links
          ..clear()
          ..addAll(links);
        _loading = false;
      });
    }
  }

  Future<void> _manualSync() async {
    setState(() => _syncing = true);
    final db = ServiceDatabaseService(widget.user.uid);
    await StravaSyncService(db).sync();
    await _loadData(syncIfEmpty: false);
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _saveLinks() async {
    final db = ServiceDatabaseService(widget.user.uid);
    for (final strava in _stravaBikes) {
      final linkedId = _links[strava.stravaGearId];
      if (linkedId != null) {
        await db.linkStravaBike(strava.stravaGearId, linkedId);
      } else if (strava.linkedBikeId != null) {
        await db.unlinkStravaBike(strava.stravaGearId);
      }
    }
    if (mounted) Navigator.of(context).pop();
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _IconBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        leadingWidth: 60,
        title: Text(
          'Link Strava Bikes',
          style: AppTextStyles.inter(
            size: 18,
            weight: FontWeight.w700,
            color: p.ink,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _buildBody(p),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_loading || _syncing) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(p.accent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                (_syncing ? 'Syncing with Strava…' : 'Loading…').toUpperCase(),
                style: AppTextStyles.eyebrow(color: p.inkDim),
              ),
            ],
          ),
        ),
      );
    }

    if (_stravaBikes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        children: [
          _SectionLabel('Strava Bikes'),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bike_rounded,
                        size: 16, color: p.accent),
                    const SizedBox(width: 6),
                    Text(
                      'No strava bikes'.toUpperCase(),
                      style: AppTextStyles.inter(
                        size: 10,
                        weight: FontWeight.w700,
                        color: p.inkDim,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add bikes under Settings → My Gear in the Strava app, then sync again.',
                  style: AppTextStyles.inter(
                    size: 13,
                    color: p.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _OutlineButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry sync',
                  onTap: _manualSync,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
      children: [
        _SectionLabel('Strava Bikes'),
        ..._stravaBikes.map((strava) => _BikeMatchCard(
              strava: strava,
              appBikes: _appBikes,
              linkedId: _links[strava.stravaGearId],
              onChanged: (v) {
                setState(() {
                  _links[strava.stravaGearId] = v;
                });
              },
            )),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _OutlineButton(
                icon: Icons.refresh_rounded,
                label: 'Resync',
                onTap: _manualSync,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                icon: Icons.link_rounded,
                label: 'Save Links',
                onTap: _saveLinks,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BikeMatchCard extends StatelessWidget {
  final StravaBike strava;
  final List<Bike> appBikes;
  final String? linkedId;
  final ValueChanged<String?> onChanged;

  const _BikeMatchCard({
    required this.strava,
    required this.appBikes,
    required this.linkedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final kmText = _kmFormatter.format(strava.distanceKm.round());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 13, color: p.accent),
              const SizedBox(width: 5),
              Text(
                'Strava bike · mileage'.toUpperCase(),
                style: AppTextStyles.inter(
                  size: 9,
                  weight: FontWeight.w700,
                  color: p.inkDim,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  strava.name,
                  style: AppTextStyles.inter(
                    size: 14,
                    weight: FontWeight.w700,
                    color: p.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    kmText,
                    style: AppTextStyles.mono(
                      size: 18,
                      weight: FontWeight.w700,
                      color: p.ink,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'km',
                    style: AppTextStyles.inter(
                      size: 11,
                      weight: FontWeight.w600,
                      color: p.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Linked app bike'.toUpperCase(),
            style: AppTextStyles.inter(
              size: 9,
              weight: FontWeight.w700,
              color: p.inkDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _BikeDropdown(
            value: linkedId,
            appBikes: appBikes,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BikeDropdown extends StatelessWidget {
  final String? value;
  final List<Bike> appBikes;
  final ValueChanged<String?> onChanged;

  const _BikeDropdown({
    required this.value,
    required this.appBikes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded, size: 20, color: p.inkMuted),
          dropdownColor: p.surface2,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          style: AppTextStyles.inter(
            size: 13,
            weight: FontWeight.w600,
            color: p.ink,
          ),
          hint: Text(
            'Select app bike',
            style: AppTextStyles.inter(
              size: 13,
              weight: FontWeight.w600,
              color: p.inkDim,
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Skip',
                style: AppTextStyles.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: p.inkDim,
                ),
              ),
            ),
            ...appBikes.map(
              (app) => DropdownMenuItem<String?>(
                value: app.id,
                child: Text(
                  app.name,
                  style: AppTextStyles.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          Container(width: 12, height: 1, color: p.borderStrong),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: AppTextStyles.eyebrow(color: p.inkDim),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: p.border)),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: p.ink),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: p.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: p.accentInk),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: AppTextStyles.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: p.accentInk,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surface2,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: p.ink),
      ),
    );
  }
}
