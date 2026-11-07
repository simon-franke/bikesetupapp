# Clickwise

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Clickwise targets iOS and Android, with iPad support desired in the future. Native conventions should be respected within the shared app.

## Users

Mountain bikers tuning suspension and bike setup. They need to record settings, compare setups and experiments, and keep track of maintenance for their own bikes.

## Product Purpose

A simple personal bike log for setups, experiments and maintenance. Help riders keep useful records of their bikes and adjustments without making recording or finding information unnecessarily complicated.

## Capabilities and Constraints

- Bike settings and saved setups, setup experiments, service history and repair to-dos are existing capabilities.
- Strava is an optional integration for bike mileage, not a prerequisite for using the product.
- The existing implementation uses Flutter and Firebase. Follow `AGENTS.md` for architecture, checks and development-session safeguards.

## Brand Commitments

- Preserve the Clickwise name and its actual blue suspension top-cap logo. Use the logo rather than a generic bicycle icon for product branding.
- Keep copy short, direct and conversational. Avoid em dashes and unnecessary explanatory text.
- Improve existing screens with clear hierarchy and consistent behavior. Do not turn a narrow request for better presentation into an elaborate onboarding journey or unrelated redesign.

## Evidence on Hand

- `README.md` describes the implemented features and development workflow.
- `lib/features/` contains the existing product implementation; it is evidence of current behavior, not automatic approval of every product choice.
- `assets/app-icon/design.json` records the logo source; `ios/Runner/AppIcon.icon/Assets/top-cap.png` contains the source artwork, and `assets/app-icon/logo.png` is the in-app asset.
- Public support contact and publisher details have not yet been supplied. Do not invent them or claim store approval/readiness from a UI change.

## Product Principles

1. Keep the rider's task simple: recording and finding setup and maintenance information should take little effort.
2. Preserve user data, edits and context through navigation and account changes.
3. Use familiar interactions and purposeful hierarchy; introduce steps only when they help the rider complete the task.

## Accessibility & Inclusion

Preserve text scaling, keyboard handling and readable contrast, as required by the repository's UI conventions and existing tests.
