import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/services/biometric_service.dart';

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

class BiometricUnlockRequested extends AuthEvent {
  BiometricUnlockRequested(this.result);
  final Completer<bool> result;
}

class AuthState {
  const AuthState({
    this.phase = LoadPhase.initial,
    this.session,
    this.error,
    this.biometricRequired = false,
    this.biometricError,
  });
  final LoadPhase phase;
  final Session? session;
  final String? error;
  final bool biometricRequired;
  final String? biometricError;
  AuthState copyWith({
    LoadPhase? phase,
    Object? session = _same,
    Object? error = _same,
    bool? biometricRequired,
    Object? biometricError = _same,
  }) => AuthState(
    phase: phase ?? this.phase,
    session: identical(session, _same) ? this.session : session as Session?,
    error: identical(error, _same) ? this.error : error as String?,
    biometricRequired: biometricRequired ?? this.biometricRequired,
    biometricError: identical(biometricError, _same)
        ? this.biometricError
        : biometricError as String?,
  );
}

const _same = Object();

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this.repository, {
    this.biometricService = const DisabledBiometricService(),
    this.sessionCheckDelay = const Duration(milliseconds: 900),
  }) : super(const AuthState()) {
    on<SessionCheckRequested>(_check);
    on<LoginRequested>(_login);
    on<LogoutRequested>(_logout);
    on<BiometricUnlockRequested>(_unlockWithBiometrics);
  }
  final AuthRepository repository;
  final BiometricService biometricService;
  final Duration sessionCheckDelay;
  Session? _pendingBiometricSession;
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

  Future<bool> unlockWithBiometrics() {
    final result = Completer<bool>();
    add(BiometricUnlockRequested(result));
    return result.future;
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
      // Keep the branded startup state visible long enough to avoid a flash
      // when secure-storage restoration completes before the first UI frame.
      final restored = repository.restoreSession();
      final results = await Future.wait<Object?>([
        restored,
        Future<void>.delayed(sessionCheckDelay),
      ]);
      final session = results.first as Session?;
      if (session != null && await biometricService.isEnabled()) {
        if (await biometricService.isAvailable()) {
          _pendingBiometricSession = session;
          final unlocked = await biometricService.authenticate();
          if (!unlocked) {
            emit(
              state.copyWith(
                phase: LoadPhase.success,
                session: null,
                biometricRequired: true,
                biometricError:
                    'Biometric unlock was cancelled. Try again or sign in with your password.',
              ),
            );
            return;
          }
          _pendingBiometricSession = null;
        } else {
          await biometricService.setEnabled(false);
        }
      }
      emit(
        state.copyWith(
          phase: LoadPhase.success,
          session: session,
          biometricRequired: false,
          biometricError: null,
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
      _pendingBiometricSession = null;
      emit(
        state.copyWith(
          phase: LoadPhase.success,
          session: session,
          biometricRequired: false,
          biometricError: null,
        ),
      );
      event.result.complete(true);
    } catch (error) {
      emit(
        state.copyWith(phase: LoadPhase.error, session: null, error: '$error'),
      );
      event.result.complete(false);
    }
  }

  Future<void> _logout(LogoutRequested event, Emitter<AuthState> emit) async {
    _pendingBiometricSession = null;
    await repository.logout();
    emit(const AuthState(phase: LoadPhase.success));
    event.done.complete();
  }

  Future<void> _unlockWithBiometrics(
    BiometricUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    final pending = _pendingBiometricSession;
    if (pending == null || !await biometricService.isAvailable()) {
      emit(
        state.copyWith(
          biometricRequired: false,
          biometricError:
              'Biometric authentication is not available on this device.',
        ),
      );
      event.result.complete(false);
      return;
    }
    emit(state.copyWith(phase: LoadPhase.loading, biometricError: null));
    final unlocked = await biometricService.authenticate();
    if (unlocked) {
      _pendingBiometricSession = null;
      emit(
        state.copyWith(
          phase: LoadPhase.success,
          session: pending,
          biometricRequired: false,
          biometricError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          phase: LoadPhase.success,
          session: null,
          biometricRequired: true,
          biometricError:
              'Biometric unlock failed. Try again or sign in with your password.',
        ),
      );
    }
    event.result.complete(unlocked);
  }
}
