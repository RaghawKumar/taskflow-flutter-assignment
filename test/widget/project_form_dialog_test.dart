import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/blocs/projects/projects_bloc.dart';
import 'package:taskflow/presentation/screens/projects_screen.dart';

void main() {
  testWidgets('creating a project closes without using disposed controllers', (
    tester,
  ) async {
    final repository = _ProjectRepository();
    final bloc = ProjectsBloc(repository);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    ProjectFormDialog(orgId: 'org_1', projectsBloc: bloc),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project_name')),
      'New project',
    );
    await tester.enterText(
      find.byKey(const Key('project_description')),
      'Description',
    );
    await tester.tap(find.byKey(const Key('save_project')));
    await tester.pumpAndSettle();

    expect(repository.projects.single.name, 'New project');
    expect(find.byType(ProjectFormDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ProjectRepository implements TaskFlowRepository {
  final List<Project> projects = [];
  @override
  bool offline = false;
  @override
  String? forcedError;
  @override
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  }) async {
    final project = Project(
      id: id ?? 'project_1',
      orgId: orgId,
      name: request.name,
      description: request.description,
      createdAt: DateTime(2026),
    );
    projects.add(project);
    return project;
  }

  @override
  Future<List<Project>> projectsForOrg(String orgId) async => projects;
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
  Future<void> deleteTask(String id) async {}
  @override
  Future<List<AppUser>> membersForOrg(String orgId) async => [];
  @override
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  }) => throw UnimplementedError();
  @override
  Future<TaskItem> task(String id) => throw UnimplementedError();
  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async => [];
  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async => [];
}
