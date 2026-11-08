# Strava integration

- Keep OAuth client secrets server-side in managed secret storage, never in the client or repository.
- Scope credentials to the authenticated user. Preserve single-use OAuth state checks and sign-out cleanup; responses from a superseded session must not save credentials.
- Require the permissions needed for historical mileage. If permissions are missing, request reconnection rather than silently reporting zero mileage.
