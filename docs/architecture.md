# App architecture

The app uses feature folders and a UI → controller → repository flow. It remains a single Flutter package and uses Material controls and Provider.

```text
lib/
  main.dart                     Firebase/platform initialization and runApp
  app/
    app_dependencies.dart       Repository factories and controller lifetimes
    startup/                    Default bike/setup resolution
    routing/                    Existing Navigator transition helper
  common/
    models/                     Typed command outcomes and failure codes
    controllers/                Observable async operation state
    data/                       Firestore keys and timestamp conversion
    layout/                     Responsive compositions
    theme/                      Material theme and palette
    ui/                         Reusable controls and modal compositions
  features/
    auth/
    bikes/
    maintenance/
    settings/
    setups/
    strava/
    workspace/
```

Features use `ui/`, `controllers/`, `repositories/` and `models/` where needed. Strava also has `platform/` for conditional browser callback handling. Workspace composes the other features and does not need a repository of its own.

## Responsibilities

- **UI:** rendering, responsive layout, animation, focus, temporary input drafts, dialogs and navigation. It reads controller state or typed streams and invokes controller actions. It does not construct persistence services or access Firebase singletons.
- **Controllers:** feature commands, application workflows, async operation state, selection state, write ordering and subscription lifetimes. Constructors receive dependencies. They do not import widgets or concrete Firestore repositories.
- **Repositories:** persistence contracts and implementations. They own Firestore paths, snapshots, HTTP/OAuth adapters and preference storage. Firestore snapshots and timestamps stay inside this layer; callers receive typed models or maps for extensible setting fields.
- **Models:** data and domain values, including bike types, categories, unit conversion and maintenance schedule calculations. They do not depend on Firestore or UI implementations.

Firebase Auth's `User` and `UserCredential` remain the authentication boundary types. The Firestore schema is unchanged. The separately deployed Functions project proxies web OAuth exchanges and refreshes.

## Dependency injection and lifetimes

`AppDependencies` is the composition root. `main()` provides it through Provider. UI entry points resolve it with `AppDependencies.of(context)` and get feature controllers through `forUser(uid)`. Isolated legacy/widget entry points fall back to the default composition root when no Provider scope exists.

Controllers and repositories are created lazily. User controllers are cached per user, preserving setting write queues across editor and page changes. Sign-out first clears the active user's local Strava credentials and sync timestamp, then signs out of Firebase and disposes cached user controllers. Screen controllers (`WorkspaceController`, `ServicesController`, `SettingsController`, `BikeMatchingController`, `ServiceEntriesController`) are created by their screen and disposed with it. Pending persistence writes can finish after a screen closes; disposed controllers stop emitting notifications.

For tests, construct controllers with fake repository contracts, or provide an `AppDependencies` instance with repository factories:

```dart
final dependencies = AppDependencies(
  setupsRepository: (_) => fakeSetupsRepository,
);

Provider<AppDependencies>.value(
  value: dependencies,
  child: screen,
);
```

Dispose test dependency scopes after unmounting their widgets. A feature test only needs to inject repositories that its code uses.

## Key workflows

- `StartupController` resolves the default selection for both launch and returning sign-in.
- `BikesController` coordinates creation of a bike, its default setup through repository contracts and the non-observable `SetupCreationService`.
- `SetupsController` supplies typed settings streams, creates default setup fields and serializes writes per bike/setup/category/field. `SettingSaveController` owns editor save revisions and retry state.
- `MaintenanceController` exposes component/history commands. `ServiceEntriesController` replaces and cancels latest-entry subscriptions, reports failures and supports retry.
- `ServicesController` owns mileage loading and syncing. Request generations prevent late responses for an old bike from replacing the current bike's mileage.
- `StravaAuthService` reads credentials scoped to the Firebase UID, serializes concurrent refreshes, and discards results after sign-out or a user change. Browser callbacks require the initiating tab's single-use, ten-minute OAuth state and matching UID. Granted scopes are persisted; historical mileage requires `activity:read_all`. Web refreshes use `stravaRefresh`; mobile exchanges and refreshes use the existing direct flow.
- `ServiceEditorController` owns log/defer entry IDs, mileage requests, duplicate submission prevention and retry state. `MaintenanceController` constructs entries and atomically creates components with their initial service baseline. Widgets retain inputs and navigate only after successful persistence. Pure model functions own setup defaults, bike-link suggestions and deferred-service mileage.
- `StravaSyncService` coordinates token renewal, fetching, persistence and the last-sync timestamp through injected repositories. `StravaController` shares an in-flight sync across callers.
- `BikeMatchingController` owns suggested and edited bike links. `SettingsController` owns connection/account state; `AppStateNotifier` persists theme choices through a preference repository.

## Command and async contract

Mutation and screen-loading commands return `CommandResult<T>`: success, expected `AppFailure`, or cancellation. Repositories translate known SDK/HTTP failures into failure codes with the original cause and stack. Missing documents remain missing data; failed reads propagate. Unexpected exceptions propagate and stay available in controller error state with their stack. User-facing wording lives in `failure_message.dart`; `presentCommand` handles presentation and reports unexpected errors through Flutter's error reporting.

`OperationController` provides activity tracking, error state, named request generations, sharing of identical in-flight commands, and notification suppression after disposal. Screen loads check request validity after awaited operations. Public state is exposed through read-only getters and unmodifiable collections. Subscription owners retain stream exceptions and stacks and cancel subscriptions on replacement/disposal.

`WriteQueue` orders operations and allows the next write after a failure. Auth session changes, theme persistence and per-field setting writes use queues. Strava sync persistence and disconnection deletion share a queue; deletion invalidates pending sync results and follows any already-started write. Commands started after disposal are cancelled before work begins. Already accepted field edits continue through their shared queue when an editor closes, while obsolete presentation results are cancelled. Started persistence calls are not rolled back on disposal.

## Navigation

`app/routing/app_routes.dart` supplies `AppRoutes.fadeSlide()`. Navigation still uses `Navigator.push`/`pop`; there is no declarative router, route table or new deep-link scheme.

## Verification

Run `flutter analyze --fatal-infos`, `flutter test`, and `flutter test --platform chrome test/strava_web_callback_test.dart`, and `(cd functions && npm test)`.

`test/controllers_test.dart` covers workflows, save ordering/retry, stale responses, subscription cleanup and Provider injection without Firebase. `test/controller_async_test.dart` covers typed outcomes, error stacks, shared submissions, stable retry IDs, immutable state, ordered auth/theme writes and disposal. `test/controller_domain_rules_test.dart` covers pure rules. `test/architecture_test.dart` protects layer import boundaries. Existing responsive, contrast, modal, chooser, maintenance and editor tests continue to cover the UI.
