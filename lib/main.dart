import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/mock_data_source.dart';
import 'data/repositories/local_repositories.dart';
import 'domain/models/models.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/projects/projects_bloc.dart';
import 'presentation/blocs/settings/settings_cubit.dart';
import 'presentation/blocs/tasks/tasks_bloc.dart';
import 'presentation/screens/auth_screens.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final source = AssetMockDataSource();
  final taskRepository = LocalTaskFlowRepository(source);
  runApp(
    TaskFlowApp(
      authBloc: AuthBloc(LocalAuthRepository(source)),
      projectsBloc: ProjectsBloc(taskRepository),
      tasksBloc: TasksBloc(taskRepository),
      settingsCubit: SettingsCubit(taskRepository),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({
    super.key,
    required this.authBloc,
    required this.projectsBloc,
    required this.tasksBloc,
    required this.settingsCubit,
  });
  final AuthBloc authBloc;
  final ProjectsBloc projectsBloc;
  final TasksBloc tasksBloc;
  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc..checkSession()),
      BlocProvider.value(value: projectsBloc),
      BlocProvider.value(value: tasksBloc),
      BlocProvider.value(value: settingsCubit),
    ],
    child: BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.session != current.session,
      listener: (context, state) {
        final session = state.session;
        if (session == null) {
          context.read<ProjectsBloc>().clear();
          context.read<TasksBloc>().clear();
        } else {
          context.read<ProjectsBloc>().load(session.orgId);
          context.read<TasksBloc>().load(session.orgId);
        }
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => BlocBuilder<AuthBloc, AuthState>(
          builder: (context, auth) => MaterialApp(
            title: 'TaskFlow',
            debugShowCheckedModeBanner: false,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: auth.phase == LoadPhase.loading
                ? const SplashScreen()
                : auth.session == null
                ? const LoginScreen()
                : const HomeScreen(),
          ),
        ),
      ),
    ),
  );

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff5b5bd6),
      brightness: brightness,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
    ),
  );
}
