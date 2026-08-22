import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/request_cancellation.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

class TasksState {
  const TasksState({
    this.phase = LoadPhase.initial,
    this.tasks = const [],
    this.members = const [],
    this.filter = const TaskFilter(),
    this.error,
  });
  final LoadPhase phase;
  final List<TaskItem> tasks;
  final List<AppUser> members;
  final TaskFilter filter;
  final String? error;
  List<TaskItem> get filtered => tasks.where(filter.matches).toList();
  TasksState copyWith({
    LoadPhase? phase,
    List<TaskItem>? tasks,
    List<AppUser>? members,
    TaskFilter? filter,
    Object? error = _same,
  }) => TasksState(
    phase: phase ?? this.phase,
    tasks: tasks ?? this.tasks,
    members: members ?? this.members,
    filter: filter ?? this.filter,
    error: identical(error, _same) ? this.error : error as String?,
  );
}

const _same = Object();

sealed class TasksEvent {
  const TasksEvent();
}

class TasksLoaded extends TasksEvent {
  TasksLoaded(this.orgId, this.done);
  final String orgId;
  final Completer<void> done;
}

class TaskSaved extends TasksEvent {
  TaskSaved(this.projectId, this.request, this.id, this.result);
  final String projectId;
  final TaskRequest request;
  final String? id;
  final Completer<bool> result;
}

class TaskDeleted extends TasksEvent {
  TaskDeleted(this.id, this.result);
  final String id;
  final Completer<bool> result;
}

class TaskAssigned extends TasksEvent {
  TaskAssigned(this.id, this.userId, this.result);
  final String id;
  final String? userId;
  final Completer<bool> result;
}

class TaskFilterChanged extends TasksEvent {
  const TaskFilterChanged(this.filter);
  final TaskFilter filter;
}

class MemberRemoved extends TasksEvent {
  MemberRemoved(this.memberUserId, this.actorUserId, this.result);
  final String memberUserId;
  final String actorUserId;
  final Completer<bool> result;
}

class TasksCleared extends TasksEvent {
  const TasksCleared();
}

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc(this.repository) : super(const TasksState()) {
    on<TasksLoaded>(_load);
    on<TaskSaved>(_save);
    on<TaskDeleted>(_delete);
    on<TaskAssigned>(_assign);
    on<MemberRemoved>(_removeMember);
    on<TaskFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
    on<TasksCleared>((e, emit) => emit(const TasksState()));
  }
  final TaskFlowRepository repository;
  String? _orgId;
  Future<void> load(String orgId) {
    final done = Completer<void>();
    add(TasksLoaded(orgId, done));
    return done.future;
  }

  void setFilter(TaskFilter filter) => add(TaskFilterChanged(filter));
  void clear() => add(const TasksCleared());
  Future<bool> save(String projectId, TaskRequest request, {String? id}) {
    final result = Completer<bool>();
    add(TaskSaved(projectId, request, id, result));
    return result.future;
  }

  Future<bool> delete(String id) {
    final result = Completer<bool>();
    add(TaskDeleted(id, result));
    return result.future;
  }

  Future<bool> assign(String id, String? userId) {
    final result = Completer<bool>();
    add(TaskAssigned(id, userId, result));
    return result.future;
  }

  Future<bool> removeMember(
    String memberUserId, {
    required String actorUserId,
  }) {
    final result = Completer<bool>();
    add(MemberRemoved(memberUserId, actorUserId, result));
    return result.future;
  }

  String? userName(String? id) => id == null
      ? null
      : state.members.where((u) => u.id == id).firstOrNull?.name;
  int countForProject(String id) =>
      state.tasks.where((t) => t.projectId == id).length;
  Future<void> _load(TasksLoaded e, Emitter<TasksState> emit) async {
    _orgId = e.orgId;
    emit(state.copyWith(phase: LoadPhase.loading, error: null));
    try {
      final results = await Future.wait([
        repository.tasksForOrg(e.orgId),
        repository.membersForOrg(e.orgId),
      ]);
      final tasks = results[0] as List<TaskItem>;
      emit(
        state.copyWith(
          phase: tasks.isEmpty ? LoadPhase.empty : LoadPhase.success,
          tasks: tasks,
          members: results[1] as List<AppUser>,
        ),
      );
    } on RequestCancelledException {
      // A newer refresh superseded this load; keep the latest state untouched.
    } catch (error) {
      emit(state.copyWith(phase: LoadPhase.error, error: '$error'));
    }
    e.done.complete();
  }

  Future<bool> _mutate(
    Emitter<TasksState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (_orgId != null) {
        final results = await Future.wait([
          repository.tasksForOrg(_orgId!),
          repository.membersForOrg(_orgId!),
        ]);
        final tasks = results[0] as List<TaskItem>;
        emit(
          state.copyWith(
            phase: tasks.isEmpty ? LoadPhase.empty : LoadPhase.success,
            tasks: tasks,
            members: results[1] as List<AppUser>,
            error: null,
          ),
        );
      }
      return true;
    } catch (error) {
      emit(state.copyWith(error: '$error'));
      return false;
    }
  }

  Future<void> _save(TaskSaved e, Emitter<TasksState> emit) async {
    e.result.complete(
      await _mutate(emit, () async {
        await repository.saveTask(e.projectId, e.request, id: e.id);
      }),
    );
  }

  Future<void> _delete(TaskDeleted e, Emitter<TasksState> emit) async {
    e.result.complete(await _mutate(emit, () => repository.deleteTask(e.id)));
  }

  Future<void> _assign(TaskAssigned e, Emitter<TasksState> emit) async {
    e.result.complete(
      await _mutate(emit, () async {
        await repository.assignTask(e.id, e.userId, _orgId!);
      }),
    );
  }

  Future<void> _removeMember(MemberRemoved e, Emitter<TasksState> emit) async {
    e.result.complete(
      await _mutate(
        emit,
        () => repository.removeMember(
          _orgId!,
          e.memberUserId,
          actorUserId: e.actorUserId,
        ),
      ),
    );
  }
}
