import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/app_localizations.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/blocs/auth/auth_bloc.dart';
import 'package:taskflow/presentation/blocs/projects/projects_bloc.dart';
import 'package:taskflow/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:taskflow/presentation/screens/task_detail_screen.dart';
import 'package:taskflow/presentation/screens/tasks_screen.dart';
import 'package:taskflow/presentation/widgets/skeleton_loading.dart';

void main() {
  testWidgets('task list renders loading state', (tester) async {
    final repository = _TaskRepository()..loadingGate = Completer<void>();
    await _pump(tester, repository, const TasksScreen(), awaitTasks: false);
    expect(find.byType(SkeletonList), findsOneWidget);
    repository.loadingGate!.complete();
  });

  testWidgets('task list renders empty state', (tester) async {
    await _pump(tester, _TaskRepository(tasks: []), const TasksScreen());
    expect(find.text('No tasks match these filters.'), findsOneWidget);
  });

  testWidgets('task list renders error and retry state', (tester) async {
    await _pump(
      tester,
      _TaskRepository(error: const AppException('Task load failed')),
      const TasksScreen(),
    );
    expect(find.text('Task load failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('task list renders successful task data', (tester) async {
    await _pump(tester, _TaskRepository(), const TasksScreen());
    expect(find.text('Test task'), findsOneWidget);
    expect(find.byKey(const Key('task_list')), findsOneWidget);
  });

  testWidgets('task status update changes repository and UI state', (
    tester,
  ) async {
    final repository = _TaskRepository();
    await _pump(tester, repository, const TaskDetailScreen(taskId: 'task_1'));
    await tester.tap(find.byKey(const Key('status_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();
    expect(repository.tasks.single.status, TaskStatus.done);
    expect(find.text('Done'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _TaskRepository repository,
  Widget child, {
  bool awaitTasks = true,
}) async {
  final auth = AuthBloc(_AuthRepository());
  final projects = ProjectsBloc(repository);
  final tasks = TasksBloc(repository);
  addTearDown(auth.close);
  addTearDown(projects.close);
  addTearDown(tasks.close);
  await auth.login('user@example.com', 'Password123!');
  await projects.load('org_1');
  final loading = tasks.load('org_1');
  if (awaitTasks) await loading;
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: auth),
        BlocProvider.value(value: projects),
        BlocProvider.value(value: tasks),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  await tester.pump();
}

class _AuthRepository implements AuthRepository {
  final session = Session(
    user: const AppUser(id: 'user_1', name: 'User', email: 'user@example.com'),
    orgId: 'org_1',
    role: 'org_admin',
    expiresAt: DateTime(2030),
  );
  @override
  Future<Session> login(LoginRequest request) async => session;
  @override
  Future<void> logout() async {}
  @override
  Future<Session> refresh(Session session) async => session;
  @override
  Future<Session?> restoreSession() async => session;
}

class _TaskRepository implements TaskFlowRepository {
  _TaskRepository({List<TaskItem>? tasks, this.error})
    : tasks =
          tasks ??
          [
            TaskItem(
              id: 'task_1',
              projectId: 'project_1',
              title: 'Test task',
              description: 'Details',
              status: TaskStatus.todo,
              priority: TaskPriority.medium,
              assigneeId: 'user_1',
              dueDate: DateTime(2026, 2, 1),
              createdAt: DateTime(2026),
            ),
          ];
  List<TaskItem> tasks;
  Object? error;
  Completer<void>? loadingGate;
  @override
  bool offline = false;
  @override
  String? forcedError;
  Future<void> _beforeLoad() async {
    if (loadingGate != null) await loadingGate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async {
    await _beforeLoad();
    return List.of(tasks);
  }

  @override
  Future<List<Project>> projectsForOrg(String orgId) async => [
    Project(
      id: 'project_1',
      orgId: orgId,
      name: 'Project',
      description: '',
      createdAt: DateTime(2026),
    ),
  ];
  @override
  Future<List<AppUser>> membersForOrg(String orgId) async => const [
    AppUser(id: 'user_1', name: 'User', email: 'user@example.com'),
  ];
  @override
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  }) async {
    final current = tasks.firstWhere((task) => task.id == id);
    final updated = current.copyWith(
      title: request.title,
      description: request.description,
      status: request.status,
      priority: request.priority,
      assigneeId: request.assigneeId,
      dueDate: request.dueDate,
    );
    tasks = [updated];
    return updated;
  }

  @override
  Future<TaskItem> assignTask(
    String taskId,
    String? userId,
    String orgId,
  ) async {
    final updated = tasks.single.copyWith(assigneeId: userId);
    tasks = [updated];
    return updated;
  }

  @override
  Future<void> deleteProject(String id, {required String actorUserId}) async {}
  @override
  Future<void> deleteTask(String id) async =>
      tasks.removeWhere((task) => task.id == id);
  @override
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> task(String id) async =>
      tasks.firstWhere((task) => task.id == id);
  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async =>
      tasks.where((task) => task.projectId == projectId).toList();
  @override
  Future<void> removeMember(
    String orgId,
    String memberUserId, {
    required String actorUserId,
  }) async {}
  @override
  Future<List<TaskNotification>> notificationsForUser(String userId) async =>
      [];
  @override
  Future<TaskNotification> markNotificationRead(String notificationId) =>
      throw UnimplementedError();
}
