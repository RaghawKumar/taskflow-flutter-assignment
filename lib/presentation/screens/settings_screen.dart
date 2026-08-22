import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/tasks/tasks_bloc.dart';
import 'members_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>();
    final settings = context.watch<SettingsCubit>();
    final session = auth.state.session!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: Responsive.listPadding(context, maxWidth: 720),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(session.user.name.substring(0, 1)),
          ),
          const SizedBox(height: 12),
          Text(
            session.user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(session.user.email, textAlign: TextAlign.center),
          Text(session.role, textAlign: TextAlign.center),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Organization members'),
            subtitle: Text(
              session.isAdmin
                  ? 'View and manage organization access'
                  : 'View people in your organization',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MembersScreen()),
            ),
          ),
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: settings.state.darkMode,
            onChanged: settings.toggleTheme,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Simulate offline'),
            subtitle: const Text(
              'Previously loaded projects and tasks remain available',
            ),
            value: settings.state.offline,
            onChanged: (value) async {
              settings.setOffline(value);
              if (!value && context.mounted) {
                await Future.wait([
                  context.read<ProjectsBloc>().load(session.orgId),
                  context.read<TasksBloc>().load(session.orgId),
                ]);
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.error_outline),
            title: const Text('Simulate timeout'),
            subtitle: const Text('Turn on, then pull to refresh'),
            value: settings.state.forcedError != null,
            onChanged: (v) => settings.simulateError(
              v ? 'Request timed out. Please retry.' : null,
            ),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
