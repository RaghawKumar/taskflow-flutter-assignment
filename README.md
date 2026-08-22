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
    │   ├── notifications/    inbox loading and read-state mutations
    │   └── settings/         theme, locale and debug connectivity controls
    ├── screens/              auth, dashboard, projects, tasks, members,
    │                         notifications and settings
    └── widgets/              reusable skeleton/loading components
```

`AssetMockDataSource` is the only class that reads `assets/mock-data.json`. Every top-level entity collection is parsed independently into typed organizations, users, organization members, projects, tasks, comments, notifications, credentials, and token data. UI code dispatches events to feature-specific BLoCs, which talk to repository interfaces; a future HTTP implementation can replace the local repositories without changing screens. Constructor injection wires dependencies in `main.dart`.

All mock writes are also centralized in `MockDataSource` mutation methods (`upsertProject`, `removeProject`, `upsertTask`, `removeTask`, `setTaskAssignee`, and `removeMembership`). Repositories validate and authorize requests, then call these methods; they never mutate mock collections directly. Entities and request types support JSON serialization/deserialization, with generic `DataResponse`, `ListResponse`, and `MutationResponse` types mirroring transport-layer responses.

The app uses the `flutter_bloc` package with bounded feature ownership: `AuthBloc`, `ProjectsBloc`, `TasksBloc`, `NotificationsBloc`, and `SettingsCubit`. `MultiBlocProvider` injects them, an authentication listener coordinates organization-scoped initial loads, and screens watch only the feature state they need. `LoadPhase` models initial, loading, success, empty, and error consistently. Mutations and authorization checks live in BLoCs/repositories rather than widgets.

The dependency direction is:

```text
Screens/widgets -> BLoC/Cubit -> repository interface -> local repository
                                                   -> asset data source
                                                   -> secure/local storage
```

No widget reads JSON, secure storage, or SharedPreferences directly. This keeps the repository contracts suitable for a future HTTP-backed implementation.

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
- User-scoped notification inbox with unread badge, read state, pull-to-refresh, and navigation to the related task

## Reviewer credentials

```text
Admin:  ava.admin@nimbusdigital.test / Password123!
Member: marcus.member@nimbusdigital.test / Password123!
```

Additional Harborlight accounts remain in the bundled JSON. Credentials are loaded through the data layer and are not hardcoded into authentication logic or widgets. The visible admin hint is reviewer assistance only.

## Mock data, simulated failures, and offline mode

`assets/mock-data.json` is bundled as one Flutter asset. `AssetMockDataSource` loads it once, applies an artificial 300–800 ms delay, and deserializes each top-level key into its own typed collection. Local repositories scope results to the authenticated `org_id`, apply validation and authorization, expose request/response-style objects, and update the data source's process-local collections for mutations. The last successful project/task responses are persisted in SharedPreferences for stale offline reads.

Open **Settings** after login:

1. **Timeout:** enable **Simulate timeout**, then pull down on Projects or Tasks. The error/retry UI appears. Disable the toggle and tap retry to recover.
2. **Offline with cached data:** first load Projects and Tasks online, then enable **Simulate offline**. Existing data remains visible with an orange stale-data warning. Pull-to-refresh/retry is safe. Disable the toggle to reconnect and automatically refresh.
3. **Offline without cached data:** clear the app's storage, launch and authenticate, then enable offline before the first project/task load. The screen shows an offline error and retry action instead of crashing.
4. **Validation error:** submit a project with an empty name or a task with an empty title. Form validation appears immediately and the repository also rejects invalid requests.
5. **Authentication error:** submit an incorrect email/password on Login to display the mocked authentication failure.
6. **Authorization error:** sign in as the Member reviewer account. Project deletion and member mutation are unavailable in the UI, and direct repository calls are independently rejected. This enforcement is covered by the authorization unit tests.
7. **404 error:** repository lookup/mutation with an unknown project or task ID produces a typed `404 — ... not found` failure. Because the normal UI only exposes valid IDs, reproduce this deterministic condition with the repository/error-state unit tests.
8. **Cross-organization assignment:** attempting to assign a user outside the active organization is rejected by the repository. The picker filters invalid users, while the repository-level guard is demonstrated by its unit test.
9. **Cancellation:** start repeated pull-to-refresh actions quickly. A newer project/task read cooperatively cancels the superseded read without presenting cancellation as an application error.

Artificial request latency is randomized between 300–800 ms so loading UI is observable.

Overlapping reads on the same repository channel use cooperative `CancellationToken`s. A new project/task refresh cancels its superseded artificial request in the data source; feature BLoCs treat cancellation as expected control flow rather than an error state.

## Setup and commands

Verified development toolchain:

```text
Flutter 3.41.9 (stable)
Dart 3.11.5
DevTools 2.54.2
```

Install Flutter stable and Android Studio/Android SDK, confirm `flutter doctor` is healthy, and start an Android emulator or connect a device. Then run from the project root:

```bash
flutter pub get
flutter run
flutter test
flutter test integration_test/app_test.dart
flutter test --coverage
flutter build apk --release
```

`flutter test` runs the isolated unit, widget, and golden suites. The integration command requires a connected Android target and builds/installs a test application. APK generation is not required during ordinary development; when explicitly requested, the release build is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Build and production readiness

The Task 13 commands were verified with Flutter 3.41.9 / Dart 3.11.5:

| Check | Result |
| --- | --- |
| `flutter pub get` | Pass — dependencies resolve successfully |
| `flutter analyze` | Pass — no issues found |
| `flutter test` | Pass — 35 tests |
| `flutter build apk --debug` | Pass — `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | Pass — `build/app/outputs/flutter-apk/app-release.apk` |

