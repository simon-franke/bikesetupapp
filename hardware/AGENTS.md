# Hardware work

Start with `README.md` and `telemetry/development/CONTINUING.md`.

Keep the current editable assembly in `telemetry/design/`, matching interchange files in `telemetry/exports/`, and current images in `telemetry/previews/`. Scripts, source geometry, validation records belong in `telemetry/development/`.

Use stable filenames and Git revision history. Keep only supporting geometry and scripts used by the current design. Remove superseded studies and images instead of maintaining a second revision history. Update paths when reorganizing assets. Never run a Fusion script against an unconfirmed active document: some scripts replace or modify components.

Distinguish approximate fit studies from physically validated hardware. Existing validation reports apply only to the geometry that produced them.
