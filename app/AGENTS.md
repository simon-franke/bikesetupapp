# App development

Paths below are relative to `app/` unless stated otherwise.

## Checks

Use the toolchain versions specified by CI. Run:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos
flutter test
(cd ../backend/functions && npm test)
```

Follow the repository setup documentation for local test configuration. Never overwrite existing local configuration or credentials.

## Development rules

- Keep presentation separate from persistence and external services. Reuse existing shared behavior instead of creating competing implementations.
- Preserve write ordering where operations depend on one another, and surface failures to the user.
- Do not add migrations for pre-release development data.

## Product constraints

- Before UI or routing changes, read `lib/common/ui/AGENTS.md`.
- Design for phones only; do not add tablet or desktop layouts. Preserve text scaling and keyboard handling.
- Keep one consistent bike/setup chooser. No drawer, sidebar, or inline setting editors; setting editors use bottom sheets.
- For Strava or its authentication/session integration, read `lib/features/strava/AGENTS.md`.
- This project is native-only. Do not add web platform support, hosting, or browser-specific authentication.
- Follow `../backend/AGENTS.md` for backend and deployment work.
