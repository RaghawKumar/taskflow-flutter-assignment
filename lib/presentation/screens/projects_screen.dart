import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../widgets/app_scope.dart';
import 'task_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget body;
    if (app.dataPhase == LoadPhase.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (app.dataPhase == LoadPhase.error) {
      body = _State(
        icon: Icons.cloud_off,
        text: app.error ?? 'Could not load projects',
        onRetry: app.loadAll,
      );
    } else if (app.dataPhase == LoadPhase.empty) {
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
            onRefresh: app.loadAll,
            child: GridView.builder(
              padding: Responsive.listPadding(context, maxWidth: 1280),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
                mainAxisExtent: Responsive.isCompact(context) ? 150 : 175,
              ),
              itemCount: app.projects.length,
              itemBuilder: (context, index) {
                final p = app.projects[index];
                return Card(
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
                        '${p.description}\n${app.taskCount(p.id)} tasks',
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
                          final ok = await app.deleteProject(p.id);
                          if (!ok && context.mounted)
                            showError(context, app.error!);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (app.session!.isAdmin)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
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
      appBar: AppBar(title: const Text('Projects')),
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
    final app = AppScope.of(context);
    final tasks = app.tasks.where((t) => t.projectId == project.id).toList();
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
        onRefresh: app.loadAll,
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
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: project?.name);
  final description = TextEditingController(text: project?.description);
  final app = AppScope.of(context, listen: false);
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(project == null ? 'New project' : 'Edit project'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Project name is required.'
                    : null,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            final ok = await app.saveProject(
              ProjectRequest(name: name.text, description: description.text),
              id: project?.id,
            );
            if (dialogContext.mounted && ok) Navigator.pop(dialogContext);
            if (dialogContext.mounted && !ok)
              showError(dialogContext, app.error!);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  description.dispose();
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
