import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/skeleton_loading.dart';
import 'task_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final projectsBloc = context.watch<ProjectsBloc>();
    final state = projectsBloc.state;
    final session = context.watch<AuthBloc>().state.session!;
    final tasksBloc = context.watch<TasksBloc>();
    Widget body;
    if (state.phase == LoadPhase.loading) {
      body = const SkeletonList();
    } else if (state.phase == LoadPhase.error) {
      body = _State(
        icon: Icons.cloud_off,
        text: state.error ?? 'Could not load projects',
        onRetry: () => projectsBloc.load(session.orgId),
      );
    } else if (state.phase == LoadPhase.empty) {
      body = _State(
        icon: Icons.folder_off_outlined,
        text: 'No projects yet',
        onRetry: () => showProjectForm(context),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final columns = Responsive.columns(context);
          return RefreshIndicator(
            onRefresh: () => projectsBloc.load(session.orgId),
            child: GridView.builder(
              padding: Responsive.listPadding(context, maxWidth: 1280),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: Responsive.isCompact(context) ? 174 : 184,
              ),
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final p = state.projects[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: index * 45),
                  child: _ProjectCard(
                    project: p,
                    taskCount: tasksBloc.countForProject(p.id),
                    canDelete: session.isAdmin,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailsScreen(project: p),
                      ),
                    ),
                    onAction: (value) async {
                      if (value == 'edit') {
                        showProjectForm(context, project: p);
                      }
                      if (value == 'delete' &&
                          await confirmDelete(context, p.name) &&
                          context.mounted) {
                        final ok = await projectsBloc.delete(
                          p.id,
                          actorUserId: session.user.id,
                        );
                        if (!ok && context.mounted) {
                          showError(context, projectsBloc.state.error!);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.text('projects'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProjectForm(context),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.taskCount,
    required this.canDelete,
    required this.onTap,
    required this.onAction,
  });

  final Project project;
  final int taskCount;
  final bool canDelete;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.folder_rounded, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Project actions',
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  project.description.trim().isEmpty
                      ? 'No description added.'
                      : project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View project',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key, required this.project});
  final Project project;
  @override
  Widget build(BuildContext context) {
    final tasksBloc = context.watch<TasksBloc>();
    final session = context.watch<AuthBloc>().state.session!;
    final tasks = tasksBloc.state.tasks
        .where((t) => t.projectId == project.id)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit project',
            icon: const Icon(Icons.edit),
            onPressed: () => showProjectForm(context, project: project),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskFormScreen(projectId: project.id),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
      body: RefreshIndicator(
        onRefresh: () => tasksBloc.load(session.orgId),
        child: ListView(
          padding: Responsive.listPadding(context),
          children: [
            _ProjectOverview(project: project, taskCount: tasks.length),
            const SizedBox(height: 24),
            Text(
              'Task summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 4 : 2;
                final width =
                    (constraints.maxWidth - (12 * (columns - 1))) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: TaskStatus.values
                      .map(
                        (status) => SizedBox(
                          width: width,
                          child: _StatusSummaryCard(
                            status: status,
                            count: tasks
                                .where((task) => task.status == status)
                                .length,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Project tasks',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${tasks.length} total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              _EmptyProjectTasks(
                onCreate: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskFormScreen(projectId: project.id),
                  ),
                ),
              ),
            ...tasks.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: entry.$1 * 45),
                  child: _ProjectTaskCard(
                    task: entry.$2,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: entry.$2.id),
                      ),
                    ),
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

class _ProjectOverview extends StatelessWidget {
  const _ProjectOverview({required this.project, required this.taskCount});

  final Project project;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  project.description.trim().isEmpty
                      ? 'No project description added.'
                      : project.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$taskCount ${taskCount == 1 ? 'task' : 'tasks'} in this project',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({required this.status, required this.count});

  final TaskStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            enumLabel(status.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTaskCard extends StatelessWidget {
  const _ProjectTaskCard({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.brightness == Brightness.dark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: primary.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.task_alt_rounded, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${enumLabel(task.status.name)}  •  ${enumLabel(task.priority.name)} priority',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProjectTasks extends StatelessWidget {
  const _EmptyProjectTasks({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(Icons.playlist_add_rounded, size: 44, color: primary),
          const SizedBox(height: 10),
          Text(
            'No tasks in this project',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create the first task to start tracking progress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create task'),
          ),
        ],
      ),
    );
  }
}

Future<void> showProjectForm(BuildContext context, {Project? project}) async {
  final projectsBloc = context.read<ProjectsBloc>();
  final session = context.read<AuthBloc>().state.session!;
  await showDialog(
    context: context,
    builder: (_) => ProjectFormDialog(
      project: project,
      orgId: session.orgId,
      projectsBloc: projectsBloc,
    ),
  );
}

class ProjectFormDialog extends StatefulWidget {
  const ProjectFormDialog({
    super.key,
    required this.orgId,
    required this.projectsBloc,
    this.project,
  });
  final String orgId;
  final ProjectsBloc projectsBloc;
  final Project? project;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController description;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.project?.name);
    description = TextEditingController(text: widget.project?.description);
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.project == null ? 'New project' : 'Edit project'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('project_name'),
                controller: name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Project name is required.'
                    : null,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('project_description'),
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('save_project'),
        onPressed: saving ? null : _save,
        child: saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await widget.projectsBloc.save(
      widget.orgId,
      ProjectRequest(name: name.text, description: description.text),
      id: widget.project?.id,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
      showError(
        context,
        widget.projectsBloc.state.error ?? 'Could not save project.',
      );
    }
  }
}

Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('“$name” cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
void showError(BuildContext context, String error) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));

class _State extends StatelessWidget {
  const _State({required this.icon, required this.text, required this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56),
        const SizedBox(height: 12),
        Text(text),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
