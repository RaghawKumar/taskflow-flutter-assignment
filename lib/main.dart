import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/mock_data_source.dart';
import 'data/repositories/local_repositories.dart';
import 'domain/models/models.dart';
import 'presentation/controllers/app_bloc.dart';
import 'presentation/screens/auth_screens.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/widgets/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final source = AssetMockDataSource();
  runApp(
    TaskFlowApp(
      bloc: AppBloc(
        LocalAuthRepository(source),
        LocalTaskFlowRepository(source),
      ),
    ),
  );
}

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key, required this.bloc});
  final AppBloc bloc;
  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  @override
  void initState() {
    super.initState();
    widget.bloc.checkSession();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    bloc: widget.bloc,
    child: BlocBuilder<AppBloc, AppState>(
      builder: (context, state) => MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: state.sessionPhase == LoadPhase.loading
            ? const SplashScreen()
            : state.session == null
            ? const LoginScreen()
            : const HomeScreen(),
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
