# Bike Setup App

Keep bike settings, saved setups, maintenance records, and repair to-dos in one place. Built with Flutter and Firebase, with optional Strava integration for bike mileage.

[Open the app](https://simon-franke.github.io/bikesetupapp/)

## Run locally

Install Flutter and configure a Firebase project with Firestore and the sign-in methods you want to use.

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
touch .env
flutter run
```

Firebase configuration and `.env` are local files and are not committed. Add Strava credentials to `.env` if you need the integration.

## Contributing

Run the checks before opening a pull request:

```bash
flutter analyze --fatal-infos
flutter test
```

GitHub Actions runs both checks on pull requests. CI uses placeholder configuration and does not need Firebase or Strava credentials.

See [AGENTS.md](AGENTS.md) for architecture, development conventions, and deployment details.

## Code structure

Feature code lives in `lib/features/`, shared UI and infrastructure in `lib/common/`, and dependency wiring, startup and navigation in `lib/app/`. Features use a UI → controller → repository flow. See [the architecture guide](docs/architecture.md) for responsibilities, injection and tests.
