import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class SessionCheckRequested extends AuthEvent {
  const SessionCheckRequested();
}

class LoginRequested extends AuthEvent {
  LoginRequested(this.email, this.password, this.result);
  final String email, password;
  final Completer<bool> result;
}

class LogoutRequested extends AuthEvent {
  LogoutRequested(this.done);
  final Completer<void> done;
}

class AuthState {
  const AuthState({this.phase = LoadPhase.initial, this.session, this.error});
  final LoadPhase phase;
  final Session? session;
  final String? error;
  AuthState copyWith({
    LoadPhase? phase,
    Object? session = _same,
    Object? error = _same,
  }) => AuthState(
    phase: phase ?? this.phase,
    session: identical(session, _same) ? this.session : session as Session?,
    error: identical(error, _same) ? this.error : error as String?,
  );
}

const _same = Object();

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(const AuthState()) {
    on<SessionCheckRequested>(_check);
    on<LoginRequested>(_login);
    on<LogoutRequested>(_logout);
  }
  final AuthRepository repository;
  void checkSession() => add(const SessionCheckRequested());
  Future<bool> login(String email, String password) {
    final result = Completer<bool>();
    add(LoginRequested(email, password, result));
    return result.future;
  }

  Future<void> logout() {
    final done = Completer<void>();
    add(LogoutRequested(done));
    return done.future;
  }

  Future<void> register(String name, String email, String password) async {
    if (name.trim().isEmpty || !email.contains('@') || password.length < 8)
      throw const AppException(
        'Enter a name, valid email, and password of at least 8 characters.',
      );
  }

  Future<void> _check(
    SessionCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(phase: LoadPhase.loading, error: null));
    try {
      emit(
        state.copyWith(
          phase: LoadPhase.success,
          session: await repository.restoreSession(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(phase: LoadPhase.error, session: null, error: '$error'),
      );
    }
  }

  Future<void> _login(LoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(phase: LoadPhase.loading, error: null));
    try {
      final session = await repository.login(
        LoginRequest(event.email.trim(), event.password),
      );
      emit(state.copyWith(phase: LoadPhase.success, session: session));
      event.result.complete(true);
    } catch (error) {
      emit(
        state.copyWith(phase: LoadPhase.error, session: null, error: '$error'),
      );
      event.result.complete(false);
    }
  }

  Future<void> _logout(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(const AuthState(phase: LoadPhase.success));
    event.done.complete();
  }
}
