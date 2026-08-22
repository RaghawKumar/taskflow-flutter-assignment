import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/validators.dart';
import 'package:taskflow/domain/models/models.dart';

void main() {
  group('validation', () {
    test('email and password validation', () {
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('ava@example.com'), isNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('long-enough'), isNull);
    });
  });
  group('task filtering', () {
    final task = TaskItem(
      id: '1',
      projectId: 'p',
      title: 'Task',
      description: '',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      assigneeId: 'u1',
      dueDate: DateTime(2026, 2, 1),
      createdAt: DateTime(2026),
    );
    test('matches all selected dimensions', () {
      expect(
        TaskFilter(
          status: TaskStatus.todo,
          priority: TaskPriority.high,
          assigneeId: 'u1',
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 3, 1),
        ).matches(task),
        isTrue,
      );
      expect(const TaskFilter(status: TaskStatus.done).matches(task), isFalse);
    });
  });
}
