import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/common/ui/app_select.dart';
import 'package:bikesetupapp/common/ui/bike_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
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
    await presentCommand(context, () => _controller.load());
  }

  Future<void> _manualSync() async {
    await presentCommand(context, _controller.sync);
  }

  Future<void> _saveLinks() async {
    final saved = await presentCommand(context, _controller.save);
    if (mounted && saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: buildDetailAppBar(context, title: 'Link Strava bikes'),
      body: _buildBody(p),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_loading || _syncing) {
      return SizedBox(
        height: 240,
        child: Center(
          child: AppLoadingState(
              label: _syncing ? 'Syncing with Strava…' : 'Loading bikes…'),
        ),
      );
    }

    if (_stravaBikes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        children: [
          AppSectionLabel('Strava bikes'),
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
                    BikeIcon(size: AppIconSizes.compact, color: p.accentText),
                    const SizedBox(width: 6),
                    Text(
                      'No strava bikes'.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: p.inkDim),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add bikes under Settings → My Gear in the Strava app, then sync again.',
                  style: AppTextStyles.body.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: AppActionButton(
                      outlined: true,
                      icon: CupertinoIcons.arrow_clockwise,
                      label: 'Retry sync',
                      onPressed: _manualSync,
                    )),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
      children: [
        AppSectionLabel('Strava bikes'),
        ..._stravaBikes.map((strava) => _BikeMatchCard(
              strava: strava,
              appBikes: _appBikes,
              linkedId: _links[strava.stravaGearId],
              onChanged: (v) {
                _controller.link(strava.stravaGearId, v);
              },
            )),
        const SizedBox(height: 24),
        AppActionButton(
          icon: CupertinoIcons.link,
          label: 'Save links',
          onPressed: _saveLinks,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(CupertinoIcons.arrow_clockwise),
          label: const Text('Resync'),
          onPressed: _manualSync,
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
              Icon(CupertinoIcons.flame,
                  size: AppIconSizes.compact, color: p.accentText),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(
                'Strava bike mileage',
                style: AppTextStyles.caption.copyWith(color: p.inkDim),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(strava.name, style: AppTextStyles.label.copyWith(color: p.ink)),
          const SizedBox(height: 6),
          Text('$kmText km',
              style: AppTextStyles.body.copyWith(color: p.inkMuted)),
          const SizedBox(height: 12),
          Text(
            'Linked app bike'.toUpperCase(),
            style: AppTextStyles.caption.copyWith(color: p.inkDim),
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
    return AppSelect<String?>(
        label: 'Select app bike',
        value: value,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('Skip')),
          for (final bike in appBikes)
            DropdownMenuItem<String?>(value: bike.id, child: Text(bike.name))
        ],
        onChanged: onChanged);
  }
}
