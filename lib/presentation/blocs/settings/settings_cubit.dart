import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/services/biometric_service.dart';

class SettingsState {
  const SettingsState({
    this.darkMode = false,
    this.offline = false,
    this.forcedError,
    this.locale = const Locale('en'),
    this.biometricEnabled = false,
    this.biometricAvailable,
  });
  final bool darkMode, offline, biometricEnabled;
  final bool? biometricAvailable;
  final String? forcedError;
  final Locale locale;
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this.repository, {
    this.biometricService = const DisabledBiometricService(),
  }) : super(
         SettingsState(
           offline: repository.offline,
           forcedError: repository.forcedError,
         ),
       );
  final TaskFlowRepository repository;
  final BiometricService biometricService;
  SettingsState _copy({
    bool? darkMode,
    bool? offline,
    Object? forcedError = _same,
    Locale? locale,
    bool? biometricEnabled,
    Object? biometricAvailable = _same,
  }) => SettingsState(
    darkMode: darkMode ?? state.darkMode,
    offline: offline ?? state.offline,
    forcedError: identical(forcedError, _same)
        ? state.forcedError
        : forcedError as String?,
    locale: locale ?? state.locale,
    biometricEnabled: biometricEnabled ?? state.biometricEnabled,
    biometricAvailable: identical(biometricAvailable, _same)
        ? state.biometricAvailable
        : biometricAvailable as bool?,
  );
  void toggleTheme(bool value) => emit(_copy(darkMode: value));
  void setOffline(bool value) {
    repository.offline = value;
    emit(_copy(offline: value));
  }

  void simulateError(String? value) {
    repository.forcedError = value;
    emit(_copy(forcedError: value));
  }

  void setLocale(Locale locale) => emit(_copy(locale: locale));

  Future<void> loadSecuritySettings() async {
    final available = await biometricService.isAvailable();
    final enabled = available && await biometricService.isEnabled();
    if (!available && await biometricService.isEnabled()) {
      await biometricService.setEnabled(false);
    }
    emit(_copy(biometricAvailable: available, biometricEnabled: enabled));
  }

  Future<String?> setBiometricEnabled(bool enabled) async {
    if (!enabled) {
      await biometricService.setEnabled(false);
      emit(_copy(biometricEnabled: false));
      return null;
    }
    if (!await biometricService.isAvailable()) {
      emit(_copy(biometricAvailable: false, biometricEnabled: false));
      return 'No enrolled fingerprint or face authentication is available.';
    }
    if (!await biometricService.authenticate()) {
      return 'Biometric verification was cancelled or unsuccessful.';
    }
    await biometricService.setEnabled(true);
    emit(_copy(biometricAvailable: true, biometricEnabled: true));
    return null;
  }
}

const _same = Object();
