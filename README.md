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
    ├── controllers/          ChangeNotifier application/business state
    ├── screens/              auth, dashboard, projects, tasks, settings
    └── widgets/              injected controller scope
```

`AssetMockDataSource` is the only class that reads `assets/mock-data.json`. Each top-level collection is parsed independently. UI code talks to `AppController`, which talks to repository interfaces; a future HTTP implementation can replace the local repositories without changing screens. Constructor injection wires dependencies in `main.dart`.

`ChangeNotifier` provides dependency-light state management. `LoadPhase` models initial, loading, success, empty, and error consistently. Mutations and authorization checks live in the controller/repository rather than widgets.

## Implemented flows

- Splash/session check, login validation, simulated registration, logout
- Secure access/refresh token storage; passwords are never stored or logged
- Access token expiry after 900 seconds and automatic mock refresh on restoration
- Organization-scoped project list/detail, create/edit/delete, status summaries
- Complete task list/detail/create/edit/delete, status and priority updates
- Status, priority, assignee and inclusive due-date-range filters
- Organization member picker, assign/unassign, repository-level cross-org protection
- Repository-level admin enforcement for project deletion
- Pull-to-refresh, loading/empty/error states, delete confirmations
- SharedPreferences cache of the last successful project/task response
- Offline and timeout simulation, cached/stale data banner, retry support
- Responsive bottom navigation/navigation rail and dark mode

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

Unit coverage includes validation and multi-dimensional task filtering. Widget coverage includes login form validation. The `integration_test` device-suite entry point is isolated from the unit suite and ready for device-driven flows. Tests use fakes and never require a network.

## Technical decisions and limitations

- Project/task mutations are intentionally in-memory for the process lifetime, as permitted by the brief; successful reads are cached for offline display.
- Registration simulates success and does not create a persistent credential.
- The mock refresh response renews the same supplied token value because the fixture supplies only one pair.
- Notification inbox, biometrics, inactivity timeout, pending-operation sync, and request cancellation are bonus scope and are not included.
- Avatar URLs are not fetched, preserving the no-third-party-network requirement.
