# App development notes

All paths and commands below are relative to `app/`, except `.github/`, which is at the repository root.

## Checks

CI uses Flutter 3.41.4 and Node 22. Run:

```sh
flutter pub get --enforce-lockfile
flutter analyze --fatal-infos
flutter test
(cd ../backend/functions && npm test)
```

Without local Firebase configuration, use `lib/firebase_options.dart.example`
as `lib/firebase_options.dart` and set `STRAVA_CLIENT_ID=ci-placeholder` in
`.env` for tests. Do not overwrite existing local configuration.

## Shared debug session

- Preserve the user's VS Code debug session; never stop or replace its app process.
- Reuse an existing tooling connection for inspection when available. Ask before
  hot restart or resetting app state.
- Run tests separately; use another device instance if they relaunch the
  app. Only stop processes started exclusively for your own tests.

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
- Setups require explicit field configuration, and experiments require a captured
  setup snapshot. Do not add migrations for pre-release development data.
- Setting icons, units and default fields belong in
  `lib/features/setups/ui/field_meta.dart`.

## UI

- Use `AppTheme`, controls from `lib/common/ui/app_components.dart`,
  `showAppSheet` for forms and `AppRoutes.fadeSlide()` for routes.
- Orange fills use `accent` with `accentInk`; orange text/icons use `accentText`.
  Use `inkMuted`/`inkDim` without reduced opacity. Contrast is tested in
  `test/contrast_test.dart`.
- The entire app uses the phone layout, capped at 480 logical pixels by
  `lib/common/layout/phone_viewport.dart`. Preserve text scaling and keyboard
  handling; do not add tablet or desktop layouts. Check `test/phone_viewport_test.dart`.
- `bike_chooser_sheet.dart` is the single bike/setup chooser. There is no drawer,
  sidebar or inline editor. All setting editors open as bottom sheets.
- Make hierarchy clear with minimal content and grouping. Every label, container
  and decoration should serve a purpose; reconsider layout when removing content.
- Use consistent alignment, spacing and visual language. Preserve the app's
  character while making components feel like parts of one coherent design.
- Keep copy short, direct and conversational. Explain only what is not already
  apparent from the interface. Never use em dashes.
- Choose controls that fit the value, precision and frequency of use. Make
  choices easy to compare and selected states unmistakable.
- Minimize effort with sensible defaults and grouped, relevant inputs. Preserve
  user edits and context as choices change; avoid unnecessary steps or disclosure.
- Use subtle motion and feedback to clarify changes and maintain continuity,
  without distracting from the task or making the interface feel unstable.

## Screen transitions

- Use `AppTactileButton.isLoading` for pending primary actions, with a short
  `loadingLabel`. Use `AppLoadingState` for a page/section that has no content yet.
  Both share the clicking logo in `app_loading.dart`; keep existing content in
  place during writes, and never delay completion to finish an animation cycle.
- Use `AppRoutes.fadeSlide()` for pushed pages; preserve native iOS back gestures.
- Use `AppScreenTransition` with stable state keys when replacing screens
  (for example workspace and no-bikes), rather than adding a navigation route.
  It fades through the page background so unrelated layouts do not overlap.
  Keep outgoing widget ancestry stable until dismissal; do not remount screens
  to disable their input. Inspect intermediate frames, not only settled screens.
- Timing and curves live in `lib/app/routing/app_motion.dart`. Do not invent
  durations per screen. Respect Reduced Motion.
- Use `showAppSheet` for sheets. Its future completes after dismissal finishes.
  If a sheet action changes the underlying screen, await `dismissAppSheet`
  before applying that change; capture callbacks before the sheet is disposed.
- When the next screen's data is already available, update synchronously instead
  of briefly rendering a loading screen between known states.
- Destructive confirmations that run a command stay visible until it completes,
  with progress and retry in the same sheet. Remove any covered chooser when
  the command starts, so live deletions cannot expose an empty intermediate sheet.

## Strava and deployment

- Native Strava OAuth and refresh use `stravaExchange` and `stravaRefresh` in
  `../backend/functions/`. `STRAVA_CLIENT_SECRET` stays in Cloud Secret Manager; never
  bundle it in a client build.
- Credentials belong to a Firebase UID. Preserve single-use OAuth state checks,
  and sign-out cleanup. Historical mileage requires
  `activity:read_all`; unscoped credentials require reconnection.
- Pushes to `main` that change `../backend/` or the deployment workflow deploy Firebase Functions and Firestore rules via
  `.github/workflows/deploy.yml`. This is a native-only project; do not restore
  web platform files, hosting, or browser-specific authentication.
- Deployment secret: `FIREBASE_TOKEN`. Firebase options and the Strava client ID
  are configured locally for client builds.
