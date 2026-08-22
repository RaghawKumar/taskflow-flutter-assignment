import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/request_cancellation.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/data/repositories/local_repositories.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/presentation/blocs/notifications/notifications_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifications are scoped to the authenticated user', () async {
    final repository = LocalTaskFlowRepository(_FastAssetSource());
    final notifications = await repository.notificationsForUser('user_002');
    expect(notifications, hasLength(1));
    expect(notifications.every((item) => item.userId == 'user_002'), isTrue);
  });

  test(
    'NotificationsBloc marks an item read and refreshes unread count',
    () async {
      final repository = LocalTaskFlowRepository(_FastAssetSource());
      final bloc = NotificationsBloc(repository);
      addTearDown(bloc.close);
      await bloc.load('user_002');
      expect(bloc.state.unreadCount, 1);

      await bloc.markRead('notif_4001');
      expect(bloc.state.unreadCount, 0);
      expect(bloc.state.notifications.single.read, isTrue);
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
