# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## CI/CD

`.github/workflows/ci.yml` runs separate **Flutter lint** and **Flutter tests**
checks for pull requests targeting `main`, pushes to `main`, and manual runs.
Both use Flutter 3.41.4, enforce `pubspec.lock`, and use placeholder Firebase
options and a placeholder `.env` so checks do not need repository secrets.
Lint runs `flutter analyze --fatal-infos`; tests run `flutter test` and the
Strava web callback tests in Chrome. A separate Node 22 job runs the Strava function tests.

The app deploys to **GitHub Pages** (`https://simon-franke.github.io/bikesetupapp/`) via
`.github/workflows/deploy.yml` on every push to `main`. The workflow has three jobs:

| Job | What it does | Required secret |
|---|---|---|
| `build` | `flutter build web --base-href /bikesetupapp/` | `FIREBASE_OPTIONS`, `STRAVA_CLIENT_ID` |
| `deploy` | Publishes `build/web` to GitHub Pages | — |
| `deploy-functions` | `firebase deploy --only functions` | `FIREBASE_TOKEN` |

`FIREBASE_OPTIONS` is `lib/firebase_options.dart` base64-encoded.
`FIREBASE_TOKEN` is generated with `firebase login:ci`.

### Firebase Function

`functions/index.js` exports 2nd-gen Cloud Functions (`stravaCallback` and
`stravaRefresh`). `stravaCallback` acts as the
Strava OAuth proxy on web. It receives the authorization code from Strava, exchanges it
for tokens using `STRAVA_CLIENT_SECRET` (stored in Google Cloud Secret Manager, never
in the web bundle), then redirects back to the app with the token payload base64url-encoded
in `?strava_auth=` with the original state in `?strava_state=`.
`stravaRefresh` accepts a refresh token in a POST body and renews credentials
server-side using the same secret; browser CORS permits the production Pages origin.
The handlers live in `functions/strava_handlers.js`; `npm test` runs their tests.

To redeploy the function manually:
```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

### Strava web OAuth flow

On web, "Connect Strava" navigates the browser tab to Strava's auth page with the
Firebase Function URL as the redirect URI. After the user authorizes:

1. Strava → Firebase Function (`stravaCallback`)
2. Function exchanges code → tokens (server-side)
3. Function → redirects to `https://simon-franke.github.io/bikesetupapp/?strava_auth=<base64url>&strava_state=<state>`
4. `main()` calls `handleStravaWebCallback(userId: user?.uid)` which validates the initiating tab's single-use state (ten-minute expiry) and user, saves UID-scoped tokens and granted scopes, and strips the callback parameters
5. If a new auth was detected and the user is signed in, Strava bikes are auto-synced

On mobile the existing `FlutterWebAuth2` / custom-scheme flow also validates OAuth state.
Both platforms request `activity:read_all`; historical mileage refuses unknown or
partial activity scopes. Legacy unscoped credentials require reconnection.
Sign-out clears local credentials and the sync timestamp for the active UID.

Key files:
- `lib/features/strava/platform/strava_web_callback.dart` — web implementation (conditional import)
- `lib/features/strava/platform/strava_web_callback_stub.dart` — mobile/desktop stub
- `lib/features/strava/repositories/strava_auth_service.dart` — `authorizeWeb()` / `buildWebAuthUrl()`
- `functions/index.js` — Firebase Function

## Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build
flutter build apk        # Android
flutter build ios        # iOS

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture

This is a Flutter app for storing bike setup data in Firebase Firestore, with Google Sign-In or anonymous authentication.

### State Management
- **Provider** supplies `AppDependencies` and the global theme state: dark/light theme via `AppStateNotifier` (`lib/features/settings/controllers/app_state_notifier.dart`). Theme preference is persisted with `SharedPreferences`.
- Feature controllers own commands and async state; UI consumes controller state and typed repository streams. Controllers receive repository contracts through constructor injection. Screen controllers are disposed by their owning widgets.

### App Startup Flow (`lib/main.dart`)
On launch, the app reads `AuthController.currentUser`. If signed in, `StartupController` resolves the user's default bike and setup through injected bikes and setups repository contracts. If all required data is present, the app opens `MyHomePage`; otherwise it redirects to `LoginPage`.

### Firestore Data Model
All data lives under the `UserBikeSetup` collection, keyed by `userID`:

