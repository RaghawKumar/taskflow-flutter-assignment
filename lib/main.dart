import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_localizations.dart';
import 'core/app_colors.dart';
import 'data/datasources/mock_data_source.dart';
import 'data/repositories/local_repositories.dart';
import 'domain/models/models.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/notifications/notifications_bloc.dart';
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
      notificationsBloc: NotificationsBloc(taskRepository),
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
    required this.notificationsBloc,
  });
  final AuthBloc authBloc;
  final ProjectsBloc projectsBloc;
  final TasksBloc tasksBloc;
  final SettingsCubit settingsCubit;
  final NotificationsBloc notificationsBloc;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc..checkSession()),
      BlocProvider.value(value: projectsBloc),
      BlocProvider.value(value: tasksBloc),
      BlocProvider.value(value: settingsCubit),
      BlocProvider.value(value: notificationsBloc),
    ],
    child: BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.session != current.session,
      listener: (context, state) {
        final session = state.session;
        if (session == null) {
          context.read<ProjectsBloc>().clear();
          context.read<TasksBloc>().clear();
          context.read<NotificationsBloc>().clear();
        } else {
          context.read<ProjectsBloc>().load(session.orgId);
          context.read<TasksBloc>().load(session.orgId);
          context.read<NotificationsBloc>().load(session.user.id);
        }
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => BlocBuilder<AuthBloc, AuthState>(
          builder: (context, auth) => MaterialApp(
            title: 'TaskFlow',
            debugShowCheckedModeBanner: false,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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

  ThemeData _theme(Brightness brightness) {
    final scheme = AppColors.scheme(brightness);
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
