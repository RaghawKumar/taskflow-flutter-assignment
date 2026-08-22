# TaskFlow

TaskFlow is an Android-first Flutter project-management app built entirely from the supplied combined mock JSON. It includes simulated authentication, organization-scoped projects, task CRUD and assignment, filtering, cached offline reads, debug failures, responsive navigation, and dark mode.

## Architecture

The app uses a small clean/layered architecture:

```text
lib/
├── core/                     validation and cross-cutting helpers
├── data/
│   ├── datasources/          bundled JSON loading, delay/offline/error simulation
│   └── repositories/         local implementations, secure session and cache
├── domain/
│   ├── models/               entities, requests, filters and state enums
│   └── repositories/         backend-independent interfaces
└── presentation/
    ├── blocs/
    │   ├── auth/             session, login, registration and logout
    │   ├── projects/         project loading and mutations
    │   ├── tasks/            tasks, members, filters and assignment
    │   └── settings/         theme and debug connectivity controls
    ├── screens/              auth, dashboard, projects, tasks, settings
    └── widgets/              injected controller scope
```

`AssetMockDataSource` is the only class that reads `assets/mock-data.json`. Every top-level entity collection is parsed independently into typed organizations, users, organization members, projects, tasks, comments, notifications, credentials, and token data. UI code dispatches events to feature-specific BLoCs, which talk to repository interfaces; a future HTTP implementation can replace the local repositories without changing screens. Constructor injection wires dependencies in `main.dart`.

All mock writes are also centralized in `MockDataSource` mutation methods (`upsertProject`, `removeProject`, `upsertTask`, `removeTask`, `setTaskAssignee`, and `removeMembership`). Repositories validate and authorize requests, then call these methods; they never mutate mock collections directly. Entities and request types support JSON serialization/deserialization, with generic `DataResponse`, `ListResponse`, and `MutationResponse` types mirroring transport-layer responses.

The app uses the `flutter_bloc` package with bounded feature ownership: `AuthBloc`, `ProjectsBloc`, `TasksBloc`, and `SettingsCubit`. `MultiBlocProvider` injects them, an authentication listener coordinates organization-scoped initial loads, and screens watch only the feature state they need. `LoadPhase` models initial, loading, success, empty, and error consistently. Mutations and authorization checks live in BLoCs/repositories rather than widgets.

## Implemented flows

- Splash/session check, login validation, simulated registration, logout
- Secure access/refresh token storage; passwords are never stored or logged
- Access token expiry after 900 seconds and automatic mock refresh on restoration
- Organization-scoped project list/detail, create/edit/delete, status summaries
- Complete task list/detail/create/edit/delete, status and priority updates
- Status, priority, assignee and inclusive due-date-range filters
- Organization member picker, assign/unassign, repository-level cross-org protection
- Repository-level admin enforcement for project deletion
- Repository-authoritative member management: admins can remove members, self-removal is blocked, and affected tasks are unassigned
- Pull-to-refresh, loading/empty/error states, delete confirmations
- SharedPreferences cache of the last successful project/task response
- Offline and timeout simulation, cached/stale data banner, retry support
- Responsive bottom navigation/navigation rail and dark mode
- Compact, medium, and expanded breakpoints with centered maximum content widths, adaptive project grids, flexible dashboard metrics, scroll-safe forms, and landscape-safe filter sheets
- Custom fade/slide navigation and staggered list-entry animations
- Animated, screen-reader-aware skeleton loading states
- English and Hindi localization with an in-app language selector
- Accessibility semantics for metrics, tasks, loading announcements, destructive-action tooltips, and large-text-safe scrolling layouts

## Reviewer credentials

```text
Admin:  ava.admin@nimbusdigital.test / Password123!
Member: marcus.member@nimbusdigital.test / Password123!
```

Additional Harborlight accounts remain in the bundled JSON. Credentials are loaded through the data layer and are not hardcoded into authentication logic or widgets. The visible admin hint is reviewer assistance only.

## Simulating failures and offline mode

Open **Settings** after login:

1. Enable **Simulate timeout**, then pull to refresh. Disable it and retry to recover.
2. Enable **Simulate offline**. Last successfully loaded project/task data remains visible and an orange stale-data banner appears. Disable it to reconnect and refresh.
3. Repository lookup of an unknown task ID produces `404 — task not found`.
4. Empty names/titles produce simulated validation errors.
5. A member account cannot delete a project even if repository deletion is invoked directly.
6. Assigning an ID outside the active organization is rejected in the repository.

Artificial request latency is randomized between 300–800 ms so loading UI is observable.

Overlapping reads on the same repository channel use cooperative `CancellationToken`s. A new project/task refresh cancels its superseded artificial request in the data source; feature BLoCs treat cancellation as expected control flow rather than an error state.

## Setup and commands

Developed with Flutter's stable channel and Dart 3. Run from the project root:

```bash
flutter pub get
flutter run
flutter test
flutter test integration_test
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests

Unit coverage includes validation, multi-dimensional task filtering, feature-BLoC authentication, project loading/error recovery, task filtering, and mock-data parsing. Widget coverage includes login form validation and responsive breakpoints. The `integration_test` device-suite entry point is isolated from the unit suite and ready for device-driven flows. Tests use fakes and never require a network.

## Technical decisions and limitations

- Project/task mutations are intentionally in-memory for the process lifetime, as permitted by the brief; successful reads are cached for offline display.
- Registration simulates success and does not create a persistent credential.
- Mock refresh retains the fixture refresh token but issues a distinct JWT-style simulated access token and renews its 15-minute expiry. Tokens are never logged or exposed to widgets.
- Notification inbox, biometrics, inactivity timeout, and pending-operation sync are bonus scope and are not included.
- Avatar URLs are not fetched, preserving the no-third-party-network requirement.
