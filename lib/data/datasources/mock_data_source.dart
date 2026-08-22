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
  List<Map<String, dynamic>> credentials = [];
  late AuthTokens tokens;
}

abstract interface class MockDataSource {
  Future<MockDatabase> load();
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
    db.credentials = List<Map<String, dynamic>>.from(auth['test_credentials']);
    final token = auth['mock_login_response'] as Map<String, dynamic>;
    db.tokens = AuthTokens(
      accessToken: token['access_token'],
      refreshToken: token['refresh_token'],
      accessExpiresIn: token['access_token_expires_in_seconds'],
      refreshExpiresIn: token['refresh_token_expires_in_seconds'],
    );
    return _database = db;
  }

  List<T> _parse<T>(dynamic input, T Function(Map<String, dynamic>) fromJson) =>
      (input as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();

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
