# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
| `lib/app_services/` | `AppStateNotifier` (theme) and `AppTheme` (light/dark `ThemeData`) |
| `lib/bike_enums/` | `BikeType` (DH, Enduro, Dirt, XC, Singlespeed, Road), `Category` (RearTire, FrontTire, Shock, Fork, GeneralSettings), `NewBikeMode` |

### Enums as Configuration
`BikeType` carries `hasShock` and `hasFork` booleans that control which `Bubble` widgets are shown on the home page. `Category.category` returns the exact Firestore document name used as the settings category.

### Home Page Layout
`MyHomePage` uses a `Stack` with a colored header panel containing bike image and interactive `Bubble` widgets (one per category). Below the header, a `HomePageListView` shows the currently selected category's settings as a stream from Firestore.
