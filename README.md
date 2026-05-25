# bikesetupapp
#### Description:
> Flutter App to Store Bike Setup Information in Google Firestore Database with Google SignIn

## Features
* Setup information linked to Google account (alternative: Anonymous SignIn)
* Multiple bikes (set default bike in settings)
* Multiple setups per bike
* Store basic setup information and view it in a bike information popup
* Quickly change and view frequently used settings via a card-based control panel grid
* Settings are divided into 5 categories (rear tyre, front tyre, shock, fork, general/frame)
* Easily switch categories via interactive schematic bubbles on the bike image
* Unlimited number of settings in each category
* Todo list to keep track of things that need fixing on your bike
* Settings page to log out, change theme, and set default bike
* Responsive layout: sidebar on wide screens (>= 768px), drawer on narrow screens

## Implementation Details

### database_service
Contains everything related to writing and retrieving data from Firebase and authenticating the user.

### app_services
Contains theme information (`AppTheme`, `AppStateNotifier`), responsive layout helpers (`ResponsiveLayout`), and page route transitions (`AppRoutes`).

### alert_dialogs
Contains all Alert Dialogs, grouped by domain: auth, bike, settings, todo.

### app_pages
Contains every full-screen page: `home_page`, `google_sign_in`, `drawer`, `settings_page`, `bike_selector_page`, `new_bike_page`, `todolist_page`.

### bike_enums
Contains the enums `BikeType`, `Category`, `NewBikeMode` used throughout the application.

### widgets
Contains reusable widgets used within pages and dialogs, including `SidebarContent`, `ControlPanelGrid`, `SchematicBubble`, `HomePageListView`, and others.

## App Flow

Upon launching, the app verifies whether the user is logged in and whether their default bike exists. If either condition is not met, the user is redirected to the login page. If both are met, the user is directed to the HomePage.

The HomePage displays a colored header panel with a bike schematic and interactive `SchematicBubble` widgets (one per category). Tapping a bubble switches the active category. Below the header, a `ControlPanelGrid` shows the current category's settings as cards — tapping a card opens a stepper bottom sheet to adjust the value.

On wide screens (>= 768 px) a persistent sidebar replaces the drawer. The sidebar shows the user's bike list, and footer actions for settings and adding a new bike.

The NavDrawer/sidebar allows bike and setup modification, deletion, and creation. Each bike has its own to-do list for tracking repairs.

The settings page lets users log in or out, change the theme, and set their default bike.

## Firebase

Each user has their own document referenced by their user ID under the `UserBikeSetup` collection. This document contains collections for `Bikes`, `ToDoList`, and stores the user's default bike. Each bike has a `SetupList` sub-collection for setup metadata, and per-setup sub-collections keyed by category (Fork, Shock, RearTire, FrontTire, GeneralSettings) for the actual settings key-value pairs.

## Deployment

The app is deployed to **GitHub Pages** at `https://simon-franke.github.io/bikesetupapp/`.
Pushing to `main` triggers the `Deploy to GitHub Pages` workflow automatically.

### Required GitHub secrets

Set these under **repo → Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `FIREBASE_OPTIONS` | `lib/firebase_options.dart` base64-encoded (`base64 < lib/firebase_options.dart`) |
| `STRAVA_CLIENT_ID` | Strava API client ID (currently `214695`) |
| `FIREBASE_TOKEN` | Firebase CI token — generate with `firebase login:ci` |

### Firebase Function (Strava OAuth proxy)

The `functions/` directory contains a Firebase Cloud Function (`stravaCallback`) that
handles the server-side Strava OAuth token exchange so the client secret never appears
in the web bundle.

**One-time setup:**
```bash
# Enable Secret Manager API at:
# https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=bikesetupapp-bd22a

# Store the Strava client secret in Google Cloud Secret Manager
firebase secrets:set STRAVA_CLIENT_SECRET

# Deploy the function
cd functions && npm install && cd ..
firebase deploy --only functions
```

The `deploy-functions` CI job deploys the function automatically on push once the
`FIREBASE_TOKEN` secret is set. Until then, deploy manually with the command above.

### Strava API settings

In the [Strava API dashboard](https://www.strava.com/settings/api) set:
```
Authorization Callback Domain: us-central1-bikesetupapp-bd22a.cloudfunctions.net
```

---

## Setup (after cloning)

Firebase config files are **not committed** to this repository (they contain API keys). You must generate them locally before running the app:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com) and enable Firestore + Google Sign-In.
2. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. Generate the config files:
   ```bash
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `macos/Runner/GoogleService-Info.plist`.
4. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

See `lib/firebase_options.dart.example` for the expected file structure.
