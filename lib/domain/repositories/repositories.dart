import '../models/models.dart';

abstract interface class AuthRepository {
  Future<Session> login(LoginRequest request);
  Future<Session?> restoreSession();
  Future<Session> refresh(Session session);
  Future<void> logout();
}

abstract interface class TaskFlowRepository {
  Future<List<Project>> projectsForOrg(String orgId);
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  });
  Future<void> deleteProject(String id, {required String actorUserId});
  Future<List<TaskItem>> tasksForOrg(String orgId);
  Future<List<TaskItem>> tasksForProject(String projectId);
  Future<TaskItem> task(String id);
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  });
  Future<void> deleteTask(String id);
  Future<TaskItem> assignTask(String taskId, String? userId, String orgId);
  Future<List<AppUser>> membersForOrg(String orgId);
  Future<void> removeMember(
    String orgId,
    String memberUserId, {
    required String actorUserId,
  });
  bool get offline;
  set offline(bool value);
  String? get forcedError;
  set forcedError(String? value);
}
