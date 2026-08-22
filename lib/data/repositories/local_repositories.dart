import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/mock_data_source.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this.source, {FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();
  final MockDataSource source;
  final FlutterSecureStorage storage;
  static const _sessionKey = 'taskflow_session';

  @override
  Future<Session> login(LoginRequest request) async {
    await source.delay();
    final db = await source.load();
    Map<String, dynamic>? match;
    for (final c in db.credentials) {
      if ((c['email'] as String).toLowerCase() == request.email.toLowerCase() &&
          c['password'] == request.password)
        match = c;
    }
    if (match == null) throw const AppException('Incorrect email or password.');
    final user = db.users.firstWhere((u) => u.email == match!['email']);
    final session = Session(
      user: user,
      orgId: match['org_id'],
      role: match['role'],
      expiresAt: DateTime.now().add(
        Duration(seconds: db.tokens.accessExpiresIn),
      ),
    );
    await _write(session, db.tokens);
    return session;
  }

  Future<void> _write(Session session, AuthTokens tokens) => storage.write(
    key: _sessionKey,
    value: jsonEncode({
      'user_id': session.user.id,
      'org_id': session.orgId,
      'role': session.role,
      'expires_at': session.expiresAt.toIso8601String(),
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
    }),
  );

  @override
  Future<Session?> restoreSession() async {
    final raw = await storage.read(key: _sessionKey);
    if (raw == null) return null;
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    final db = await source.load();
    final user = db.users.where((u) => u.id == saved['user_id']).firstOrNull;
    if (user == null) {
      await logout();
      return null;
    }
    final session = Session(
      user: user,
      orgId: saved['org_id'],
      role: saved['role'],
      expiresAt: DateTime.parse(saved['expires_at']),
    );
    if (DateTime.now().isAfter(session.expiresAt)) return refresh(session);
    return session;
  }

  @override
  Future<Session> refresh(Session session) async {
    final raw = await storage.read(key: _sessionKey);
    if (raw == null)
      throw const AppException('Your session has ended. Please sign in.');
    final db = await source.load();
    final renewed = Session(
      user: session.user,
      orgId: session.orgId,
      role: session.role,
      expiresAt: DateTime.now().add(
        Duration(seconds: db.tokens.accessExpiresIn),
      ),
    );
    final nonce = base64Url
        .encode(utf8.encode(DateTime.now().microsecondsSinceEpoch.toString()))
        .replaceAll('=', '');
    final refreshedTokens = AuthTokens(
      accessToken: 'mock.refreshed.$nonce',
      refreshToken: db.tokens.refreshToken,
      accessExpiresIn: db.tokens.accessExpiresIn,
      refreshExpiresIn: db.tokens.refreshExpiresIn,
    );
    await _write(renewed, refreshedTokens);
    return renewed;
  }

  @override
  Future<void> logout() => storage.delete(key: _sessionKey);
}

class LocalTaskFlowRepository implements TaskFlowRepository {
  LocalTaskFlowRepository(this.source);
  final MockDataSource source;
  @override
  bool get offline => source.offline;
  @override
  set offline(bool value) => source.offline = value;
  @override
  String? get forcedError => source.forcedError;
  @override
  set forcedError(String? value) => source.forcedError = value;

  Future<void> _cache(String key, List<Map<String, dynamic>> data) async =>
      (await SharedPreferences.getInstance()).setString(key, jsonEncode(data));
  Future<List<T>> _cached<T>(
    String key,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map((e) => parse(Map<String, dynamic>.from(e)))
              .toList();
  }

  @override
  Future<List<Project>> projectsForOrg(String orgId) async {
    try {
      await source.delay();
      final data = (await source.load()).projects
          .where((p) => p.orgId == orgId)
          .toList();
      await _cache('projects_$orgId', data.map((e) => e.toJson()).toList());
      return data;
    } on AppException {
      final cache = await _cached('projects_$orgId', Project.fromJson);
      if (cache.isNotEmpty) return cache;
      rethrow;
    }
  }

  @override
  Future<List<TaskItem>> tasksForOrg(String orgId) async {
    try {
      await source.delay();
      final db = await source.load();
      final ids = db.projects
          .where((p) => p.orgId == orgId)
          .map((p) => p.id)
          .toSet();
      final data = db.tasks.where((t) => ids.contains(t.projectId)).toList();
      await _cache('tasks_$orgId', data.map((e) => e.toJson()).toList());
      return data;
    } on AppException {
      final cache = await _cached('tasks_$orgId', TaskItem.fromJson);
      if (cache.isNotEmpty) return cache;
      rethrow;
    }
  }

  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async {
    await source.delay();
    return (await source.load()).tasks
        .where((t) => t.projectId == projectId)
        .toList();
  }

  @override
  Future<TaskItem> task(String id) async {
    await source.delay();
    return (await source.load()).tasks.where((t) => t.id == id).firstOrNull ??
        (throw const AppException('404 — task not found.'));
  }

