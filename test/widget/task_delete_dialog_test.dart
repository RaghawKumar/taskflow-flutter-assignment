import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:taskflow/presentation/screens/task_detail_screen.dart';

void main() {
  testWidgets('task deletion requires explicit confirmation', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async => confirmed = await confirmTaskDelete(
                context,
                'Important task',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Task'), findsNWidgets(2));
    expect(find.textContaining('Important task'), findsOneWidget);
    expect(confirmed, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
  });

  testWidgets('confirmed deletion closes details without showing 404', (
    tester,
  ) async {
    final repository = _TaskRepository();
    final bloc = TasksBloc(repository);
    addTearDown(bloc.close);
    await bloc.load('org_1');

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskDetailScreen(taskId: 'task_1'),
                  ),
                ),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete task'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_task')));
    await tester.pumpAndSettle();

    expect(repository.tasks, isEmpty);
    expect(find.text('Open details'), findsOneWidget);
    expect(find.text('404 — task not found.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _TaskRepository implements TaskFlowRepository {
  final List<TaskItem> tasks = [
    TaskItem(
      id: 'task_1',
      projectId: 'project_1',
      title: 'Delete me',
      description: '',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      dueDate: DateTime(2026),
      createdAt: DateTime(2026),
    ),
  ];
  @override
  bool offline = false;
  @override
  String? forcedError;
  @override
  Future<void> deleteTask(String id) async =>
      tasks.removeWhere((task) => task.id == id);
  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async => List.of(tasks);
  @override
  Future<List<AppUser>> membersForOrg(String orgId) async => [];
  @override
  Future<TaskItem> assignTask(String taskId, String? userId, String orgId) =>
      throw UnimplementedError();
  @override
  Future<void> deleteProject(String id, {required String actorUserId}) async {}
  @override
  Future<void> removeMember(
    String orgId,
    String memberUserId, {
    required String actorUserId,
  }) async {}
  @override
  Future<List<Project>> projectsForOrg(String orgId) async => [];
  @override
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> task(String id) => throw UnimplementedError();
  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async =>
      tasks.where((task) => task.projectId == projectId).toList();
}
