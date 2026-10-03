import '../controllers/bike_matching_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
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
  late final BikeMatchingController _controller;
  List<StravaBike> get _stravaBikes => _controller.stravaBikes;
  List<Bike> get _appBikes => _controller.appBikes;
  Map<String, String?> get _links => _controller.links;
  bool get _loading => _controller.loading;
  bool get _syncing => _controller.syncing;

  @override
  void initState() {
    super.initState();
    final user = AppDependencies.of(context).forUser(widget.user.uid);
    _controller = BikeMatchingController(user.bikes, user.strava)
      ..addListener(_changed);
    _loadData();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _controller.load();
    _showSyncError(_controller.syncError);
  }

  Future<void> _manualSync() async {
    await _controller.sync();
    _showSyncError(_controller.syncError);
  }

  void _showSyncError(String? message) {
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 8)));
  }

  Future<void> _saveLinks() async {
    await _controller.save();
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
                        size: 16, color: p.accentText),
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
                _controller.link(strava.stravaGearId, v);
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
                  size: 13, color: p.accentText),
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
    return AppSectionLabel(text);
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
    return SizedBox(
        width: double.infinity,
        child: AppActionButton(
            label: label, icon: icon, onPressed: onTap, outlined: true));
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
    return AppActionButton(label: label, icon: icon, onPressed: onTap);
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
