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
                mainAxisSpacing: 12,
                mainAxisExtent: Responsive.isCompact(context) ? 150 : 175,
              ),
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final p = state.projects[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: index * 45),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        child: Icon(Icons.folder_outlined),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${p.description}\n${tasksBloc.countForProject(p.id)} tasks',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailsScreen(project: p),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit')
                            showProjectForm(context, project: p);
                          if (value == 'delete' &&
                              await confirmDelete(context, p.name) &&
                              context.mounted) {
                            final ok = await projectsBloc.delete(
                              p.id,
                              actorUserId: session.user.id,
                            );
                            if (!ok && context.mounted)
                              showError(context, projectsBloc.state.error!);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          if (session.isAdmin)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('projects'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProjectForm(context),
        child: const Icon(Icons.add),
      ),
      body: body,
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
        title: Text(project.name),
        actions: [
          IconButton(
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
            Text(project.description),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskStatus.values
                  .map(
                    (s) => Chip(
                      label: Text(
                        '${enumLabel(s.name)}: ${tasks.where((t) => t.status == s).length}',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Tasks', style: Theme.of(context).textTheme.titleLarge),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No tasks in this project')),
              ),
            ...tasks.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.title),
                subtitle: Text(
                  '${enumLabel(t.status.name)} • ${enumLabel(t.priority.name)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(taskId: t.id),
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
