# App development

Paths below are relative to `app/` unless stated otherwise.

## Checks

CI uses Flutter 3.41.4 and Node 22:

```sh
flutter pub get --enforce-lockfile
flutter analyze --fatal-infos
flutter test
(cd ../backend/functions && npm test)
```

For tests without local Firebase configuration, copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and set `STRAVA_CLIENT_ID=ci-placeholder` in `.env`. Never overwrite existing local configuration.

## Architecture and data

- Features live in `lib/features/`; shared code in `lib/common/`. Wire dependencies in `lib/app/app_dependencies.dart`.
- UI obtains controllers through `AppDependencies.of(context)`. Controllers depend on repository contracts; Firebase access and Firestore conversions belong in repositories. `test/architecture_test.dart` enforces this.
- Use `CommandResult`, `OperationController`, and `WriteQueue` for commands and ordered writes; present failures with `presentCommand`. Async behavior is covered by `test/controller_async_test.dart`.
- Under `UserBikeSetup/{uid}`, setup metadata lives in `Bikes/{bikeId}/SetupList/{setupId}` and settings in `Bikes/{bikeId}/{setupId}/{category}`. `Category.category` is a stored name; changing it affects existing data.
- Setups require explicit field configuration; experiments require a captured setup snapshot. Do not add migrations for pre-release development data.
- Setting icons, units, and default fields belong in `lib/features/setups/ui/field_meta.dart`.

## UI and integrations

- Before any UI or routing change, read `lib/common/ui/AGENTS.md`; its shared component and transition rules apply across all features.
- The app uses a phone layout capped at 480 logical pixels by `lib/common/layout/phone_viewport.dart`. Do not add tablet or desktop layouts. Preserve text scaling and keyboard handling; see `test/phone_viewport_test.dart`.
- `bike_chooser_sheet.dart` is the single bike/setup chooser. No drawer, sidebar, or inline setting editors; setting editors use bottom sheets.
- For Strava or its authentication/session integration, read `lib/features/strava/AGENTS.md`.
- This project is native-only. Do not restore web platform files, hosting, or browser-specific authentication. Firebase options and the Strava client ID are configured locally; deployment rules live in `../backend/AGENTS.md`.
