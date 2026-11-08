# Backend development

Use the runtime version specified by the project configuration. Run `npm test` from `functions/`. Follow `README.md` for emulator checks and deployment procedures; do not bypass required checks before deployment.

Enforce authenticated ownership of user data. Preserve single-use OAuth state checks and sign-out cleanup. Prevent stale writes from recreating data during or after account deletion.

Keep service secrets in managed server-side secret storage, never in the app or repository. Never overwrite existing local configuration or credentials.
