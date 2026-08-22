import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../widgets/app_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: Responsive.listPadding(context, maxWidth: 720),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(app.session!.user.name.substring(0, 1)),
          ),
          const SizedBox(height: 12),
          Text(
            app.session!.user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(app.session!.user.email, textAlign: TextAlign.center),
          Text(app.session!.role, textAlign: TextAlign.center),
          const Divider(height: 40),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: app.darkMode,
            onChanged: app.toggleTheme,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Simulate offline'),
            subtitle: const Text(
              'Previously loaded projects and tasks remain available',
            ),
            value: app.offline,
            onChanged: app.setOffline,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.error_outline),
            title: const Text('Simulate timeout'),
            subtitle: const Text('Turn on, then pull to refresh'),
            value: app.repository.forcedError != null,
            onChanged: (v) => app.simulateError(
              v ? 'Request timed out. Please retry.' : null,
            ),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await app.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
