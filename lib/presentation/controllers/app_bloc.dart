import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

class AppState {
  const AppState({
    this.sessionPhase = LoadPhase.initial,
    this.dataPhase = LoadPhase.initial,
    this.session,
    this.projects = const [],
    this.tasks = const [],
    this.members = const [],
    this.filter = const TaskFilter(),
    this.error,
    this.darkMode = false,
    this.offline = false,
    this.forcedError,
  });
  final LoadPhase sessionPhase;
  final LoadPhase dataPhase;
  final Session? session;
  final List<Project> projects;
  final List<TaskItem> tasks;
  final List<AppUser> members;
  final TaskFilter filter;
  final String? error;
  final bool darkMode;
  final bool offline;
  final String? forcedError;

  AppState copyWith({
    LoadPhase? sessionPhase,
    LoadPhase? dataPhase,
    Object? session = _unchanged,
    List<Project>? projects,
    List<TaskItem>? tasks,
    List<AppUser>? members,
    TaskFilter? filter,
    Object? error = _unchanged,
    bool? darkMode,
    bool? offline,
    Object? forcedError = _unchanged,
  }) => AppState(
    sessionPhase: sessionPhase ?? this.sessionPhase,
    dataPhase: dataPhase ?? this.dataPhase,
    session: identical(session, _unchanged)
        ? this.session
        : session as Session?,
    projects: projects ?? this.projects,
    tasks: tasks ?? this.tasks,
    members: members ?? this.members,
    filter: filter ?? this.filter,
    error: identical(error, _unchanged) ? this.error : error as String?,
    darkMode: darkMode ?? this.darkMode,
    offline: offline ?? this.offline,
    forcedError: identical(forcedError, _unchanged)
        ? this.forcedError
        : forcedError as String?,
  );
}

const _unchanged = Object();

sealed class AppEvent {
  const AppEvent();
}

class SessionChecked extends AppEvent {
  const SessionChecked();
}

class LoginSubmitted extends AppEvent {
  LoginSubmitted(this.email, this.password, this.result);
  final String email, password;
  final Completer<bool> result;
}

class LogoutRequested extends AppEvent {
  LogoutRequested(this.done);
  final Completer<void> done;
}

class DataRefreshed extends AppEvent {
  DataRefreshed(this.done);
  final Completer<void> done;
}

class ProjectSaved extends AppEvent {
  ProjectSaved(this.request, this.id, this.result);
  final ProjectRequest request;
  final String? id;
  final Completer<bool> result;
}

class ProjectDeleted extends AppEvent {
  ProjectDeleted(this.id, this.result);
  final String id;
  final Completer<bool> result;
}

class TaskSaved extends AppEvent {
  TaskSaved(this.projectId, this.request, this.id, this.result);
  final String projectId;
  final TaskRequest request;
  final String? id;
  final Completer<bool> result;
}

class TaskDeleted extends AppEvent {
  TaskDeleted(this.id, this.result);
  final String id;
  final Completer<bool> result;
}

class TaskAssigned extends AppEvent {
  TaskAssigned(this.id, this.userId, this.result);
  final String id;
  final String? userId;
  final Completer<bool> result;
}

class FilterChanged extends AppEvent {
  const FilterChanged(this.filter);
  final TaskFilter filter;
}

class ThemeChanged extends AppEvent {
  const ThemeChanged(this.value);
  final bool value;
}

class OfflineChanged extends AppEvent {
  OfflineChanged(this.value, this.done);
  final bool value;
  final Completer<void> done;
}

class ForcedErrorChanged extends AppEvent {
  const ForcedErrorChanged(this.value);
  final String? value;
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(this.auth, this.repository)
    : super(
        AppState(
          offline: repository.offline,
          forcedError: repository.forcedError,
        ),
      ) {
    on<SessionChecked>(_onSessionChecked);
    on<LoginSubmitted>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<DataRefreshed>(_onRefresh);
    on<ProjectSaved>(_onProjectSaved);
    on<ProjectDeleted>(_onProjectDeleted);
    on<TaskSaved>(_onTaskSaved);
    on<TaskDeleted>(_onTaskDeleted);
    on<TaskAssigned>(_onTaskAssigned);
    on<FilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<ThemeChanged>(
      (event, emit) => emit(state.copyWith(darkMode: event.value)),
    );
    on<OfflineChanged>(_onOfflineChanged);
    on<ForcedErrorChanged>((event, emit) {
      repository.forcedError = event.value;
      emit(state.copyWith(forcedError: event.value));
    });
  }
  final AuthRepository auth;
  final TaskFlowRepository repository;

  LoadPhase get sessionPhase => state.sessionPhase;
  LoadPhase get dataPhase => state.dataPhase;
  Session? get session => state.session;
  List<Project> get projects => state.projects;
  List<TaskItem> get tasks => state.tasks;
  List<AppUser> get members => state.members;
  TaskFilter get filter => state.filter;
  String? get error => state.error;
  bool get darkMode => state.darkMode;
  bool get offline => state.offline;
  List<TaskItem> get filteredTasks => tasks.where(filter.matches).toList();
  String? userName(String? id) =>
      id == null ? null : members.where((u) => u.id == id).firstOrNull?.name;
  int taskCount(String projectId) =>
      tasks.where((t) => t.projectId == projectId).length;

  void checkSession() => add(const SessionChecked());
  Future<bool> login(String email, String password) {
    final result = Completer<bool>();
    add(LoginSubmitted(email, password, result));
    return result.future;
  }

