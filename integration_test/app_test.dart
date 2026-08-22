import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/request_cancellation.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/data/repositories/local_repositories.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/presentation/blocs/auth/auth_bloc.dart';
import 'package:taskflow/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:taskflow/presentation/blocs/projects/projects_bloc.dart';
import 'package:taskflow/presentation/blocs/settings/settings_cubit.dart';
import 'package:taskflow/presentation/blocs/tasks/tasks_bloc.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow uses bundled mock credentials', (tester) async {
    await _launchAndLogin(tester);
    expect(find.textContaining('Hello, Ava'), findsOneWidget);
  });

  testWidgets('project listing is organization scoped', (tester) async {
    await _launchAndLogin(tester);
    await _openProjects(tester);
    expect(find.text('Website Relaunch'), findsOneWidget);
    expect(find.text('Client Onboarding Revamp'), findsNothing);
  });

  testWidgets('task listing displays organization tasks', (tester) async {
    await _launchAndLogin(tester);
    await _openTasks(tester);
    expect(find.text('Fix broken contact form'), findsOneWidget);
  });

  testWidgets('create and update task flow', (tester) async {
    await _launchAndLogin(tester);
    await _openTasks(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Website Relaunch'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task_title')),
      'Integration task',
    );
    await tester.enterText(
      find.byKey(const Key('task_description')),
      'Created by integration test',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Integration task'),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Integration task'), findsOneWidget);
    await tester.tap(find.text('Integration task'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task_title')),
      'Updated integration task',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(find.text('Updated integration task'), findsOneWidget);
  });

  testWidgets('task assignment flow updates current assignee', (tester) async {
    await _launchAndLogin(tester);
    await _openTasks(tester);
    await tester.tap(find.text('Fix broken contact form'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assignee_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ava Thompson').last);
    await tester.pumpAndSettle();
    expect(find.text('Ava Thompson'), findsOneWidget);
  });
}

Future<void> _launchAndLogin(WidgetTester tester) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
  final source = _FastAssetSource();
  final repository = LocalTaskFlowRepository(source);
  await tester.pumpWidget(
    TaskFlowApp(
      authBloc: AuthBloc(LocalAuthRepository(source)),
      projectsBloc: ProjectsBloc(repository),
      tasksBloc: TasksBloc(repository),
      settingsCubit: SettingsCubit(repository),
      notificationsBloc: NotificationsBloc(repository),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('email')),
    'ava.admin@nimbusdigital.test',
  );
  await tester.enterText(find.byKey(const Key('password')), 'Password123!');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

Future<void> _openProjects(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.folder_outlined).last);
  await tester.pumpAndSettle();
}

Future<void> _openTasks(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.task_alt).last);
  await tester.pumpAndSettle();
}

class _FastAssetSource extends AssetMockDataSource {
  @override
  Future<void> delay([CancellationToken? cancellationToken]) async {
    cancellationToken?.throwIfCancelled();
    if (offline) throw const AppException('Offline');
    if (forcedError != null) throw AppException(forcedError!);
  }
}
