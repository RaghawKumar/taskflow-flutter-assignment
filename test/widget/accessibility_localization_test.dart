import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/app_localizations.dart';
import 'package:taskflow/presentation/widgets/skeleton_loading.dart';

void main() {
  testWidgets('Hindi localization resolves navigation labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('hi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _LocalizedLabel(),
      ),
    );
    expect(find.text('प्रोजेक्ट'), findsOneWidget);
  });

  testWidgets('skeleton exposes one live-region loading announcement', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonList(items: 2))),
    );
    expect(find.bySemanticsLabel('Loading content'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('skeleton remains overflow-free at large text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonList(items: 2))),
    );
    expect(tester.takeException(), isNull);
  });
}

class _LocalizedLabel extends StatelessWidget {
  const _LocalizedLabel();
  @override
  Widget build(BuildContext context) => Text(context.l10n.text('projects'));
}
