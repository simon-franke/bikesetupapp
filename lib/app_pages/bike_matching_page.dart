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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ServiceDatabaseService(widget.user.uid);
    final appDb = DatabaseService(widget.user.uid);

    final stravaBikesStream = db.getStravaBikes();
    final appBikesStream = appDb.getBikes();

    final stravaBikes = await stravaBikesStream.first;
    final appBikesSnap = await appBikesStream.first;

    final appBikes = (appBikesSnap as dynamic)
        .docs
        .map<Bike>((doc) => Bike.fromSnapshot(doc))
        .toList();

    // Pre-fill existing links and auto-match by name similarity
    for (final strava in stravaBikes) {
      if (strava.linkedBikeId != null) {
        _links[strava.stravaGearId] = strava.linkedBikeId;
      } else {
        // Try auto-match by name
        final stravaLower = strava.name.toLowerCase();
        for (final app in appBikes) {
          if (app.name.toLowerCase().contains(stravaLower) ||
              stravaLower.contains(app.name.toLowerCase())) {
            _links[strava.stravaGearId] = app.id;
            break;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _stravaBikes = stravaBikes;
        _appBikes = appBikes;
        _loading = false;
      });
    }
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
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _stravaBikes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No Strava bikes found.\nSync your Strava account first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
