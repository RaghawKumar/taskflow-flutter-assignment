import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/notifications/notifications_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/user_avatar.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'task_detail_screen.dart';

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
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                label: Text(context.l10n.text('home')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.folder_outlined),
                label: Text(context.l10n.text('projects')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.task_alt),
                label: Text(context.l10n.text('tasks')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                label: Text(context.l10n.text('settings')),
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
              color: Theme.of(context).colorScheme.secondary,
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
        title: Text(
          context.l10n.text('dashboard'),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) => Semantics(
              button: true,
              label:
                  '${context.l10n.text('notifications')}, ${state.unreadCount} ${context.l10n.text('unread')}',
              child: IconButton(
                tooltip: context.l10n.text('notifications'),
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
            _WelcomeBanner(
              user: session.user,
              openTasks: tasks.where((t) => t.status.name != 'done').length,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
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
                    ),
                    _Metric(
                      icon: Icons.task_alt_rounded,
                      label: context.l10n.text('tasks'),
                      value: '${tasks.length}',
                    ),
                    _Metric(
                      icon: Icons.check_circle_rounded,
                      label: context.l10n.text('completed'),
                      value: '$done',
                    ),
                    _Metric(
                      icon: Icons.group_rounded,
                      label: context.l10n.text('members'),
                      value: '${tasksState.members.length}',
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(context.l10n.text('everythingComplete')),
                  ),
                ),
              ),
            ...tasks
                .where((t) => t.status.name != 'done')
                .take(5)
                .map(
                  (t) => Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    child: ListTile(
                      key: Key('upcoming_task_${t.id}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: t.id),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.radio_button_unchecked,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${context.l10n.text('due')} ${_date(t.dueDate)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PriorityBadge(priority: t.priority.name),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.user, required this.openTasks});

  final AppUser user;
  final int openTasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -38,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onPrimary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              UserAvatar(user: user, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.l10n.text('hello')}, ${user.name.split(' ').first}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      openTasks == 0
                          ? context.l10n.text('everythingComplete')
                          : '$openTasks open ${openTasks == 1 ? 'task' : 'tasks'} ready for your attention.',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.trending_up_rounded,
                color: scheme.onPrimary,
                size: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$label: $value',
      readOnly: true,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: dark ? 0.20 : 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.primary.withValues(alpha: dark ? 0.28 : 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: dark ? 0.08 : 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                icon,
                size: 92,
                color: scheme.primary.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: scheme.onPrimary, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'urgent' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.primary,
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
