import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/repositories.dart';

class SettingsState {
  const SettingsState({
    this.darkMode = false,
    this.offline = false,
    this.forcedError,
    this.locale = const Locale('en'),
  });
  final bool darkMode, offline;
  final String? forcedError;
  final Locale locale;
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.repository)
    : super(
        SettingsState(
          offline: repository.offline,
          forcedError: repository.forcedError,
        ),
      );
  final TaskFlowRepository repository;
  SettingsState _copy({
    bool? darkMode,
    bool? offline,
    Object? forcedError = _same,
    Locale? locale,
  }) => SettingsState(
    darkMode: darkMode ?? state.darkMode,
    offline: offline ?? state.offline,
    forcedError: identical(forcedError, _same)
        ? state.forcedError
        : forcedError as String?,
    locale: locale ?? state.locale,
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
}

const _same = Object();
