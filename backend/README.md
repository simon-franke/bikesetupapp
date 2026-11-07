# Clickwise backend

Firebase services used by the [Clickwise app](../app/README.md). Run Firebase commands from this directory.

- `functions/`: native Strava OAuth exchange and refresh, plus account deletion.
- `firestore.rules`: ownership and access rules for user data.
- `test/firestore/`: emulator tests for the production rules.
- `firebase.json`: deployment and emulator configuration.

## Local checks

Use Node 22. From `backend/`:

```sh
(cd functions && npm ci && npm test)
```

Firestore rules tests also need Java 21 or newer:

```sh
(cd test/firestore && npm ci)
npx --yes firebase-tools@15.18.0 emulators:exec --only firestore --project demo-bike-rules "npm --prefix test/firestore test"
```

The demo project runs locally and does not require production credentials.

## Deployment

Pushes to `main` affecting `backend/` or the deployment workflow deploy Functions and Firestore rules using the `FIREBASE_TOKEN` GitHub secret. Manual deployment, with access to the configured Firebase project:

```sh
firebase deploy --only functions,firestore:rules --project bikesetupapp-bd22a
```

`STRAVA_CLIENT_SECRET` belongs in Cloud Secret Manager. The client ID can be supplied to the app, but the client secret must never be included in a client build. Preserve Firebase UID ownership, single-use OAuth state checks and sign-out cleanup when changing authentication.

Deploy account deletion and its matching Firestore rules together. See the [store release notes](../app/docs/store-release.md) for the remaining account and publication requirements.
