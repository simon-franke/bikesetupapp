# Repository notes

## Checks

CI uses Flutter 3.41.4 and Node 22. Run:

```sh
flutter pub get --enforce-lockfile
flutter analyze --fatal-infos
flutter test
flutter test --platform chrome test/strava_web_callback_test.dart
(cd functions && npm test)
```

Without local Firebase configuration, use `lib/firebase_options.dart.example`
as `lib/firebase_options.dart` and set `STRAVA_CLIENT_ID=ci-placeholder` in
`.env` for tests. Do not overwrite existing local configuration.

## Code conventions

- Features live in `lib/features/`; shared code in `lib/common/`.
  Wire dependencies in `lib/app/app_dependencies.dart`.
- UI gets controllers through `AppDependencies.of(context)`. Controllers depend
  on repository contracts. Keep Firebase access and Firestore conversions in
  repositories. `test/architecture_test.dart` checks these boundaries.
- Use `CommandResult`, `OperationController` and `WriteQueue` for commands,
  async state and ordered writes. Present failures with `presentCommand`.
  See `test/controller_async_test.dart` for expected behavior.
- Firestore setup metadata lives in `Bikes/{bikeId}/SetupList/{setupId}`;
  settings live separately in `Bikes/{bikeId}/{setupId}/{category}`.
  Both are under `UserBikeSetup/{uid}`. `Category.category` supplies the stored
  category name; changing it affects existing data.
- Setting icons, units and default fields belong in
  `lib/features/setups/ui/field_meta.dart`.

## UI

- Use `AppTheme`, controls from `lib/common/ui/app_components.dart`,
  `showAdaptiveModal` for forms and `AppRoutes.fadeSlide()` for routes.
- Orange fills use `accent` with `accentInk`; orange text/icons use `accentText`.
  Use `inkMuted`/`inkDim` without reduced opacity. Contrast is tested in
  `test/contrast_test.dart`.
- Layout follows available window width and text scale. Use the helpers in
  `lib/common/layout/responsive_layout.dart`; check `test/responsive_layout_test.dart`.
- `bike_chooser_sheet.dart` is the single bike/setup chooser. There is no drawer
  or sidebar. Phones use modal setting editors; wide layouts use the inline editor.

## Strava and deployment

- Web OAuth and refresh go through `stravaCallback` and `stravaRefresh` in
  `functions/`. `STRAVA_CLIENT_SECRET` stays in Cloud Secret Manager for web;
  never bundle it in the web app.
- Credentials belong to a Firebase UID. Preserve single-use OAuth state checks,
  the ten-minute expiry and sign-out cleanup. Historical mileage requires
  `activity:read_all`; unscoped credentials require reconnection.
- Every push to `main` deploys Firebase Functions and GitHub Pages via
  `.github/workflows/deploy.yml`. Web builds require `--base-href /bikesetupapp/`.
- Deployment secrets: `FIREBASE_OPTIONS` (base64-encoded
  `lib/firebase_options.dart`), `STRAVA_CLIENT_ID` and `FIREBASE_TOKEN`.
