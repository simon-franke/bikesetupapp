# Strava integration

- Native OAuth and refresh use `stravaExchange` and `stravaRefresh` in `backend/functions/` at the repository root. `STRAVA_CLIENT_SECRET` stays in Cloud Secret Manager; never bundle it in the client.
- Credentials belong to a Firebase UID. Preserve single-use OAuth state checks and sign-out cleanup; responses from a superseded session must not save credentials.
- Historical mileage requires `activity:read_all`. Credentials without that scope require reconnection, not a zero-mileage fallback.
