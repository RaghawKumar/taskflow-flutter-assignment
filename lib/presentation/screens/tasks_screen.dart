import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/skeleton_loading.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TasksBloc>();
    final state = bloc.state;
    final session = context.watch<AuthBloc>().state.session!;
    final projects = context.watch<ProjectsBloc>().state.projects;
    final tasks = state.filtered;
    final filter = state.filter;
    final hasFilters =
        filter.status != null ||
        filter.priority != null ||
        filter.assigneeId != null ||
        filter.from != null ||
        filter.to != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.text('tasks'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              isLabelVisible: hasFilters,
              smallSize: 8,
              child: IconButton(
                tooltip: 'Filter tasks',
                onPressed: () => showFilters(context),
                icon: Icon(
                  hasFilters
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: projects.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => showProjectPicker(context),
              child: const Icon(Icons.add),
            ),
      body: state.phase == LoadPhase.loading
          ? const SkeletonList()
          : state.phase == LoadPhase.error
          ? Center(
              child: _TasksMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load tasks',
                message: state.error ?? 'Failed to load',
                actionLabel: 'Retry',
                onAction: () => bloc.load(session.orgId),
              ),
            )
          : tasks.isEmpty
          ? Center(
              child: _TasksMessage(
                icon: Icons.task_alt_rounded,
                title: hasFilters ? 'No matching tasks' : 'No tasks yet',
                message: 'No tasks match these filters.',
                actionLabel: hasFilters ? 'Clear filters' : null,
                onAction: hasFilters
                    ? () => bloc.setFilter(const TaskFilter())
                    : null,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => bloc.load(session.orgId),
              child: ListView.builder(
                key: const Key('task_list'),
                padding: Responsive.listPadding(context, maxWidth: 920),
                itemCount: tasks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _TaskListHeader(
                      count: tasks.length,
                      hasFilters: hasFilters,
                      onFilter: () => showFilters(context),
                    );
                  }
                  final taskIndex = index - 1;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: taskIndex * 35),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(task: tasks[taskIndex]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final TaskItem task;
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TasksBloc>();
    final assignee = bloc.userName(task.assigneeId);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label:
          '${task.title}, ${enumLabel(task.priority.name)} priority, ${enumLabel(task.status.name)}, ${assignee ?? 'Unassigned'}',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: theme.brightness == Brightness.dark ? 0 : 2,
        shadowColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.task_alt_rounded, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: primary),
                  ],
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskMetaPill(
                      icon: Icons.flag_outlined,
                      label: enumLabel(task.priority.name),
                    ),
                    _TaskMetaPill(
                      icon: Icons.track_changes_rounded,
                      label: enumLabel(task.status.name),
                    ),
                    _TaskMetaPill(
                      icon: Icons.person_outline_rounded,
                      label: assignee ?? 'Unassigned',
                    ),
                    _TaskMetaPill(
                      icon: Icons.calendar_today_outlined,
                      label:
                          '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskMetaPill extends StatelessWidget {
  const _TaskMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListHeader extends StatelessWidget {
  const _TaskListHeader({
    required this.count,
    required this.hasFilters,
    required this.onFilter,
  });

  final int count;
  final bool hasFilters;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.17)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'task' : 'tasks'}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    hasFilters ? 'Filtered results' : 'All assigned work',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Filter tasks',
              onPressed: onFilter,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksMessage extends StatelessWidget {
  const _TasksMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

Future<void> showProjectPicker(BuildContext context) async {
  final projects = context.read<ProjectsBloc>().state.projects;
  final project = await showModalBottomSheet<Project>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Choose a project')),
          ...projects.map(
            (p) => ListTile(
              title: Text(p.name),
              onTap: () => Navigator.pop(context, p),
            ),
          ),
        ],
      ),
    ),
  );
  if (project != null && context.mounted)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(projectId: project.id)),
    );
}

Future<void> showFilters(BuildContext context) async {
  final bloc = context.read<TasksBloc>();
  TaskStatus? status = bloc.state.filter.status;
  TaskPriority? priority = bloc.state.filter.priority;
  String? assignee = bloc.state.filter.assigneeId;
  DateTime? from = bloc.state.filter.from;
  DateTime? to = bloc.state.filter.to;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.text('filterTasks'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Narrow tasks by progress, priority, owner, or due date.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskStatus?>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      ...TaskStatus.values.map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(enumLabel(v.name)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => status = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority?>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.low_priority_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      ...TaskPriority.values.map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(enumLabel(v.name)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => priority = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: assignee,
                    decoration: const InputDecoration(
                      labelText: 'Assignee',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      ...bloc.state.members.map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => assignee = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              initialDate: from ?? DateTime.now(),
                            );
                            if (d != null) setState(() => from = d);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_outlined),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  from == null
                                      ? 'Due from'
                                      : '${from!.day}/${from!.month}/${from!.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              initialDate: to ?? DateTime.now(),
                            );
                            if (d != null) setState(() => to = d);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_available_outlined),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  to == null
                                      ? 'Due to'
                                      : '${to!.day}/${to!.month}/${to!.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          bloc.setFilter(const TaskFilter());
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          bloc.setFilter(
                            TaskFilter(
                              status: status,
                              priority: priority,
                              assigneeId: assignee,
                              from: from,
                              to: to,
                            ),
                          );
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
