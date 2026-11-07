# Repository guide

This repository contains `app/` (Flutter), `backend/` (Firebase services and rules), and `hardware/` (mechanical and electronics work).

Read `app/AGENTS.md` before changing app code. Run Flutter commands from `app/`, Firebase commands from `backend/`, and function tests from `backend/functions/`. CI workflows remain at `.github/workflows/`.

Preserve the user’s running debug session. Never stop or replace its process, hot restart it, or reset its state without permission.

Keep generated build artifacts and credentials out of Git. Preserve editable CAD sources and clearly distinguish prototypes from validated hardware.
