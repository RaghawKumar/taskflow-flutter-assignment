import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../core/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/notifications/notifications_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/tasks/tasks_bloc.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
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
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(.025, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
          ),
        ),
      ],
    );
    return Scaffold(
      body: body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: context.l10n.text('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_outlined),
                  label: context.l10n.text('projects'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.task_alt),
                  label: context.l10n.text('tasks'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: context.l10n.text('settings'),
                ),
              ],
            ),
      bottomSheet: settings.offline
          ? Material(
              color: AppColors.warning,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: Center(child: Text(context.l10n.text('offline'))),
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
    final session = context.watch<AuthBloc>().state.session!;
    final projects = context.watch<ProjectsBloc>().state.projects;
    final tasksState = context.watch<TasksBloc>().state;
    final tasks = tasksState.tasks;
    final done = tasks.where((t) => t.status.name == 'done').length;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('dashboard')),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) => Semantics(
              button: true,
              label: 'Notifications, ${state.unreadCount} unread',
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: state.unreadCount > 0,
                  label: Text('${state.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProjectsBloc>().load(session.orgId),
            context.read<TasksBloc>().load(session.orgId),
          ]);
        },
        child: ListView(
          padding: Responsive.listPadding(context),
          children: [
            Text(
              'Hello, ${session.user.name.split(' ').first}',
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
                      label: context.l10n.text('projects'),
                      value: '${projects.length}',
                      background: scheme.primaryContainer,
                      foreground: scheme.onPrimaryContainer,
                    ),
                    _Metric(
                      icon: Icons.task_alt_rounded,
                      label: context.l10n.text('tasks'),
                      value: '${tasks.length}',
                      background: scheme.secondaryContainer,
                      foreground: scheme.onSecondaryContainer,
                    ),
                    _Metric(
                      icon: Icons.check_circle_rounded,
                      label: context.l10n.text('completed'),
                      value: '$done',
                      background: scheme.tertiaryContainer,
                      foreground: scheme.onTertiaryContainer,
                    ),
                    _Metric(
                      icon: Icons.group_rounded,
                      label: context.l10n.text('members'),
                      value: '${tasksState.members.length}',
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
                  context.l10n.text('upcoming'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${tasks.where((t) => t.status.name != 'done').length} open',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.every((t) => t.status.name == 'done'))
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Everything is complete. Great work!'),
                  ),
                ),
              ),
            ...tasks
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
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    readOnly: true,
    child: Card(
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
      'high' => AppColors.warning,
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
