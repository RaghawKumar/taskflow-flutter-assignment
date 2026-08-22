import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../domain/models/models.dart';

class MockDatabase {
  List<Organization> organizations = [];
  List<AppUser> users = [];
  List<OrgMember> members = [];
  List<Project> projects = [];
  List<TaskItem> tasks = [];
  List<TaskComment> comments = [];
  List<TaskNotification> notifications = [];
  List<AuthCredential> credentials = [];
  late AuthTokens tokens;
}

abstract interface class MockDataSource {
  Future<MockDatabase> load();
  Future<MutationResponse<Project>> upsertProject(Project project);
  Future<MutationResponse<bool>> removeProject(String projectId);
  Future<MutationResponse<TaskItem>> upsertTask(TaskItem task);
  Future<MutationResponse<bool>> removeTask(String taskId);
  Future<MutationResponse<TaskItem>> setTaskAssignee(
    String taskId,
    String? userId,
  );
  Future<MutationResponse<bool>> removeMembership(String orgId, String userId);
  Future<void> delay();
  bool get offline;
  set offline(bool value);
  String? get forcedError;
  set forcedError(String? value);
}

class AssetMockDataSource implements MockDataSource {
  MockDatabase? _database;
  @override
  bool offline = false;
  @override
  String? forcedError;

  @override
  Future<MockDatabase> load() async {
    if (_database != null) return _database!;
    final root =
        jsonDecode(await rootBundle.loadString('assets/mock-data.json'))
            as Map<String, dynamic>;
    final db = MockDatabase();
    db.organizations = _parse(root['organizations'], Organization.fromJson);
    db.users = _parse(root['users'], AppUser.fromJson);
    db.members = _parse(root['org_members'], OrgMember.fromJson);
    db.projects = _parse(root['projects'], Project.fromJson);
    db.tasks = _parse(root['tasks'], TaskItem.fromJson);
    db.comments = _parse(root['comments'], TaskComment.fromJson);
    db.notifications = _parse(root['notifications'], TaskNotification.fromJson);
    final auth = root['auth_mock'] as Map<String, dynamic>;
    db.credentials = _parse(auth['test_credentials'], AuthCredential.fromJson);
    final token = auth['mock_login_response'] as Map<String, dynamic>;
    db.tokens = AuthTokens.fromJson(token);
    return _database = db;
  }

  List<T> _parse<T>(dynamic input, T Function(Map<String, dynamic>) fromJson) =>
      (input as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();

  @override
  Future<MutationResponse<Project>> upsertProject(Project project) async {
    final db = await load();
    final index = db.projects.indexWhere((item) => item.id == project.id);
    if (index < 0) {
      db.projects.add(project);
    } else {
      db.projects[index] = project;
    }
    return MutationResponse(data: project);
  }

  @override
  Future<MutationResponse<bool>> removeProject(String projectId) async {
    final db = await load();
    final removed = db.projects.any((item) => item.id == projectId);
    db.projects.removeWhere((item) => item.id == projectId);
    db.tasks.removeWhere((item) => item.projectId == projectId);
    return MutationResponse(data: removed);
  }

  @override
  Future<MutationResponse<TaskItem>> upsertTask(TaskItem task) async {
    final db = await load();
    final index = db.tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      db.tasks.add(task);
    } else {
      db.tasks[index] = task;
    }
    return MutationResponse(data: task);
  }

  @override
  Future<MutationResponse<bool>> removeTask(String taskId) async {
    final db = await load();
    final removed = db.tasks.any((item) => item.id == taskId);
    db.tasks.removeWhere((item) => item.id == taskId);
    return MutationResponse(data: removed);
  }

  @override
  Future<MutationResponse<TaskItem>> setTaskAssignee(
    String taskId,
    String? userId,
  ) async {
    final db = await load();
    final index = db.tasks.indexWhere((item) => item.id == taskId);
    if (index < 0) throw const AppException('404 — task not found.');
    final updated = db.tasks[index].copyWith(assigneeId: userId);
    db.tasks[index] = updated;
    return MutationResponse(data: updated);
  }

  @override
  Future<MutationResponse<bool>> removeMembership(
    String orgId,
    String userId,
  ) async {
    final db = await load();
    final removed = db.members.any(
      (member) => member.orgId == orgId && member.userId == userId,
    );
    db.members.removeWhere(
      (member) => member.orgId == orgId && member.userId == userId,
    );
    final projectIds = db.projects
        .where((project) => project.orgId == orgId)
        .map((project) => project.id)
        .toSet();
    for (final task in List<TaskItem>.of(db.tasks)) {
      if (projectIds.contains(task.projectId) && task.assigneeId == userId) {
        await setTaskAssignee(task.id, null);
      }
    }
    return MutationResponse(data: removed);
  }

  @override
  Future<void> delay() async {
    await Future<void>.delayed(
      Duration(milliseconds: 300 + Random().nextInt(501)),
    );
    if (offline)
      throw const AppException(
        'Offline — showing last saved data when available.',
      );
    if (forcedError != null) throw AppException(forcedError!);
  }
}
