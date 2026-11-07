# Backend development

Use Node 22. Run `npm test` from `functions/`. See `README.md` for the Firestore emulator checks and deployment commands.

Preserve Firebase UID ownership, single-use OAuth state checks, sign-out cleanup, and the account-deletion marker protections. Keep the Strava secret in Cloud Secret Manager, never in the app or repository.

Firebase configuration and rules paths are relative to this directory. CI workflows live in `../.github/workflows/`. After all CI checks pass, pushes to `main` affecting this directory or either CI/deployment workflow deploy Functions and rules. To deploy manually, run `Flutter CI` on `main`; it runs the same checks first.

Deployment workflow: `.github/workflows/deploy.yml` at the repository root. Deployment secret: `FIREBASE_TOKEN`. `STRAVA_CLIENT_SECRET` belongs in Cloud Secret Manager, never client configuration.
