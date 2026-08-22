enum LoadPhase { initial, loading, success, empty, error }

enum TaskStatus { todo, inProgress, review, done }

enum TaskPriority { low, medium, high, urgent }

TaskStatus taskStatusFromJson(String value) => switch (value) {
  'in_progress' => TaskStatus.inProgress,
  'review' => TaskStatus.review,
  'done' => TaskStatus.done,
  _ => TaskStatus.todo,
};

String taskStatusJson(TaskStatus value) =>
    value == TaskStatus.inProgress ? 'in_progress' : value.name;

String enumLabel(String value) => value
    .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
    .replaceAll('_', ' ')
    .trim()
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

class Organization {
  const Organization({required this.id, required this.name});
  final String id;
  final String name;
  factory Organization.fromJson(Map<String, dynamic> json) =>
      Organization(id: json['id'], name: json['name']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser(id: json['id'], name: json['name'], email: json['email']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class OrgMember {
  const OrgMember({
    required this.orgId,
    required this.userId,
    required this.role,
  });
  final String orgId;
  final String userId;
  final String role;
  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
    orgId: json['org_id'],
    userId: json['user_id'],
    role: json['role'],
  );
  Map<String, dynamic> toJson() => {
    'org_id': orgId,
    'user_id': userId,
    'role': role,
  };
}

class AuthCredential {
  const AuthCredential({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });
  final String email;
  final String password;
  final String orgId;
  final String role;
  factory AuthCredential.fromJson(Map<String, dynamic> json) => AuthCredential(
    email: json['email'],
    password: json['password'],
    orgId: json['org_id'],
    role: json['role'],
  );
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'org_id': orgId,
    'role': role,
  };
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
    id: json['id'],
    taskId: json['task_id'],
    authorId: json['author_id'],
    body: json['body'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'author_id': authorId,
    'body': body,
    'created_at': createdAt.toIso8601String(),
  };
}

class TaskNotification {
  const TaskNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.taskId,
    required this.message,
    required this.read,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String type;
  final String taskId;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory TaskNotification.fromJson(Map<String, dynamic> json) =>
      TaskNotification(
        id: json['id'],
        userId: json['user_id'],
        type: json['type'],
        taskId: json['task_id'],
        message: json['message'],
        read: json['read'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'task_id': taskId,
    'message': message,
    'read': read,
    'created_at': createdAt.toIso8601String(),
  };
}

class Project {
  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.createdAt,
  });
  final String id;
  final String orgId;
  final String name;
  final String description;
  final DateTime createdAt;
  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    orgId: json['org_id'],
    name: json['name'],
    description: json['description'],
    createdAt: DateTime.parse(json['created_at']),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };
  Project copyWith({String? name, String? description}) => Project(
    id: id,
    orgId: orgId,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt,
  );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    this.assigneeId,
  });
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime dueDate;
  final DateTime createdAt;
  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'],
    projectId: json['project_id'],
    title: json['title'],
    description: json['description'],
    status: taskStatusFromJson(json['status']),
    priority: TaskPriority.values.byName(json['priority']),
    assigneeId: json['assignee_id'],
    dueDate: DateTime.parse(json['due_date']),
    createdAt: DateTime.parse(json['created_at']),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'title': title,
    'description': description,
    'status': taskStatusJson(status),
    'priority': priority.name,
    'assignee_id': assigneeId,
    'due_date': dueDate.toIso8601String().substring(0, 10),
    'created_at': createdAt.toIso8601String(),
  };
  TaskItem copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    Object? assigneeId = _unset,
    DateTime? dueDate,
  }) => TaskItem(
    id: id,
    projectId: projectId,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assigneeId: identical(assigneeId, _unset)
        ? this.assigneeId
        : assigneeId as String?,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
  );
}

const _unset = Object();

class TaskFilter {
  const TaskFilter({
    this.status,
    this.priority,
    this.assigneeId,
    this.from,
    this.to,
  });
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? assigneeId;
  final DateTime? from;
  final DateTime? to;
  bool matches(TaskItem task) =>
      (status == null || task.status == status) &&
      (priority == null || task.priority == priority) &&
      (assigneeId == null || task.assigneeId == assigneeId) &&
      (from == null || !task.dueDate.isBefore(from!)) &&
      (to == null || !task.dueDate.isAfter(to!));
}

class Session {
  const Session({
    required this.user,
    required this.orgId,
    required this.role,
    required this.expiresAt,
  });
  final AppUser user;
  final String orgId;
  final String role;
  final DateTime expiresAt;
  bool get isAdmin => role == 'org_admin';
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
  });
  final String accessToken;
  final String refreshToken;
  final int accessExpiresIn;
  final int refreshExpiresIn;
  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    accessExpiresIn: json['access_token_expires_in_seconds'],
    refreshExpiresIn: json['refresh_token_expires_in_seconds'],
  );
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_in_seconds': accessExpiresIn,
    'refresh_token_expires_in_seconds': refreshExpiresIn,
  };
}

class DataResponse<T> {
  const DataResponse({required this.data, this.stale = false});
  final T data;
  final bool stale;
}

class ListResponse<T> {
  const ListResponse({required this.items, this.stale = false});
  final List<T> items;
  final bool stale;
}

class MutationResponse<T> {
  const MutationResponse({required this.data, this.message = 'Success'});
  final T data;
  final String message;
}

class LoginRequest {
  const LoginRequest(this.email, this.password);
  final String email;
  final String password;
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class ProjectRequest {
  const ProjectRequest({required this.name, required this.description});
  final String name;
  final String description;
  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}

class TaskRequest {
  const TaskRequest({
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.assigneeId,
  });
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime dueDate;
  final String? assigneeId;
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': taskStatusJson(status),
    'priority': priority.name,
    'due_date': dueDate.toIso8601String().substring(0, 10),
    'assignee_id': assigneeId,
  };
}

class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
