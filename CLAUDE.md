# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CI/CD

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

`functions/index.js` — a 2nd-gen Cloud Function (`stravaCallback`) that acts as the
Strava OAuth proxy on web. It receives the authorization code from Strava, exchanges it
for tokens using `STRAVA_CLIENT_SECRET` (stored in Google Cloud Secret Manager, never
in the web bundle), then redirects back to the app with the token payload base64url-encoded
in `?strava_auth=`.

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
3. Function → redirects to `https://simon-franke.github.io/bikesetupapp/?strava_auth=<base64url>`
4. `main()` calls `handleStravaWebCallback()` which saves the tokens and strips the URL param
5. If a new auth was detected and the user is signed in, Strava bikes are auto-synced

On mobile the existing `FlutterWebAuth2` / custom-scheme flow is unchanged.

Key files:
- `lib/strava_web_callback.dart` — web implementation (conditional import)
- `lib/strava_web_callback_stub.dart` — mobile/desktop stub
- `lib/database_service/strava_auth_service.dart` — `authorizeWeb()` / `buildWebAuthUrl()`
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
- **Provider** is used for a single piece of global state: dark/light theme via `AppStateNotifier` (`lib/app_services/app_state_notifier.dart`). Theme preference is persisted with `SharedPreferences`.
- All other state is passed down as constructor arguments or read directly from Firestore streams.

### App Startup Flow (`lib/main.dart`)
On launch, the app checks `FirebaseAuth.instance.currentUser`. If signed in, it fetches the user's default bike and setup from Firestore. If all required data is present, the app opens `MyHomePage`; otherwise it redirects to `LoginPage`.

### Firestore Data Model
All data lives under the `UserBikeSetup` collection, keyed by `userID`:

```
UserBikeSetup/{userID}
  default_bike: String (bikeID)
  Bikes/{uBikeID}
    bike_name, bike_type, defaultSetup
    SetupList/{uSetupID}        ← setup metadata + setup_information fields
    {uSetupID}/{category}       ← settings key-value pairs (e.g. Fork, Shock, RearTire, FrontTire, GeneralSettings)
  ToDoList/{uBikeID}/MyList/{docID}  ← todo items
```

`DatabaseService` (`lib/database_service/database.dart`) is the sole point of contact with Firestore — instantiated with `DatabaseService(userID)`.

### Key Modules

| Directory | Purpose |
|---|---|
| `lib/database_service/` | `DatabaseService` (Firestore CRUD) and `AuthService` (Google/anonymous sign-in) |
| `lib/app_pages/` | Full-screen pages: `home_page`, `google_sign_in`, `drawer`, `settings_page`, `bike_selector_page`, `new_bike_page`, `todolist_page` |
| `lib/alert_dialogs/` | All `showDialog` calls grouped by domain: auth, bike, settings, todo |
| `lib/widgets/` | Reusable widgets used within pages and dialogs |
| `lib/app_services/` | `AppStateNotifier` (theme), `AppTheme` (light/dark `ThemeData`), `ResponsiveLayout`, `AppRoutes` |
| `lib/bike_enums/` | `BikeType` (DH, Enduro, Dirt, XC, Singlespeed, Road), `Category` (RearTire, FrontTire, Shock, Fork, GeneralSettings), `NewBikeMode` |

### Enums as Configuration
`BikeType` carries `hasShock` and `hasFork` booleans that control which `SchematicBubble` widgets are shown on the home page. `Category.category` returns the exact Firestore document name used as the settings category.

### Home Page Layout
`MyHomePage` uses a `Stack` with a colored header panel containing the bike image and interactive `SchematicBubble` widgets (one per category). Below the header, a `ControlPanelGrid` shows the currently selected category's settings as tappable cards streamed from Firestore.

### Responsive Layout
- `lib/app_services/responsive_layout.dart` — `kWideBreakpoint = 768px`, `sidebarWidth = 300`
- Wide (>= 768px): `Row(SidebarContent 300px + VerticalDivider + Expanded content)`
- Narrow (< 768px): standard `Scaffold` with `drawer: NavDrawer(...)`
- `lib/widgets/sidebar_content.dart` — shared drawer/sidebar body (`isInDrawer` flag controls pop-on-navigate behavior)

### Page Transitions
- `lib/app_services/app_routes.dart` — `AppRoutes.fadeSlide()` replaces `MaterialPageRoute` everywhere
- 280ms fade + 6% vertical slide in, 200ms out

### Animations
- **Bubbles** (`lib/widgets/home_page_bubbles.dart`): tap shrink 120ms (scale 1.0→0.88), select pop 180ms (scale 1.0→1.12), `AnimatedContainer` color/border 250ms; leader line drawn with `CustomPainter`
- **ControlPanelGrid cards** (`lib/widgets/control_panel_grid.dart`): staggered fade+scale-in on load (300ms, 60ms per-card offset)
- **Hero**: bike image tagged `'bike-image-${bikeType.path}'` — `home_page.dart` ↔ `bike_selector_widget.dart`

### Field Metadata (`lib/widgets/field_meta.dart`)
`kFieldMeta` maps setting keys (e.g. `'Pressure'`, `'Rebound'`) to `FieldMeta(icon, unit)`. `kDefaultFieldKeys` maps each category to its default field list. `ControlPanelGrid` uses these to render cards with the correct icon and unit without any per-field conditionals.

### Key Widget Files

| File | Purpose |
|---|---|
| `lib/widgets/control_panel_grid.dart` | Grid of setting cards with stepper bottom sheet for editing |
| `lib/widgets/home_page_bubbles.dart` | `SchematicBubble` — anchor dot + leader line + floating card |
| `lib/widgets/homepage_list_view.dart` | List view of settings (`topPadding`: 0 wide, 45 narrow) |
| `lib/widgets/sidebar_content.dart` | Shared sidebar/drawer body |
| `lib/widgets/bike_selector_widget.dart` | Bike selection widget with Hero image |
| `lib/widgets/drawer_bike_list.dart` | Scrollable bike list inside sidebar |
| `lib/widgets/field_meta.dart` | Icon/unit metadata and default field keys per category |
| `lib/widgets/default_bike_selector_widget.dart` | Widget for choosing default bike in settings |
| `lib/widgets/setup_information_alert_content.dart` | Content for setup info dialog |
| `lib/widgets/setup_information_list_element.dart` | Single row in setup info list |
