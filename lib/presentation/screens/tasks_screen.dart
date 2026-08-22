import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../widgets/app_scope.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tasks = app.filteredTasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () => showFilters(context),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: app.projects.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => showProjectPicker(context),
              child: const Icon(Icons.add),
            ),
      body: app.dataPhase == LoadPhase.loading
          ? const Center(child: CircularProgressIndicator())
          : app.dataPhase == LoadPhase.error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(app.error ?? 'Failed to load'),
                  TextButton(
                    onPressed: app.loadAll,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : tasks.isEmpty
          ? const Center(child: Text('No tasks match these filters.'))
          : RefreshIndicator(
              onRefresh: app.loadAll,
              child: ListView.builder(
                key: const Key('task_list'),
                padding: Responsive.listPadding(context, maxWidth: 920),
                itemCount: tasks.length,
                itemBuilder: (context, i) => TaskCard(task: tasks[i]),
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
    final app = AppScope.of(context);
    final assignee = app.userName(task.assigneeId);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(
                avatar: const Icon(Icons.flag, size: 16),
                label: Text(enumLabel(task.priority.name)),
              ),
              Chip(label: Text(enumLabel(task.status.name))),
              Chip(
                avatar: const Icon(Icons.person_outline, size: 16),
                label: Text(assignee ?? 'Unassigned'),
              ),
              Chip(
                avatar: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

Future<void> showProjectPicker(BuildContext context) async {
  final app = AppScope.of(context, listen: false);
  final project = await showModalBottomSheet<Project>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Choose a project')),
          ...app.projects.map(
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
  final app = AppScope.of(context, listen: false);
  TaskStatus? status = app.filter.status;
  TaskPriority? priority = app.filter.priority;
  String? assignee = app.filter.assigneeId;
  DateTime? from = app.filter.from;
  DateTime? to = app.filter.to;
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
                children: [
                  Text(
                    'Filter tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskStatus?>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
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
                    decoration: const InputDecoration(labelText: 'Priority'),
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
                    decoration: const InputDecoration(labelText: 'Assignee'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      ...app.members.map(
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
                          child: Text(
                            from == null
                                ? 'Due from'
                                : '${from!.day}/${from!.month}/${from!.year}',
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
                          child: Text(
                            to == null
                                ? 'Due to'
                                : '${to!.day}/${to!.month}/${to!.year}',
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
                          app.setFilter(const TaskFilter());
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          app.setFilter(
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
                        child: const Text('Apply'),
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
