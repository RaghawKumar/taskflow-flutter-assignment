import 'package:flutter/material.dart';
import 'data/datasources/mock_data_source.dart';
import 'data/repositories/local_repositories.dart';
import 'domain/models/models.dart';
import 'presentation/controllers/app_controller.dart';
import 'presentation/screens/auth_screens.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/widgets/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final source = AssetMockDataSource();
  runApp(
    TaskFlowApp(
      controller: AppController(
        LocalAuthRepository(source),
        LocalTaskFlowRepository(source),
      ),
    ),
  );
}

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.checkSession();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: widget.controller,
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        themeMode: widget.controller.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: widget.controller.sessionPhase == LoadPhase.loading
            ? const SplashScreen()
            : widget.controller.session == null
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