The app starts from bundled assets and local storage without source edits, build-time secrets, environment files, or live service configuration. A source scan found no `print`, `debugPrint`, `developer.log`, private-key, keystore, or service-credential files. Mock reviewer credentials and tokens exist only in the assignment fixture; tokens are not logged. Stateful controllers used by the UI are disposed with their owning widgets, and cooperative cancellation prevents superseded repository reads from lingering. No obvious lifecycle leak was found during review.

The generated release APK is suitable for reviewer installation. Publishing to Google Play requires replacing Android's development signing setup with the owner's private upload/release key; no signing secret is committed to this repository.

## Tests

Unit coverage includes validation, multi-dimensional task filtering, feature-BLoC authentication, project loading/error recovery, task filtering, notifications, cancellation, authorization, serialization, and mock-data parsing. Widget coverage includes login validation, task-list loading/empty/error/success, task-status updates, responsive breakpoints, accessibility, localization, destructive dialogs, and a login-screen golden. Integration tests independently cover mock login, organization project listing, task listing, task create/update, and assignment. Tests use fresh mock-backed dependencies and never require a network. `flutter test --coverage` writes the LCOV report to `coverage/lcov.info`; regenerate goldens intentionally with `flutter test --update-goldens test/widget/golden_login_test.dart`.

## Technical decisions and limitations

- Android is the required and verified target. iOS is optional in the brief and has not been treated as a release target.
- Project/task/member mutations are intentionally process-local, as permitted by the brief. SharedPreferences stores the last successful project/task snapshots for offline display, not a durable transactional database.
- Registration simulates success and does not create a persistent credential.
- Mock refresh retains the fixture refresh token but issues a distinct JWT-style simulated access token and renews its 15-minute expiry. This demonstrates client session behavior; it does not cryptographically sign or remotely validate a real JWT. Tokens are never logged or exposed to widgets.
- Offline mode supports cached reads and retry, but offline mutations and the optional pending-operation synchronization queue are not implemented.
- The notification inbox reads assignment-event fixtures and deep-links to related tasks; creating a new assignment does not synthesize a new notification event.
- Dark mode, responsive/tablet layouts, animations, skeleton loading, accessibility semantics, English/Hindi localization, notifications, cancellation, golden testing, and coverage output are included bonus work. Localization covers application-authored UI; fixture content remains in its source language.
- Biometrics and inactivity timeout are outside the assignment scope and are not implemented.
- Mock `avatar_url` values are parsed and represented in the user model. Their five fixture images are bundled under `assets/avatars/`, so profiles and member lists display them without runtime third-party network calls.
