import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/controllers/app_bloc.dart';

void main() {
  final user = const AppUser(
    id: 'user_1',
    name: 'Test User',
    email: 'test@example.com',
  );
  late Session session;

  setUp(() {
    session = Session(
      user: user,
      orgId: 'org_1',
      role: 'org_admin',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  });

  test('login emits authenticated success and loaded data', () async {
    final bloc = AppBloc(_FakeAuth(session: session), _FakeRepository());
    addTearDown(bloc.close);

    expect(await bloc.login('test@example.com', 'Password123!'), isTrue);
    expect(bloc.state.session, session);
    expect(bloc.state.sessionPhase, LoadPhase.success);
    expect(bloc.state.dataPhase, LoadPhase.success);
    expect(bloc.state.projects, hasLength(1));
  });

  test('invalid login emits a user-facing error state', () async {
    final bloc = AppBloc(
      _FakeAuth(loginError: const AppException('Incorrect email or password.')),
      _FakeRepository(),
    );
    addTearDown(bloc.close);

    expect(await bloc.login('wrong@example.com', 'bad-password'), isFalse);
    expect(bloc.state.sessionPhase, LoadPhase.error);
    expect(bloc.state.error, 'Incorrect email or password.');
  });

  test('repository failure emits data error and supports retry', () async {
    final repository = _FakeRepository(
      loadError: const AppException('Request timed out. Please retry.'),
    );
    final bloc = AppBloc(_FakeAuth(session: session), repository);
    addTearDown(bloc.close);

    await bloc.login('test@example.com', 'Password123!');
    expect(bloc.state.dataPhase, LoadPhase.error);
    expect(bloc.state.error, contains('timed out'));

    repository.loadError = null;
    await bloc.loadAll();
    expect(bloc.state.dataPhase, LoadPhase.success);
    expect(bloc.state.error, isNull);
  });

  test(
    'failed protected mutation returns false and exposes its error',
    () async {
      final repository = _FakeRepository(
        deleteError: const AppException(
          'Only organization admins can delete projects.',
        ),
      );
      final bloc = AppBloc(_FakeAuth(session: session), repository);
      addTearDown(bloc.close);
      await bloc.login('test@example.com', 'Password123!');

      expect(await bloc.deleteProject('project_1'), isFalse);
      expect(bloc.state.error, contains('Only organization admins'));
    },
  );
}

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.session, this.loginError});
  final Session? session;
  final Object? loginError;
  @override
  Future<Session> login(LoginRequest request) async {
    if (loginError != null) throw loginError!;
    return session!;
  }

  @override
  Future<void> logout() async {}
  @override
  Future<Session> refresh(Session session) async => session;
  @override
  Future<Session?> restoreSession() async => session;
}

class _FakeRepository implements TaskFlowRepository {
  _FakeRepository({this.loadError, this.deleteError});
  Object? loadError;
  Object? deleteError;
  @override
  bool offline = false;
  @override
  String? forcedError;

  void _throwLoadError() {
    if (loadError != null) throw loadError!;
  }

  @override
  Future<List<Project>> projectsForOrg(String orgId) async {
    _throwLoadError();
    return [
      Project(
        id: 'project_1',
        orgId: orgId,
        name: 'Project',
        description: '',
        createdAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async {
    _throwLoadError();
    return [];
  }

  @override
  Future<List<AppUser>> membersForOrg(String orgId) async {
    _throwLoadError();
    return [];
  }

  @override
  Future<void> deleteProject(String id, {required bool isAdmin}) async {
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<TaskItem> assignTask(String taskId, String? userId, String orgId) =>
      throw UnimplementedError();
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
