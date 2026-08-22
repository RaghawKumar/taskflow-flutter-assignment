import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/blocs/auth/auth_bloc.dart';
import 'package:taskflow/presentation/blocs/projects/projects_bloc.dart';
import 'package:taskflow/presentation/blocs/tasks/tasks_bloc.dart';

void main() {
  final session = Session(
    user: const AppUser(id: 'u1', name: 'User', email: 'u@x.com'),
    orgId: 'o1',
    role: 'org_admin',
    expiresAt: DateTime(2030),
  );
  test('AuthBloc emits authenticated success', () async {
    final bloc = AuthBloc(_FakeAuth(session));
    addTearDown(bloc.close);
    expect(await bloc.login('u@x.com', 'Password123!'), isTrue);
    expect(bloc.state.session, session);
    expect(bloc.state.phase, LoadPhase.success);
  });
  test('ProjectsBloc exposes load errors and recovers', () async {
    final repository = _FakeRepository()..error = const AppException('timeout');
    final bloc = ProjectsBloc(repository);
    addTearDown(bloc.close);
    await bloc.load('o1');
    expect(bloc.state.phase, LoadPhase.error);
    repository.error = null;
    await bloc.load('o1');
    expect(bloc.state.phase, LoadPhase.success);
  });
  test('TasksBloc filters its feature-owned task state', () async {
    final bloc = TasksBloc(_FakeRepository());
    addTearDown(bloc.close);
    await bloc.load('o1');
    bloc.setFilter(const TaskFilter(status: TaskStatus.done));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.filtered, isEmpty);
  });
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this.session);
  final Session session;
  @override
  Future<Session> login(LoginRequest request) async => session;
  @override
  Future<void> logout() async {}
  @override
  Future<Session> refresh(Session session) async => session;
  @override
  Future<Session?> restoreSession() async => session;
}

class _FakeRepository implements TaskFlowRepository {
  Object? error;
  void fail() {
    if (error != null) throw error!;
  }

  @override
  bool offline = false;
  @override
  String? forcedError;
  @override
  Future<List<Project>> projectsForOrg(String orgId) async {
    fail();
    return [
      Project(
        id: 'p1',
        orgId: orgId,
        name: 'P',
        description: '',
        createdAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async {
    fail();
    return [
      TaskItem(
        id: 't1',
        projectId: 'p1',
        title: 'T',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        dueDate: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<List<AppUser>> membersForOrg(String orgId) async => [];
  @override
  Future<List<TaskNotification>> notificationsForUser(String userId) async =>
      [];
  @override
  Future<TaskNotification> markNotificationRead(String notificationId) =>
      throw UnimplementedError();
  @override
  Future<TaskItem> assignTask(String taskId, String? userId, String orgId) =>
      throw UnimplementedError();
  @override
  Future<void> deleteProject(String id, {required String actorUserId}) async {}
  @override
  Future<void> removeMember(
    String orgId,
    String memberUserId, {
    required String actorUserId,
  }) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> task(String id) => throw UnimplementedError();
  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async => [];
}
