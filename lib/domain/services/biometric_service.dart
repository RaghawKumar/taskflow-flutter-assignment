abstract interface class BiometricService {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<bool> isAvailable();
  Future<bool> authenticate();
}

class DisabledBiometricService implements BiometricService {
  const DisabledBiometricService();

  @override
  Future<bool> authenticate() async => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool enabled) async {}
}
