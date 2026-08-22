import 'package:flutter/foundation.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

class AppController extends ChangeNotifier {
  AppController(this.auth, this.repository);
  final AuthRepository auth;
  final TaskFlowRepository repository;
  LoadPhase sessionPhase = LoadPhase.initial;
  LoadPhase dataPhase = LoadPhase.initial;
  Session? session;
  List<Project> projects = [];
  List<TaskItem> tasks = [];
  List<AppUser> members = [];
  TaskFilter filter = const TaskFilter();
  String? error;
  bool darkMode = false;

  List<TaskItem> get filteredTasks => tasks.where(filter.matches).toList();
  bool get offline => repository.offline;
  String? userName(String? id) =>
      id == null ? null : members.where((u) => u.id == id).firstOrNull?.name;
  int taskCount(String projectId) =>
      tasks.where((t) => t.projectId == projectId).length;

  Future<void> checkSession() async {
    sessionPhase = LoadPhase.loading;
    notifyListeners();
    try {
      session = await auth.restoreSession();
      sessionPhase = LoadPhase.success;
      if (session != null) await loadAll();
    } catch (e) {
      error = '$e';
      sessionPhase = LoadPhase.error;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    sessionPhase = LoadPhase.loading;
    error = null;
    notifyListeners();
    try {
      session = await auth.login(LoginRequest(email.trim(), password));
      sessionPhase = LoadPhase.success;
      await loadAll();
      return true;
    } catch (e) {
      error = '$e';
      sessionPhase = LoadPhase.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (name.trim().isEmpty || !email.contains('@') || password.length < 8)
      throw const AppException(
        'Enter a name, valid email, and password of at least 8 characters.',
      );
  }

  Future<void> logout() async {
    await auth.logout();
    session = null;
    projects = [];
    tasks = [];
    sessionPhase = LoadPhase.success;
    notifyListeners();
  }

  Future<void> loadAll() async {
    if (session == null) return;
    dataPhase = LoadPhase.loading;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.projectsForOrg(session!.orgId),
        repository.tasksForOrg(session!.orgId),
        repository.membersForOrg(session!.orgId),
      ]);
      projects = results[0] as List<Project>;
      tasks = results[1] as List<TaskItem>;
      members = results[2] as List<AppUser>;
      dataPhase = projects.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (e) {
      error = '$e';
      dataPhase = LoadPhase.error;
    }
    notifyListeners();
  }

  Future<void> setOffline(bool value) async {
    repository.offline = value;
    notifyListeners();
    if (!value) await loadAll();
  }

  void setFilter(TaskFilter value) {
    filter = value;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    darkMode = value;
    notifyListeners();
  }

  void simulateError(String? value) {
    repository.forcedError = value;
    notifyListeners();
  }

  Future<bool> saveProject(ProjectRequest request, {String? id}) =>
      _mutate(() async {
        await repository.saveProject(session!.orgId, request, id: id);
      });
  Future<bool> deleteProject(String id) => _mutate(
    () => repository.deleteProject(id, isAdmin: session?.isAdmin ?? false),
  );
  Future<bool> saveTask(String projectId, TaskRequest request, {String? id}) =>
      _mutate(() => repository.saveTask(projectId, request, id: id));
  Future<bool> deleteTask(String id) =>
      _mutate(() => repository.deleteTask(id));
  Future<bool> assign(String id, String? userId) =>
      _mutate(() => repository.assignTask(id, userId, session!.orgId));
  Future<bool> _mutate(Future<void> Function() operation) async {
    error = null;
    try {
      await operation();
      await loadAll();
      return true;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return false;
    }
  }
}