```
UserBikeSetup/{userID}
  default_bike: String (bikeID)
  Bikes/{uBikeID}
    bike_name, bike_type, defaultSetup
    SetupList/{uSetupID}        ← setup metadata + setup_information fields
    {uSetupID}/{category}       ← settings key-value pairs (e.g. Fork, Shock, RearTire, FrontTire, GeneralSettings)
```

`lib/features/*/repositories/` owns persistence. Firestore implementations are injected by `AppDependencies` in `lib/app/app_dependencies.dart`; UI must not construct repositories or access Firebase singletons. Models use plain maps and DateTime values; Firestore snapshot and timestamp conversion stays in repositories. See `docs/architecture.md`.

### Key Modules

| Directory | Purpose |
|---|---|
| `lib/features/` | Feature modules: auth, bikes, setups, maintenance, Strava, settings and workspace |
| `lib/features/*/ui/` | Pages, feature widgets and dialogs |
| `lib/features/*/controllers/` | Feature commands, screen state, async coordination and subscription ownership |
| `lib/features/*/repositories/` | Persistence contracts and Firestore, OAuth/HTTP or preference implementations |
| `lib/features/*/models/` | Typed models, enums and domain value logic |
| `lib/common/` | Shared Material controls, theme, responsive layout, async controller utilities and Firestore codecs |
| `lib/app/` | Dependency composition, startup orchestration and navigation transitions |

Controllers depend on repository contracts, never concrete persistence implementations or UI. UI reads `AppDependencies.of(context)` and invokes feature controllers. `test/architecture_test.dart` enforces import boundaries. Successful sign-out disposes cached user controllers; screens dispose their own controllers.

Commands return `CommandResult<T>` (success, expected failure, or cancellation).
`OperationController` owns activity, exceptions/stacks, named request generations,
shared in-flight commands and disposal checks; `WriteQueue` orders persistence.
Keep state private and expose read-only getters/collections. Translate known
adapter failures to `AppFailure` in repositories; UI owns messages via
`failureMessage` / `presentCommand`. Unexpected exceptions retain their stacks.
`ServiceEditorController` owns service drafts, stable retry IDs and save state;
widgets own form input and navigation. Pure model rules cover setup defaults,
bike-link suggestions and deferred mileage. See `test/controller_async_test.dart`
and `test/controller_domain_rules_test.dart`.

### Enums as Configuration
`BikeType` carries `hasShock` and `hasFork` booleans that control which `SchematicBubble` widgets are shown on the home page. `Category.category` returns the exact Firestore document name used as the settings category.

### Home Page Layout
`MyHomePage` uses `SetupWorkspace` to place the interactive bike diagram beside `ControlPanelGrid` when each half of the available content width has room for a 440px diagram or 384px of settings (scaled with text size), whichever needs more room. Smaller windows stack the diagram above the settings. Enlarged text also switches to the stacked layout.

### Responsive Layout
- `lib/common/layout/responsive_layout.dart` provides `AppContentFrame`, `SetupWorkspace` and `ResponsiveCardGrid`.
- Home content and toolbar use the full window width with 24px tablet insets; other default content frames are capped at 1440px; Settings uses 700px and sign-in 440px.
- Setup retains the original transparent bike image and schematic callouts. On both phones and tablets the diagram has no background fill; the bike is tinted with `palette.inkMuted` using `BlendMode.srcIn`, while hotspot borders and leader lines use theme-specific contrast colors. The diagram and inspector each occupy exactly half of the workspace width, with the divider at the center and 24px padding inside the inspector. The diagram fills the workspace height, with the bike centered vertically and callouts positioned around the image, beside an inspector with a compact selected-setting ruler editor with inline unit selection, tap-to-type input and automatic saves when scrolling settles above the same tiles used on phones. The inspector remembers the selected field per bike/setup/category. In tall windows the editor stays pinned while tiles scroll; shorter windows and enlarged text scroll the inspector as a whole. Phones retain their tile grid and modal editor. Tablet settings use compact name/value rows; phones retain cards.
- At 768px and above, navigation moves into the toolbar and Add component appears in the service header. Narrow windows retain a separate navigation row and the service FAB.
- Service cards use two natural-height columns when there is enough room; single cards and the final card in odd-sized groups span the full width. Enlarged text falls back to one column.
- There is no drawer or persistent sidebar. Use available window width, including Split View, rather than device type.
- `test/responsive_layout_test.dart` covers tablet orientations, Split View, phone sign-in and enlarged text.
- The bike title opens `lib/features/bikes/ui/bike_chooser_sheet.dart`, the sole bike/setup chooser.
- The chooser uses a content-sized centered dialog on wide windows and a bottom sheet on phones, limited to 560px wide. Long lists scroll above the fixed Add bike action. It marks the current setup by document ID and provides Add bike, Add setup, editing, and current setup details.
- The header Settings icon opens `SettingsPage` directly.

