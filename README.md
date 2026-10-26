# Bike Setup App

Keep bike settings, saved setups, maintenance records, and repair to-dos in one place. Built with Flutter and Firebase, with optional Strava integration for bike mileage.

[Open the app](https://simon-franke.github.io/bikesetupapp/)

## Run locally

Install Flutter and configure a Firebase project with Firestore and the sign-in methods you want to use.

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

Firebase configuration stays local and is not committed. The public Strava client ID defaults to the deployed backend's ID; override it with `--dart-define=STRAVA_CLIENT_ID=...` when using a matching backend. Both native and web authentication keep `STRAVA_CLIENT_SECRET` in Cloud Secret Manager. Native code exchange uses `stravaExchange`, web callbacks use `stravaCallback`, and both refresh through `stravaRefresh`. Deploy the functions before distributing a client update. `.env` is not loaded or bundled in any build. If a previous build included a client secret, rotate it in Strava and update Cloud Secret Manager.

## Contributing

Run the checks before opening a pull request:

```bash
flutter analyze --fatal-infos
flutter test
flutter test --platform chrome test/strava_web_callback_test.dart
(cd functions && npm test)
```

GitHub Actions runs Flutter analysis, standard and browser tests, and the Strava function tests on pull requests. CI uses placeholder configuration and does not need Firebase or Strava credentials.

See [AGENTS.md](AGENTS.md) for architecture, development conventions, and deployment details.

## Code structure

Feature code lives in `lib/features/`, shared UI and infrastructure in `lib/common/`, and dependency wiring, startup and navigation in `lib/app/`. Features use a UI → controller → repository flow. See [AGENTS.md](AGENTS.md) for responsibilities, injection and tests.

## Strava connection changes

Existing unscoped Strava credentials are intentionally ignored because their owning app user cannot be verified. Users must reconnect Strava once after upgrading and grant access to all activities, including private rides, for historical service mileage. Sign-out clears the active user's local Strava credentials and sync timestamp without revoking access for other devices.

Deploy both Firebase functions before releasing the updated web app:

```bash
firebase deploy --only functions --project bikesetupapp-bd22a
```

`stravaRefresh` accepts the user's refresh token in a POST body, exchanges it using the server-side secret, and returns the rotated credentials with caching disabled. Its browser CORS policy allows the production GitHub Pages origin.
