# TaskFlow

TaskFlow is an Android-first Flutter project-management app built entirely from the supplied combined mock JSON. It includes simulated authentication, organization-scoped projects, task CRUD and assignment, filtering, cached offline reads, debug failures, responsive navigation, and dark mode.

## Architecture

Reviewer documentation: [Architecture Document](docs/ARCHITECTURE.md) · [PDF version](docs/TaskFlow_Architecture_Document.pdf)

The app uses a small clean/layered architecture:

```text
lib/
├── core/                     validation and cross-cutting helpers
├── data/
│   ├── datasources/          bundled JSON loading, delay/offline/error simulation
│   ├── repositories/         local implementations, secure session and cache
│   └── services/             platform biometric implementation
├── domain/
│   ├── models/               entities, requests, filters and state enums
│   ├── repositories/         backend-independent repository interfaces
│   └── services/             platform-independent service contracts
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

No widget reads JSON, secure storage, or SharedPreferences directly. This keeps the repository contracts suitable for a future HTTP-backed implementation. Platform biometric calls are similarly hidden behind `BiometricService`, allowing BLoC tests to use deterministic fakes.

## Simulated authentication and token flow

1. Splash dispatches a session check through `AuthBloc`.
2. `LocalAuthRepository` reads the bundled `auth_mock.test_credentials` through `AssetMockDataSource`; credentials are never hardcoded in a widget.
3. A matching email/password returns the fixture access/refresh token pair. Both tokens and session metadata are written to `flutter_secure_storage`; the password is never persisted.
4. Access expiry is calculated from `access_token_expires_in_seconds` (`900`, or 15 minutes). An expired restored session runs the mock refresh flow, retains the fixture refresh token, creates a distinct JWT-style mock access token, and renews expiry.
5. If biometric unlock is enabled, a restored session remains blocked until the device biometric prompt succeeds. Cancellation offers biometric retry and password-login fallback.
6. Logout or the five-minute inactivity timeout deletes the complete secure session, clears feature BLoCs, and causes the root authentication guard to replace all protected screens with Login.

Registration validates locally and simulates success without adding a credential or persisting a password. No real network or authentication server is called, and tokens are never printed or exposed to UI widgets.

## Implemented flows

- Splash/session check, login validation, simulated registration, logout
- Secure access/refresh token storage; passwords are never stored or logged
- Access token expiry after 900 seconds and automatic mock refresh on restoration
- Opt-in biometric unlock for a stored session, with retry and password fallback
- Automatic logout after five minutes without touch or keyboard activity, including background/resume elapsed-time checks
- Android fingerprint/face authentication and iOS Face ID/Touch ID configuration through the same platform-independent biometric service
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
- Branded TF launcher icons for Android and a complete iOS AppIcon catalog, including the 1024×1024 App Store icon

## Reviewer credentials

```text
Org A — Nimbus Digital
Admin:  ava.admin@nimbusdigital.test / Password123!
Member: marcus.member@nimbusdigital.test / Password123!

Org B — Harborlight Studios
Admin:  daniel.admin@harborlightstudios.test / Password123!
Member: elena.member@harborlightstudios.test / Password123!
```

All credentials are loaded through the data layer from `auth_mock.test_credentials`; they are not hardcoded into authentication logic or widgets. The visible admin hint is reviewer assistance only.

## Mock data, simulated failures, and offline mode

`assets/mock-data.json` is bundled as one Flutter asset. `AssetMockDataSource` loads it once, applies an artificial 300–800 ms delay, and deserializes each top-level key into its own typed collection. Local repositories scope results to the authenticated `org_id`, apply validation and authorization, expose request/response-style objects, and update the data source's process-local collections for mutations. The last successful project/task responses are persisted in SharedPreferences for stale offline reads.

Open **Settings** after login:

1. **Biometric unlock:** on an Android or iOS device/simulator with an enrolled fingerprint, Face ID, or Touch ID credential, open **Settings → Security** and enable **Biometric unlock**. Approve the verification prompt, restart the app, and authenticate again when TaskFlow restores the stored session. Cancelling shows a retry button on Login; password login remains available. Unsupported or unenrolled devices show a clear message and remain unlocked. iOS includes the required Face ID usage description in `ios/Runner/Info.plist`.
2. **Automatic inactivity timeout:** leave an authenticated screen untouched for five minutes. TaskFlow deletes the secure session and returns to Login. Touch, pointer movement, or keyboard input resets the timer; returning from the background also checks elapsed time.
3. **Request timeout:** enable **Simulate timeout**, then pull down on Projects or Tasks. The error/retry UI appears. Disable the toggle and tap retry to recover.
4. **Offline with cached data:** first load Projects and Tasks online, then enable **Simulate offline**. Existing data remains visible with an orange stale-data warning. Pull-to-refresh/retry is safe. Disable the toggle to reconnect and automatically refresh.
5. **Offline without cached data:** clear the app's storage, launch and authenticate, then enable offline before the first project/task load. The screen shows an offline error and retry action instead of crashing.
6. **Validation error:** submit a project with an empty name or a task with an empty title. Form validation appears immediately and the repository also rejects invalid requests.
7. **Authentication error:** submit an incorrect email/password on Login to display the mocked authentication failure.
8. **Authorization error:** sign in as the Member reviewer account. Project deletion and member mutation are unavailable in the UI, and direct repository calls are independently rejected. This enforcement is covered by the authorization unit tests.
9. **404 error:** repository lookup/mutation with an unknown project or task ID produces a typed `404 — ... not found` failure. Because the normal UI only exposes valid IDs, reproduce this deterministic condition with the repository/error-state unit tests.
10. **Cross-organization assignment:** attempting to assign a user outside the active organization is rejected by the repository. The picker filters invalid users, while the repository-level guard is demonstrated by its unit test.
11. **Cancellation:** start repeated pull-to-refresh actions quickly. A newer project/task read cooperatively cancels the superseded artificial request without presenting cancellation as an application error.

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
| `flutter test` | Pass — 41 tests |
| Android debug Kotlin/resources | Pass — native app and plugins compile successfully |
| Android release Flutter/Kotlin/resources | Pass — release-mode code, manifests, plugins, and resources compile successfully |
| `flutter build apk --debug` | Previously verified — output path `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | Previously verified — output path `build/app/outputs/flutter-apk/app-release.apk` |

