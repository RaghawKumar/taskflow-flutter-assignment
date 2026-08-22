import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/models/models.dart';

void main() {
  test('all read-only entities support JSON round trips', () {
    const organization = Organization(id: 'o1', name: 'Org');
    const user = AppUser(id: 'u1', name: 'User', email: 'u@example.com');
    const member = OrgMember(orgId: 'o1', userId: 'u1', role: 'member');
    const credential = AuthCredential(
      email: 'u@example.com',
      password: 'secret',
      orgId: 'o1',
      role: 'member',
    );
    const tokens = AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessExpiresIn: 900,
      refreshExpiresIn: 604800,
    );

    expect(
      Organization.fromJson(organization.toJson()).name,
      organization.name,
    );
    expect(AppUser.fromJson(user.toJson()).email, user.email);
    expect(OrgMember.fromJson(member.toJson()).role, member.role);
    expect(
      AuthCredential.fromJson(credential.toJson()).orgId,
      credential.orgId,
    );
    expect(AuthTokens.fromJson(tokens.toJson()).accessExpiresIn, 900);
  });

  test('request models serialize to transport-ready JSON', () {
    expect(const LoginRequest('u@example.com', 'secret').toJson(), {
      'email': 'u@example.com',
      'password': 'secret',
    });
    expect(
      const ProjectRequest(
        name: 'Project',
        description: 'Description',
      ).toJson()['name'],
      'Project',
    );
    final task = TaskRequest(
      title: 'Task',
      description: '',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 2, 1),
      assigneeId: 'u1',
    );
    expect(task.toJson()['status'], 'in_progress');
    expect(task.toJson()['due_date'], '2026-02-01');
  });

  test('response wrappers represent data, list and mutation responses', () {
    expect(const DataResponse(data: 'value').data, 'value');
    expect(const ListResponse<int>(items: [1, 2]).items, hasLength(2));
    expect(const MutationResponse(data: true).message, 'Success');
  });
}
