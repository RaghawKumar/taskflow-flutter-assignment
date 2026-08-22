import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

class ProjectsState {
  const ProjectsState({
    this.phase = LoadPhase.initial,
    this.projects = const [],
    this.error,
  });
  final LoadPhase phase;
  final List<Project> projects;
  final String? error;
  ProjectsState copyWith({
    LoadPhase? phase,
    List<Project>? projects,
    Object? error = _same,
  }) => ProjectsState(
    phase: phase ?? this.phase,
    projects: projects ?? this.projects,
    error: identical(error, _same) ? this.error : error as String?,
  );
}

const _same = Object();

sealed class ProjectsEvent {
  const ProjectsEvent();
}

class ProjectsLoaded extends ProjectsEvent {
  ProjectsLoaded(this.orgId, this.done);
  final String orgId;
  final Completer<void> done;
}

class ProjectSaved extends ProjectsEvent {
  ProjectSaved(this.orgId, this.request, this.id, this.result);
  final String orgId;
  final ProjectRequest request;
  final String? id;
  final Completer<bool> result;
}

class ProjectDeleted extends ProjectsEvent {
  ProjectDeleted(this.id, this.isAdmin, this.result);
  final String id;
  final bool isAdmin;
  final Completer<bool> result;
}

class ProjectsCleared extends ProjectsEvent {
  const ProjectsCleared();
}

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  ProjectsBloc(this.repository) : super(const ProjectsState()) {
    on<ProjectsLoaded>(_load);
    on<ProjectSaved>(_save);
    on<ProjectDeleted>(_delete);
    on<ProjectsCleared>((event, emit) => emit(const ProjectsState()));
  }
  final TaskFlowRepository repository;
  String? _orgId;
  Future<void> load(String orgId) {
    final done = Completer<void>();
    add(ProjectsLoaded(orgId, done));
    return done.future;
  }

  Future<bool> save(String orgId, ProjectRequest request, {String? id}) {
    final result = Completer<bool>();
    add(ProjectSaved(orgId, request, id, result));
    return result.future;
  }

  Future<bool> delete(String id, {required bool isAdmin}) {
    final result = Completer<bool>();
    add(ProjectDeleted(id, isAdmin, result));
    return result.future;
  }

  void clear() => add(const ProjectsCleared());
  Future<void> _load(ProjectsLoaded event, Emitter<ProjectsState> emit) async {
    _orgId = event.orgId;
    emit(state.copyWith(phase: LoadPhase.loading, error: null));
    try {
      final data = await repository.projectsForOrg(event.orgId);
      emit(
        state.copyWith(
          phase: data.isEmpty ? LoadPhase.empty : LoadPhase.success,
          projects: data,
        ),
      );
    } catch (error) {
      emit(state.copyWith(phase: LoadPhase.error, error: '$error'));
    }
    event.done.complete();
  }

  Future<bool> _mutate(
    Emitter<ProjectsState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (_orgId != null) {
        final data = await repository.projectsForOrg(_orgId!);
        emit(
          state.copyWith(
            phase: data.isEmpty ? LoadPhase.empty : LoadPhase.success,
            projects: data,
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

  Future<void> _save(ProjectSaved e, Emitter<ProjectsState> emit) async {
    _orgId = e.orgId;
    e.result.complete(
      await _mutate(emit, () async {
        await repository.saveProject(e.orgId, e.request, id: e.id);
      }),
    );
  }

  Future<void> _delete(ProjectDeleted e, Emitter<ProjectsState> emit) async {
    e.result.complete(
      await _mutate(
        emit,
        () => repository.deleteProject(e.id, isAdmin: e.isAdmin),
      ),
    );
  }
}
