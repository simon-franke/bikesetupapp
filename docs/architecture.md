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

Firebase Auth's `User` and `UserCredential` remain the authentication boundary types. Firestore schema and Strava web/mobile redirect behavior are unchanged. The Functions project remains a separately deployed OAuth proxy.

## Dependency injection and lifetimes

`AppDependencies` is the composition root. `main()` provides it through Provider. UI entry points resolve it with `AppDependencies.of(context)` and get feature controllers through `forUser(uid)`. Isolated legacy/widget entry points fall back to the default composition root when no Provider scope exists.

Controllers and repositories are created lazily. User controllers are cached per user, preserving setting write queues across editor and page changes. Successful sign-out clears and disposes those controllers. Screen controllers (`WorkspaceController`, `ServicesController`, `SettingsController`, `BikeMatchingController`, `ServiceEntriesController`) are created by their screen and disposed with it. Pending persistence writes can finish after a screen closes; disposed controllers stop emitting notifications.

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
- `BikesController` coordinates creation of a bike, its default setup through injected feature controllers.
- `SetupsController` supplies typed settings streams, creates default setup fields and serializes writes per bike/setup/category/field. `SettingSaveController` owns editor save revisions and retry state.
- `MaintenanceController` exposes component/history commands. `ServiceEntriesController` replaces and cancels latest-entry subscriptions, reports failures and supports retry.
- `ServicesController` owns mileage loading and syncing. Request generations prevent late responses for an old bike from replacing the current bike's mileage.
- `StravaSyncService` coordinates token renewal, fetching, persistence and the last-sync timestamp through injected repositories. `StravaController` shares an in-flight sync across callers.
- `BikeMatchingController` owns suggested and edited bike links. `SettingsController` owns connection/account state; `AppStateNotifier` persists theme choices through a preference repository.

## Navigation

`app/routing/app_routes.dart` supplies `AppRoutes.fadeSlide()`. Navigation still uses `Navigator.push`/`pop`; there is no declarative router, route table or new deep-link scheme.

## Verification

Run `flutter analyze --fatal-infos`, `flutter test`, and `flutter test --platform chrome test/strava_web_callback_test.dart`.

`test/controllers_test.dart` covers workflows, save ordering/retry, stale responses, subscription cleanup and Provider injection without Firebase. `test/architecture_test.dart` protects layer import boundaries. Existing responsive, contrast, modal, chooser, maintenance and editor tests continue to cover the UI.
