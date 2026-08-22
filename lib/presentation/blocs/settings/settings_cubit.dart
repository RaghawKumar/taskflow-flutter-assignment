import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/repositories.dart';

class SettingsState {
  const SettingsState({
    this.darkMode = false,
    this.offline = false,
    this.forcedError,
  });
  final bool darkMode, offline;
  final String? forcedError;
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
  void toggleTheme(bool value) => emit(
    SettingsState(
      darkMode: value,
      offline: state.offline,
      forcedError: state.forcedError,
    ),
  );
  void setOffline(bool value) {
    repository.offline = value;
    emit(
      SettingsState(
        darkMode: state.darkMode,
        offline: value,
        forcedError: state.forcedError,
      ),
    );
  }

  void simulateError(String? value) {
    repository.forcedError = value;
    emit(
      SettingsState(
        darkMode: state.darkMode,
        offline: state.offline,
        forcedError: value,
      ),
    );
  }
}