### Page Transitions
- `lib/app/routing/app_routes.dart` — `AppRoutes.fadeSlide()` replaces `MaterialPageRoute` everywhere
- 280ms fade + 6% vertical slide in, 200ms out

### Animations
- **Bubbles** (`lib/features/setups/ui/home_page_bubbles.dart`): tablet callouts use 112×64px at default text size; dimensions scale with text. All callouts show anchors and leader lines: selected lines are solid and orange, others dashed in a theme-specific neutral. Lines have a background halo to remain visible over the bike. Tap shrink 120ms (scale 1.0→0.97), select pop 180ms (scale 1.0→1.03), animated color 180ms; leader line drawn with `CustomPainter`
- **ControlPanelGrid cards** (`lib/features/setups/ui/control_panel_grid.dart`): staggered fade+scale-in on load (300ms, 60ms per-card offset)
- **Hero**: bike image tagged `'bike-image-${bikeType.path}'` — `home_page.dart` ↔ `bike_selector_widget.dart`

### Field Metadata (`lib/features/setups/ui/field_meta.dart`)
`kFieldMeta` maps setting keys (e.g. `'Pressure'`, `'Rebound'`) to `FieldMeta(icon, unit)`. `kDefaultFieldKeys` maps each category to its default field list. `ControlPanelGrid` uses these to render cards with the correct icon and unit without any per-field conditionals.

### Key Widget Files

| File | Purpose |
|---|---|
| `lib/features/setups/ui/control_panel_grid.dart` | Phone tiles with modal editing; tablet tiles with a persistent selected-setting editor |
| `lib/features/setups/ui/inline_setting_editor.dart` | Tablet editor presentation; `SettingSaveController` owns ordered saves and retry state |
| `lib/features/setups/ui/home_page_bubbles.dart` | `SchematicBubble` — anchor dot + leader line + floating card |
| `lib/features/bikes/ui/bike_chooser_sheet.dart` | Single bike/setup chooser and Add bike action |
| `lib/features/bikes/ui/bike_selector_widget.dart` | Bike selection widget with Hero image |
| `lib/features/bikes/ui/bike_list.dart` | Scrollable bikes and setups with management actions |
| `lib/features/bikes/ui/setup_choice_tile.dart` | Current setup marker, selection, editing, and details actions |
| `lib/features/setups/ui/field_meta.dart` | Icon/unit metadata and default field keys per category |

## Shared UI and contrast

Use Flutter Material controls styled by `AppTheme` in
`lib/common/theme/theme_data.dart`; do not add a second UI component library.
`lib/common/ui/app_components.dart` provides app compositions for action buttons,
text fields, field labels and section labels. Reuse these for new forms and
screens. Domain widgets such as `SetupChoiceTile` and `ServiceComponentCard`
compose the same Material controls.

- Orange button fills use `palette.accent` with `palette.accentInk`.
- Orange foreground text/icons use `palette.accentText`, which differs by theme.
- Secondary and supporting text use `inkMuted` / `inkDim` without reducing opacity.
- Status colors are theme-specific foreground colors. For solid status fills,
  use `AppColors.onColor(fill)` for the foreground.
- Form decorations and button sizing/radii are defined in the theme; avoid
  per-screen copies. Interactive outlines use `borderStrong`; decorative
  dividers use `border`.
- `test/contrast_test.dart` checks 4.5:1 text contrast on base and selected
  surfaces and 3:1 control-outline contrast in both themes.

- Forms use `showAdaptiveModal` from `lib/common/ui/adaptive_modal.dart`: centered, scrollable, keyboard-aware dialogs on wide windows, bottom sheets on phones.
