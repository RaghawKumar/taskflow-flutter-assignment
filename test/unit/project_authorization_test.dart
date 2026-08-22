import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/data/repositories/local_repositories.dart';
import 'package:taskflow/core/request_cancellation.dart';
import 'package:taskflow/domain/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('repository rejects project deletion by a non-admin actor', () async {
    final repository = LocalTaskFlowRepository(_FastAssetSource());
    await expectLater(
      repository.deleteProject('proj_1001', actorUserId: 'user_002'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('Only organization admins'),
        ),
      ),
    );
  });

  test(
    'repository permits project deletion by the organization admin',
    () async {
      final repository = LocalTaskFlowRepository(_FastAssetSource());
      await repository.deleteProject('proj_1001', actorUserId: 'user_001');
      expect(
        (await repository.projectsForOrg(
          'org_a1b2c3',
        )).any((project) => project.id == 'proj_1001'),
        isFalse,
      );
    },
  );

  test(
    'member management is admin enforced and unassigns removed member',
    () async {
      final source = _FastAssetSource();
      final repository = LocalTaskFlowRepository(source);
      await expectLater(
        repository.removeMember(
          'org_a1b2c3',
          'user_003',
          actorUserId: 'user_002',
        ),
        throwsA(isA<AppException>()),
      );

      await repository.removeMember(
        'org_a1b2c3',
        'user_003',
        actorUserId: 'user_001',
      );
      expect(
        (await repository.membersForOrg(
          'org_a1b2c3',
        )).any((member) => member.id == 'user_003'),
        isFalse,
      );
      expect(
        (await source.load()).tasks.where(
          (task) => task.assigneeId == 'user_003',
        ),
        isEmpty,
      );
    },
  );
}

class _FastAssetSource extends AssetMockDataSource {
  @override
  Future<void> delay([CancellationToken? cancellationToken]) async {
    cancellationToken?.throwIfCancelled();
    if (offline) throw const AppException('Offline');
    if (forcedError != null) throw AppException(forcedError!);
  }
}
