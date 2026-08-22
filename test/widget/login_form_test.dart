import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taskflow/core/app_localizations.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/blocs/auth/auth_bloc.dart';
import 'package:taskflow/presentation/screens/auth_screens.dart';

void main() {
  testWidgets('login form displays meaningful validation', (tester) async {
    final bloc = AuthBloc(_FakeAuth());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LoginScreen(),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.textContaining('Password123!'), findsNothing);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    final background = tester.widget<Image>(find.byType(Image));
    expect(
      (background.image as AssetImage).assetName,
      'assets/branding/taskflow_login_background_v2.png',
    );
  });
}

class _FakeAuth implements AuthRepository {
  @override
  Future<Session> login(LoginRequest request) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<Session> refresh(Session session) async => session;
  @override
  Future<Session?> restoreSession() async => null;
}
