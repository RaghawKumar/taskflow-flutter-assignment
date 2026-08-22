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
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: scheme.primary,
        selectedIconTheme: IconThemeData(color: scheme.onPrimary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.86),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        prefixIconColor: scheme.primary,
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