  @override
  Future<List<AppUser>> membersForOrg(String orgId) async {
    final db = await source.load();
    final ids = db.members
        .where((m) => m.orgId == orgId)
        .map((m) => m.userId)
        .toSet();
    return db.users.where((u) => ids.contains(u.id)).toList();
  }

  @override
  Future<Project> saveProject(
    String orgId,
    ProjectRequest request, {
    String? id,
  }) async {
    _validate(request.name, 'Project name');
    await source.delay();
    final db = await source.load();
    if (id == null) {
      final item = Project(
        id: 'proj_${DateTime.now().microsecondsSinceEpoch}',
        orgId: orgId,
        name: request.name.trim(),
        description: request.description.trim(),
        createdAt: DateTime.now(),
      );
      db.projects.add(item);
      return item;
    }
    final index = db.projects.indexWhere((p) => p.id == id);
    if (index < 0) throw const AppException('404 — project not found.');
    return db.projects[index] = db.projects[index].copyWith(
      name: request.name.trim(),
      description: request.description.trim(),
    );
  }

  @override
  Future<void> deleteProject(String id, {required String actorUserId}) async {
    await source.delay();
    final db = await source.load();
    final project = db.projects.where((p) => p.id == id).firstOrNull;
    if (project == null) throw const AppException('404 — project not found.');
    _requireAdmin(db, project.orgId, actorUserId);
    db.projects.removeWhere((p) => p.id == id);
    db.tasks.removeWhere((t) => t.projectId == id);
  }

  @override
  Future<void> removeMember(
    String orgId,
    String memberUserId, {
    required String actorUserId,
  }) async {
    await source.delay();
    final db = await source.load();
    _requireAdmin(db, orgId, actorUserId);
    if (actorUserId == memberUserId) {
      throw const AppException('Organization admins cannot remove themselves.');
    }
    if (!db.members.any(
      (member) => member.orgId == orgId && member.userId == memberUserId,
    )) {
      throw const AppException('404 — organization member not found.');
    }
    db.members.removeWhere(
      (member) => member.orgId == orgId && member.userId == memberUserId,
    );
    final projectIds = db.projects
        .where((project) => project.orgId == orgId)
        .map((project) => project.id)
        .toSet();
    for (var index = 0; index < db.tasks.length; index++) {
      final task = db.tasks[index];
      if (projectIds.contains(task.projectId) &&
          task.assigneeId == memberUserId) {
        db.tasks[index] = task.copyWith(assigneeId: null);
      }
    }
  }

  void _requireAdmin(MockDatabase db, String orgId, String actorUserId) {
    final authorized = db.members.any(
      (member) =>
          member.orgId == orgId &&
          member.userId == actorUserId &&
          member.role == 'org_admin',
    );
    if (!authorized) {
      throw const AppException(
        'Only organization admins can perform this action.',
      );
    }
  }

  @override
  Future<TaskItem> saveTask(
    String projectId,
    TaskRequest request, {
    String? id,
  }) async {
    _validate(request.title, 'Task title');
    await source.delay();
    final db = await source.load();
    if (request.assigneeId != null)
      await _validateMember(db, projectId, request.assigneeId!);
    if (id == null) {
      final item = TaskItem(
        id: 'task_${DateTime.now().microsecondsSinceEpoch}',
        projectId: projectId,
        title: request.title.trim(),
        description: request.description.trim(),
        status: request.status,
        priority: request.priority,
        assigneeId: request.assigneeId,
        dueDate: request.dueDate,
        createdAt: DateTime.now(),
      );
      db.tasks.add(item);
      return item;
    }
    final index = db.tasks.indexWhere((t) => t.id == id);
    if (index < 0) throw const AppException('404 — task not found.');
    return db.tasks[index] = db.tasks[index].copyWith(
      title: request.title.trim(),
      description: request.description.trim(),
      status: request.status,
      priority: request.priority,
      assigneeId: request.assigneeId,
      dueDate: request.dueDate,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await source.delay();
    final db = await source.load();
    if (!db.tasks.any((t) => t.id == id))
      throw const AppException('404 — task not found.');
    db.tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<TaskItem> assignTask(
    String taskId,
    String? userId,
    String orgId,
  ) async {
    final db = await source.load();
    final index = db.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) throw const AppException('404 — task not found.');
    if (userId != null &&
        !db.members.any((m) => m.orgId == orgId && m.userId == userId))
      throw const AppException(
        'That user does not belong to this organization.',
      );
    await source.delay();
    return db.tasks[index] = db.tasks[index].copyWith(assigneeId: userId);
  }

  Future<void> _validateMember(
    MockDatabase db,
    String projectId,
    String userId,
  ) async {
    final project = db.projects.firstWhere((p) => p.id == projectId);
    if (!db.members.any((m) => m.orgId == project.orgId && m.userId == userId))
      throw const AppException(
        'That user does not belong to this organization.',
      );
  }

  void _validate(String value, String field) {
    if (value.trim().isEmpty) throw AppException('$field is required.');
  }
}
