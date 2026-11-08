# Shared UI conventions

These rules apply across all features.

## File organization

Keep UI files focused on one screen or cohesive component. Extract independently meaningful sections and behavior when doing so improves readability.

## Consistency and accessibility

- Reuse shared controls, themes, and interaction patterns. Keep specialized measurement editors purpose-built.
- Show progress for pending actions with short, descriptive loading labels.
- Use semantic theme colors and preserve readable contrast, including muted text and icons.
- Keep copy short and conversational; no em dashes.

## Transitions and pending work

- Preserve native back gestures and screen state during transitions.
- Keep outgoing screens stable until dismissal; do not recreate them merely to disable input. Review intermediate transition frames as well as settled screens.
- Keep motion consistent across screens and respect Reduced Motion.
- Finish dismissing a sheet before changing its underlying screen. Do not use callbacks or state after their owner has been disposed.
- Keep existing content visible during writes. Update immediately when the next screen's data is already available; never delay completion to finish an animation.
- Destructive confirmations stay open until their command completes, with progress and retry in the same sheet. Dismiss covered selection interfaces before deleting their data so they cannot expose an empty intermediate screen.
