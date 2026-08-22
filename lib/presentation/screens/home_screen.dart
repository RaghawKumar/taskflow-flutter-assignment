import 'package:flutter/material.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_scope.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pages = [
      const DashboardPage(),
      const ProjectsScreen(),
      const TasksScreen(),
      const SettingsScreen(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final body = Row(
      children: [
        if (wide)
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.task_alt),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Settings'),
              ),
            ],
          ),
        Expanded(child: pages[index]),
      ],
    );
    return Scaffold(
      body: body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  label: 'Projects',
                ),
                NavigationDestination(
                  icon: Icon(Icons.task_alt),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
      bottomSheet: app.offline
          ? const Material(
              color: Colors.orange,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: Center(
                    child: Text('Offline • cached data may be stale'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final done = app.tasks.where((t) => t.status.name == 'done').length;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: app.loadAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello, ${app.session!.user.name.split(' ').first}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text('Here’s the current shape of your work.'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  icon: Icons.folder,
                  label: 'Projects',
                  value: '${app.projects.length}',
                ),
                _Metric(
                  icon: Icons.task,
                  label: 'Tasks',
                  value: '${app.tasks.length}',
                ),
                _Metric(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: '$done',
                ),
                _Metric(
                  icon: Icons.people,
                  label: 'Members',
                  value: '${app.members.length}',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
            ...app.tasks
                .where((t) => t.status.name != 'done')
                .take(5)
                .map(
                  (t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.radio_button_unchecked),
                    title: Text(t.title),
                    subtitle: Text('Due ${_date(t.dueDate)}'),
                    trailing: Chip(label: Text(t.priority.name)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 155,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 14),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