The app starts from bundled assets and local storage without source edits, build-time secrets, environment files, or live service configuration. A source scan found no `print`, `debugPrint`, `developer.log`, private-key, keystore, or service-credential files. Mock reviewer credentials and tokens exist only in the assignment fixture; tokens are not logged. Stateful controllers used by the UI are disposed with their owning widgets, and cooperative cancellation prevents superseded repository reads from lingering. No obvious lifecycle leak was found during review.

The release command produces a reviewer-installable APK using the development signing configuration. Publishing to Google Play requires replacing it with the owner's private upload/release key and secure CI configuration; no signing secret, `key.properties`, `.jks`, or `.keystore` file is committed. Generated build outputs, coverage files, tool caches, and local properties are ignored by Git.

## Tests

Unit coverage includes validation, multi-dimensional task filtering, feature-BLoC authentication, biometric session gating/retry, inactivity timeout/reset, project loading/error recovery, task filtering, notifications, cancellation, authorization, serialization, and mock-data parsing. Widget coverage includes login validation, task-list loading/empty/error/success, task-status updates, responsive breakpoints, accessibility, localization, destructive dialogs, and a login-screen golden. Integration tests independently cover mock login, organization project listing, task listing, task create/update, and assignment. Tests use fresh mock-backed dependencies and never require a network. `flutter test --coverage` writes the LCOV report to `coverage/lcov.info`; regenerate goldens intentionally with `flutter test --update-goldens test/widget/golden_login_test.dart`.

## Technical decisions and limitations

- Android is the required and verified release target. The optional iOS project includes the complete branded AppIcon catalog, secure-storage integration, and Face ID/Touch ID permission/configuration, but an iOS release archive has not been verified or submitted.
- Project/task/member mutations are intentionally process-local, as permitted by the brief. SharedPreferences stores the last successful project/task snapshots for offline display, not a durable transactional database.
- Registration simulates success and does not create a persistent credential.
- Mock refresh retains the fixture refresh token but issues a distinct JWT-style simulated access token and renews its 15-minute expiry. This demonstrates client session behavior; it does not cryptographically sign or remotely validate a real JWT. Tokens are never logged or exposed to widgets.
- Offline mode supports cached reads and retry, but offline mutations and the optional pending-operation synchronization queue are not implemented.
- The notification inbox reads assignment-event fixtures and deep-links to related tasks; creating a new assignment does not synthesize a new notification event.
- Dark mode, responsive/tablet layouts, animations, skeleton loading, accessibility semantics, English/Hindi localization, notifications, cancellation, golden testing, and coverage output are included bonus work. Localization covers application-authored UI; fixture content remains in its source language.
- Biometric unlock is opt-in and depends on an enrolled Android or iOS device credential. It protects restoration of the existing secure session; passwords and biometric data are never stored by TaskFlow. Automatic inactivity logout is fixed at five minutes for a deterministic reviewer demonstration.
- Mock `avatar_url` values are parsed and represented in the user model. Their five fixture images are bundled under `assets/avatars/`, so profiles and member lists display them without runtime third-party network calls.
