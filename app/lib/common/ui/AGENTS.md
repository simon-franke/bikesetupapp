# Shared UI conventions

These rules also apply to feature UI and routing, as directed by `app/AGENTS.md`. Paths below are relative to `app/`.

## Existing components

- Use `AppTheme` and controls from `lib/common/ui/`. `app_components.dart` contains `AppFormField`/`AppTextField`, `AppFormFooter`, `AppSectionLabel`/`AppSectionToolbar`, and `buildDetailAppBar`. Keep specialized measurement editors purpose-built.
- Use `AppActionButton.isLoading` (or `AppTactileButton.isLoading`) with a short `loadingLabel` for pending actions. Use `AppLoadingState` for empty loading sections and `AppLoadingContent` for inline progress; all share the adjuster animation.
- Theme roles: accent fills pair with `accentInk`; accent text/icons use `accentText`. Use `inkMuted`/`inkDim` without reducing opacity. See `test/contrast_test.dart`.
- Keep copy short and conversational; no em dashes.

## Transitions and pending work

- Push pages with `AppRoutes.fadeSlide()` and preserve native iOS back gestures. Replace screens with `AppScreenTransition` and stable state keys, rather than adding a route.
- Keep outgoing widget ancestry stable until dismissal; do not remount screens to disable input. Review intermediate transition frames as well as settled screens.
- Timing and curves live in `lib/app/routing/app_motion.dart`. Respect Reduced Motion; do not invent per-screen durations.
- Use `showAppSheet` for forms; its future completes after dismissal. When a sheet action changes the underlying screen, capture callbacks before disposal and await `dismissAppSheet` before applying the change.
- Keep existing content visible during writes. Update synchronously when the next screen's data is already available; never delay completion to finish an animation.
- Destructive confirmations stay open until their command completes, with progress and retry in the same sheet. Remove any covered chooser when the command starts so live deletions cannot expose an empty intermediate sheet.
