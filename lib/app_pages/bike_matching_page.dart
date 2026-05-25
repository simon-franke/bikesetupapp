import 'package:bikesetupapp/app_services/strava_sync_service.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/bike.dart';
import 'package:bikesetupapp/models/strava_bike.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Nothing in Firestore — trigger a Strava sync and re-read.
    if (stravaBikes.isEmpty && syncIfEmpty) {
      if (mounted) setState(() => _syncing = true);
      await StravaSyncService(db).sync();
      stravaBikes = await db.getStravaBikes().first;
      if (mounted) setState(() => _syncing = false);
    }

    // Pre-fill existing links and auto-match by name similarity.
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
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'Link Strava Bikes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: _loading || _syncing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: 16),
                  Text(
                    _syncing ? 'Syncing with Strava…' : 'Loading…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : _stravaBikes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bike_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bikes found on your Strava account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure bikes are added under\nSettings → My Gear in the Strava app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _manualSync,
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('Retry sync'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Match your Strava bikes to your app bikes:',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    ..._stravaBikes.map((strava) {
                      final kmText =
                          '${(strava.distanceKm).round().toString()} km';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      strava.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    kmText,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String?>(
                                initialValue: _links[strava.stravaGearId],
                                hint: Text(
                                  'Select app bike',
                                  style:
                                      Theme.of(context).textTheme.labelSmall,
                                ),
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.color ??
                                          Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.color ??
                                          Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Skip'),
                                  ),
                                  ..._appBikes.map((app) =>
                                      DropdownMenuItem<String?>(
                                        value: app.id,
                                        child: Text(app.name),
                                      )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _links[strava.stravaGearId] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .floatingActionButtonTheme
                              .backgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveLinks,
                        child: Text(
                          'Save Links',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
