import 'package:flutter/material.dart';
import '../../core/responsive.dart';
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
    final wide = Responsive.isMedium(context);
    final body = Row(
      children: [
        if (wide)
          NavigationRail(
            extended: Responsive.isExpanded(context),
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
          padding: Responsive.listPadding(context),
          children: [
            Text(
              'Hello, ${app.session!.user.name.split(' ').first}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Here’s the current shape of your work.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final scheme = Theme.of(context).colorScheme;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth >= 900 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth < 420 ? 1.25 : 1.45,
                  children: [
                    _Metric(
                      icon: Icons.folder_rounded,
                      label: 'Projects',
                      value: '${app.projects.length}',
                      background: scheme.primaryContainer,
                      foreground: scheme.onPrimaryContainer,
                    ),
                    _Metric(
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks',
                      value: '${app.tasks.length}',
                      background: scheme.secondaryContainer,
                      foreground: scheme.onSecondaryContainer,
                    ),
                    _Metric(
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      value: '$done',
                      background: scheme.tertiaryContainer,
                      foreground: scheme.onTertiaryContainer,
                    ),
                    _Metric(
                      icon: Icons.group_rounded,
                      label: 'Members',
                      value: '${app.members.length}',
                      background: scheme.surfaceContainerHighest,
                      foreground: scheme.onSurfaceVariant,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  'Upcoming tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${app.tasks.where((t) => t.status.name != 'done').length} open',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (app.tasks.every((t) => t.status.name == 'done'))
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Everything is complete. Great work!'),
                  ),
                ),
              ),
            ...app.tasks
                .where((t) => t.status.name != 'done')
                .take(5)
                .map(
                  (t) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.radio_button_unchecked,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Due ${_date(t.dueDate)}'),
                      trailing: _PriorityBadge(priority: t.priority.name),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });
  final IconData icon;
  final String label, value;
  final Color background, foreground;
  @override
  Widget build(BuildContext context) => Card(
    color: background,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: foreground, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'urgent' => Theme.of(context).colorScheme.error,
      'high' => Colors.orange.shade800,
      'medium' => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
