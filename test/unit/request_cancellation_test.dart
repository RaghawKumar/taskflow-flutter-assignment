import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/request_cancellation.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/data/repositories/local_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cancellation token interrupts artificial request delay', () async {
    final source = AssetMockDataSource();
    final token = CancellationToken();
    final pending = source.delay(token);
    token.cancel();
    await expectLater(pending, throwsA(isA<RequestCancelledException>()));
  });

  test(
    'new project request cancels the previous request on its channel',
    () async {
      final repository = LocalTaskFlowRepository(AssetMockDataSource());
      final first = repository.projectsForOrg('org_a1b2c3');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = repository.projectsForOrg('org_a1b2c3');

      await expectLater(first, throwsA(isA<RequestCancelledException>()));
      expect(await second, isNotEmpty);
    },
  );
}
