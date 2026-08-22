import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/responsive.dart';

void main() {
  for (final testCase in <(Size, int)>[
    (const Size(360, 640), 1),
    (const Size(800, 1024), 2),
    (const Size(1440, 900), 3),
  ]) {
    testWidgets('uses ${testCase.$2} columns at ${testCase.$1.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = testCase.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                Scaffold(body: Text('${Responsive.columns(context)}')),
          ),
        ),
      );
      expect(find.text('${testCase.$2}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