  Future<void> register(String name, String email, String password) async {
    if (name.trim().isEmpty || !email.contains('@') || password.length < 8)
      throw const AppException(
        'Enter a name, valid email, and password of at least 8 characters.',
      );
  }

  Future<void> logout() {
    final done = Completer<void>();
    add(LogoutRequested(done));
    return done.future;
  }

  Future<void> loadAll() {
    final done = Completer<void>();
    add(DataRefreshed(done));
    return done.future;
  }

  Future<void> setOffline(bool value) {
    final done = Completer<void>();
    add(OfflineChanged(value, done));
    return done.future;
  }

  void setFilter(TaskFilter value) => add(FilterChanged(value));
  void toggleTheme(bool value) => add(ThemeChanged(value));
  void simulateError(String? value) => add(ForcedErrorChanged(value));
  Future<bool> saveProject(ProjectRequest request, {String? id}) {
    final result = Completer<bool>();
    add(ProjectSaved(request, id, result));
    return result.future;
  }

  Future<bool> deleteProject(String id) {
    final result = Completer<bool>();
    add(ProjectDeleted(id, result));
    return result.future;
  }

  Future<bool> saveTask(String projectId, TaskRequest request, {String? id}) {
    final result = Completer<bool>();
    add(TaskSaved(projectId, request, id, result));
    return result.future;
  }

  Future<bool> deleteTask(String id) {
    final result = Completer<bool>();
    add(TaskDeleted(id, result));
    return result.future;
  }

  Future<bool> assign(String id, String? userId) {
    final result = Completer<bool>();
    add(TaskAssigned(id, userId, result));
    return result.future;
  }

  Future<void> _onSessionChecked(
    SessionChecked event,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(sessionPhase: LoadPhase.loading, error: null));
    try {
      final restored = await auth.restoreSession();
      emit(state.copyWith(session: restored, sessionPhase: LoadPhase.success));
      if (restored != null) await _loadData(emit);
    } catch (error) {
      emit(state.copyWith(sessionPhase: LoadPhase.error, error: '$error'));
    }
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AppState> emit) async {
    emit(state.copyWith(sessionPhase: LoadPhase.loading, error: null));
    try {
      final active = await auth.login(
        LoginRequest(event.email.trim(), event.password),
      );
      emit(state.copyWith(session: active, sessionPhase: LoadPhase.success));
      await _loadData(emit);
      event.result.complete(true);
    } catch (error) {
      emit(state.copyWith(sessionPhase: LoadPhase.error, error: '$error'));
      event.result.complete(false);
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AppState> emit) async {
    await auth.logout();
    emit(
      state.copyWith(
        session: null,
        projects: [],
        tasks: [],
        members: [],
        sessionPhase: LoadPhase.success,
      ),
    );
    event.done.complete();
  }

  Future<void> _onRefresh(DataRefreshed event, Emitter<AppState> emit) async {
    await _loadData(emit);
    event.done.complete();
  }

  Future<void> _loadData(Emitter<AppState> emit) async {
    final active = state.session;
    if (active == null) return;
    emit(state.copyWith(dataPhase: LoadPhase.loading, error: null));
    try {
      final results = await Future.wait([
        repository.projectsForOrg(active.orgId),
        repository.tasksForOrg(active.orgId),
        repository.membersForOrg(active.orgId),
      ]);
      final projects = results[0] as List<Project>;
      emit(
        state.copyWith(
          projects: projects,
          tasks: results[1] as List<TaskItem>,
          members: results[2] as List<AppUser>,
          dataPhase: projects.isEmpty ? LoadPhase.empty : LoadPhase.success,
        ),
      );
    } catch (error) {
      emit(state.copyWith(dataPhase: LoadPhase.error, error: '$error'));
    }
  }

  Future<bool> _mutate(
    Emitter<AppState> emit,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      await _loadData(emit);
      return true;
    } catch (error) {
      emit(state.copyWith(error: '$error'));
      return false;
    }
  }

  Future<void> _onProjectSaved(ProjectSaved e, Emitter<AppState> emit) async {
    e.result.complete(
      await _mutate(emit, () async {
        await repository.saveProject(state.session!.orgId, e.request, id: e.id);
      }),
    );
  }

  Future<void> _onProjectDeleted(
    ProjectDeleted e,
    Emitter<AppState> emit,
  ) async {
    e.result.complete(
      await _mutate(
        emit,
        () => repository.deleteProject(
          e.id,
          isAdmin: state.session?.isAdmin ?? false,
        ),
      ),
    );
  }

  Future<void> _onTaskSaved(TaskSaved e, Emitter<AppState> emit) async {
    e.result.complete(
      await _mutate(emit, () async {
        await repository.saveTask(e.projectId, e.request, id: e.id);
      }),
    );
  }

  Future<void> _onTaskDeleted(TaskDeleted e, Emitter<AppState> emit) async {
    e.result.complete(await _mutate(emit, () => repository.deleteTask(e.id)));
  }

  Future<void> _onTaskAssigned(TaskAssigned e, Emitter<AppState> emit) async {
    e.result.complete(
      await _mutate(emit, () async {
        await repository.assignTask(e.id, e.userId, state.session!.orgId);
      }),
    );
  }

  Future<void> _onOfflineChanged(
    OfflineChanged e,
    Emitter<AppState> emit,
  ) async {
    repository.offline = e.value;
    emit(state.copyWith(offline: e.value));
    if (!e.value) await _loadData(emit);
    e.done.complete();
  }
}
