# Bike Setup App

Keep bike settings, saved setups, maintenance records, and repair to-dos in one place. Built with Flutter and Firebase, with optional Strava integration for bike mileage.

This project targets native apps. GitHub Pages hosting and the web platform have been removed.

## Run locally

Install Flutter and configure a Firebase project with Firestore and the sign-in methods you want to use.

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

Firebase configuration stays local and is not committed. The public Strava client ID defaults to the deployed backend's ID; override it with `--dart-define=STRAVA_CLIENT_ID=...` when using a matching backend. Strava authentication keeps `STRAVA_CLIENT_SECRET` in Cloud Secret Manager. Native code exchange uses `stravaExchange` and token renewal uses `stravaRefresh`. Deploy the functions before distributing a client update. `.env` is not loaded or bundled in any build. If a previous build included a client secret, rotate it in Strava and update Cloud Secret Manager.

## Contributing

Run the checks before opening a pull request:

```bash
flutter analyze --fatal-infos
flutter test
(cd functions && npm test)
```

Firestore ownership-rule tests require Node 22 and Java 21 or newer:

```bash
(cd test/firestore && npm ci)
npx --yes firebase-tools@15.18.0 emulators:exec --only firestore --project demo-bike-rules "npm --prefix test/firestore test"
```

GitHub Actions runs Flutter analysis, Flutter tests, Firestore ownership-rule tests, and Strava function tests. CI uses placeholder configuration and does not need Firebase or Strava credentials.

See [AGENTS.md](AGENTS.md) for architecture, development conventions, and deployment details.

## Layout

The app uses one phone layout at every window size. `PhoneViewport` caps the entire navigator at 480 logical pixels, including routes and bottom sheets. Text scaling and keyboard handling remain enabled.

## Code structure

Feature code lives in `lib/features/`, shared UI and infrastructure in `lib/common/`, and dependency wiring, startup and navigation in `lib/app/`. Features use a UI → controller → repository flow. See [AGENTS.md](AGENTS.md) for responsibilities, injection and tests.

## Strava integration

Strava credentials belong to the signed-in Firebase user. Historical service mileage requires access to all activities, including private rides. Sign-out clears that user's local credentials and sync timestamp without revoking access for other devices.

Pushes to `main` deploy Firebase Functions and Firestore rules only. To deploy functions manually before distributing a client update:

```bash
firebase deploy --only functions --project bikesetupapp-bd22a
```

`stravaRefresh` accepts the user's refresh token in a POST body, exchanges it using the server-side secret, and returns the rotated credentials with caching disabled.
