import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/session_activity_monitor.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/domain/services/biometric_service.dart';
import 'package:taskflow/presentation/blocs/auth/auth_bloc.dart';

void main() {
  test('restored session is released only after biometric success', () async {
    final biometrics = _FakeBiometricService(outcomes: [true]);
    final bloc = AuthBloc(
      _SessionRepository(),
      biometricService: biometrics,
      sessionCheckDelay: Duration.zero,
    );
    addTearDown(bloc.close);

    bloc.checkSession();
    await bloc.stream.firstWhere(
      (state) => state.phase == LoadPhase.success && state.session != null,
    );

    expect(bloc.state.session?.user.id, 'user_1');
    expect(bloc.state.biometricRequired, isFalse);
    expect(biometrics.authenticateCalls, 1);
  });

  test('cancelled biometric unlock can be retried', () async {
    final biometrics = _FakeBiometricService(outcomes: [false, true]);
    final bloc = AuthBloc(
      _SessionRepository(),
      biometricService: biometrics,
      sessionCheckDelay: Duration.zero,
    );
    addTearDown(bloc.close);

    bloc.checkSession();
    await bloc.stream.firstWhere((state) => state.biometricRequired);
    expect(bloc.state.session, isNull);

    expect(await bloc.unlockWithBiometrics(), isTrue);
    expect(bloc.state.session?.user.id, 'user_1');
    expect(bloc.state.biometricRequired, isFalse);
  });

  test('inactivity controller triggers automatic timeout', () async {
    final timedOut = Completer<void>();
    final controller = InactivityController(
      duration: const Duration(milliseconds: 20),
      onTimeout: timedOut.complete,
    )..start();
    addTearDown(controller.dispose);

    await timedOut.future.timeout(const Duration(seconds: 1));
    expect(timedOut.isCompleted, isTrue);
  });

  test('activity resets the automatic timeout', () async {
    var timeoutCount = 0;
    final controller = InactivityController(
      duration: const Duration(milliseconds: 50),
      onTimeout: () => timeoutCount++,
    )..start();
    addTearDown(controller.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    controller.recordActivity();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(timeoutCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(timeoutCount, 1);
  });
}

class _FakeBiometricService implements BiometricService {
  _FakeBiometricService({required this.outcomes});

  final List<bool> outcomes;
  int authenticateCalls = 0;

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    return outcomes.removeAt(0);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> isEnabled() async => true;

  @override
  Future<void> setEnabled(bool enabled) async {}
}

class _SessionRepository implements AuthRepository {
  final session = Session(
    user: const AppUser(
      id: 'user_1',
      name: 'Test User',
      email: 'user@example.com',
    ),
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
