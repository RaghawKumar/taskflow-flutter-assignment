import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'single bundled asset parses every top-level entity collection',
    () async {
      final database = await AssetMockDataSource().load();

      expect(database.organizations, hasLength(2));
      expect(database.users, hasLength(5));
      expect(database.members, hasLength(5));
      expect(database.projects, hasLength(3));
      expect(database.tasks, hasLength(15));
      expect(database.comments, hasLength(4));
      expect(database.notifications, hasLength(3));
      expect(database.credentials, hasLength(4));
      expect(database.tokens.accessExpiresIn, 900);
    },
  );

  test('comments and notifications preserve their relationships', () async {
    final database = await AssetMockDataSource().load();
    final comment = database.comments.first;
    final notification = database.notifications.first;

    expect(database.tasks.any((task) => task.id == comment.taskId), isTrue);
    expect(database.users.any((user) => user.id == comment.authorId), isTrue);
    expect(
      database.tasks.any((task) => task.id == notification.taskId),
      isTrue,
    );
    expect(
      database.users.any((user) => user.id == notification.userId),
      isTrue,
    );
  });
}
