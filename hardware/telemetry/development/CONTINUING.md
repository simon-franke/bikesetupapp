# Continuing the telemetry design

## What to open

The current assembly is [`../design/Fork_telemetry.f3d`](../design/Fork_telemetry.f3d). Work from that archive or the corresponding current Fusion cloud document. Do not assume a numbered document title inside Fusion identifies the latest saved export.

The current project contains rear-mounted assembled and exploded views, plus hidden earlier components. It includes imported solids as well as native Fusion features; the imported fork placement is not parametrically linked to the native reader cartridge.

## Supporting material

- `Reader_cartridge.f3d` and `.step`: separate reader component source and the solid geometry used by the placement scripts.
- [README.md](README.md): detailed reader and mount design notes, including limitations.
- [reference/README.md](reference/README.md): approximate fork dimensions, rear-mount construction and clearance checks.
- `vendor/`: original manufacturer encoder STEP geometry. Verify the mechanical revision against the purchased encoder before fabrication.
- `*.json` and `reference/*.json`: results from earlier geometry checks. They are snapshots, not proof that later edits have passed.

## Scripts and dependencies

Top-level Python scripts run inside Autodesk Fusion and use its `adsk` API. They build, inspect or export the reader component and current fork assembly; they are not a single safe rebuild command. Read each script first, confirm its expected active document, and save work before running it. Some mutate the active document.

The Fusion scripts currently configure an absolute `OUT` path for this Mac. Update that path for another checkout. It is explicit because execution through Fusion MCP may not provide a script `__file__`.

`reference/build_fork_reference.py` and `reference/build_rear_mount_study.py` run outside Fusion using CadQuery 2.8.0. That environment was removed from this Mac; reinstall it separately only if regeneration is needed. The rear-mount builder also runs the fork-reference builder and reads `Reader_cartridge.step`.

`reference/import_rear_mount_study.py` imports the generated assemblies into the expected Fusion document and exports the current archive to `../design/`, STEP inputs come from `../exports/`, and current images go to `../previews/`. It still accepts the historical document titles used during construction.

Prefer editing the current Fusion design for incremental changes. Rebuilding from scripts can discard manual changes and should be a deliberate operation.

## Updating the repository

Export to the existing stable filename. Refresh matching exports and previews at the same milestone. Keep only generator code and source geometry required by the current design here, not beside the current design. Superseded studies and their images have been removed. Do not add numbered copies as a substitute for Git history.

Physical friction, sealing, retention, real fork/frame clearance and riding durability remain unverified. Read the design notes before treating a geometry check as physical validation.
