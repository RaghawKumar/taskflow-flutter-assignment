import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/request_cancellation.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

class NotificationsState {
  const NotificationsState({
    this.phase = LoadPhase.initial,
    this.notifications = const [],
    this.error,
  });
  final LoadPhase phase;
  final List<TaskNotification> notifications;
  final String? error;
  int get unreadCount => notifications.where((item) => !item.read).length;
  NotificationsState copyWith({
    LoadPhase? phase,
    List<TaskNotification>? notifications,
    Object? error = _same,
  }) => NotificationsState(
    phase: phase ?? this.phase,
    notifications: notifications ?? this.notifications,
    error: identical(error, _same) ? this.error : error as String?,
  );
}

const _same = Object();

sealed class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationsLoaded extends NotificationsEvent {
  NotificationsLoaded(this.userId, this.done);
  final String userId;
  final Completer<void> done;
}

class NotificationRead extends NotificationsEvent {
  NotificationRead(this.id, this.done);
  final String id;
  final Completer<void> done;
}

class NotificationsCleared extends NotificationsEvent {
  const NotificationsCleared();
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this.repository) : super(const NotificationsState()) {
    on<NotificationsLoaded>(_load);
    on<NotificationRead>(_markRead);
    on<NotificationsCleared>((event, emit) => emit(const NotificationsState()));
  }
  final TaskFlowRepository repository;
  String? _userId;
  Future<void> load(String userId) {
    final done = Completer<void>();
    add(NotificationsLoaded(userId, done));
    return done.future;
  }

  Future<void> markRead(String id) {
    final done = Completer<void>();
    add(NotificationRead(id, done));
    return done.future;
  }

  void clear() => add(const NotificationsCleared());

  Future<void> _load(
    NotificationsLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    _userId = event.userId;
    emit(state.copyWith(phase: LoadPhase.loading, error: null));
    try {
      final data = await repository.notificationsForUser(event.userId);
      emit(
        state.copyWith(
          phase: data.isEmpty ? LoadPhase.empty : LoadPhase.success,
          notifications: data,
        ),
      );
    } on RequestCancelledException {
      // Superseded by a newer inbox refresh.
    } catch (error) {
      emit(state.copyWith(phase: LoadPhase.error, error: '$error'));
    }
    event.done.complete();
  }

  Future<void> _markRead(
    NotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await repository.markNotificationRead(event.id);
      if (_userId != null) {
        final data = await repository.notificationsForUser(_userId!);
        emit(
          state.copyWith(
            phase: data.isEmpty ? LoadPhase.empty : LoadPhase.success,
            notifications: data,
            error: null,
          ),
        );
      }
    } catch (error) {
      emit(state.copyWith(error: '$error'));
    }
    event.done.complete();
  }
}
