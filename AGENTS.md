# Repository guide

- `app/`: Flutter. `backend/`: Firebase services and rules. `hardware/`: mechanical and electronics work. Read the relevant directory's `AGENTS.md` before editing.
- Run Flutter commands from `app/`, Firebase commands from `backend/`, and function tests from `backend/functions/`. CI workflows live in `.github/workflows/`.
- Preserve the user's running debug session. Never stop or replace its process, hot restart it, or reset its state without permission. Run tests separately; only stop processes started for your own tests.
- Keep generated build artifacts and credentials out of Git. Hardware source-of-truth and prototype rules live in `hardware/AGENTS.md`.

## Readability preference

Group related code with blank lines. Extract clearly named helpers for distinct tasks, without fragmenting simple operations. Use documentation comments for non-obvious contracts and inline comments for reasons, not narration. In Dart, use `///` Dartdoc; do not document every getter or repeat method names.
