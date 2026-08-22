import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/controllers/app_controller.dart';
import 'package:taskflow/presentation/screens/auth_screens.dart';
import 'package:taskflow/presentation/widgets/app_scope.dart';

void main() {
  testWidgets('login form displays meaningful validation', (tester) async {
    final controller = AppController(_FakeAuth(), _FakeRepository());
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });
}

class _FakeAuth implements AuthRepository {
  @override
  Future<Session> login(LoginRequest request) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<Session> refresh(Session session) async => session;
  @override
  Future<Session?> restoreSession() async => null;
}

class _FakeRepository implements TaskFlowRepository {
  @override
  bool offline = false;
  @override
  String? forcedError;
  @override
  Future<TaskItem> assignTask(String taskId, String? userId, String orgId) =>
      throw UnimplementedError();
  @override
  Future<void> deleteProject(String id, {required bool isAdmin}) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<List<AppUser>> membersForOrg(String orgId) async => [];
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
  Future<List<TaskItem>> tasksForOrg(String orgId) async => [];
  @override
  Future<List<TaskItem>> tasksForProject(String projectId) async => [];
}
