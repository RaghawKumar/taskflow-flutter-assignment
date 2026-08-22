import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/data/repositories/local_repositories.dart';
import 'package:taskflow/domain/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'mock refresh issues a distinct access token with renewed expiry',
    () async {
      const storage = FlutterSecureStorage();
      final repository = LocalAuthRepository(
        AssetMockDataSource(),
        storage: storage,
      );
      final session = await repository.login(
        const LoginRequest('ava.admin@nimbusdigital.test', 'Password123!'),
      );
      final original =
          jsonDecode((await storage.read(key: 'taskflow_session'))!)
              as Map<String, dynamic>;

      final refreshed = await repository.refresh(session);
      final updated =
          jsonDecode((await storage.read(key: 'taskflow_session'))!)
              as Map<String, dynamic>;

      expect(updated['access_token'], isNot(original['access_token']));
      expect(updated['access_token'], startsWith('mock.refreshed.'));
      expect(updated['refresh_token'], original['refresh_token']);
      expect(refreshed.expiresAt.isAfter(session.expiresAt), isTrue);
    },
  );

  test('logout removes the complete secure session', () async {
    const storage = FlutterSecureStorage();
    final repository = LocalAuthRepository(
      AssetMockDataSource(),
      storage: storage,
    );
    await repository.login(
      const LoginRequest('ava.admin@nimbusdigital.test', 'Password123!'),
    );

    await repository.logout();
    expect(await storage.read(key: 'taskflow_session'), isNull);
  });
}
