import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../blocs/tasks/tasks_bloc.dart';
import 'projects_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TasksBloc>();
    final matches = bloc.state.tasks.where((t) => t.id == taskId);
    if (matches.isEmpty)
      return const Scaffold(body: Center(child: Text('404 — task not found.')));
    final task = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TaskFormScreen(projectId: task.projectId, task: task),
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              if (await confirmDelete(context, task.title)) {
                final ok = await bloc.delete(task.id);
                if (context.mounted && ok) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: Responsive.listPadding(context, maxWidth: 760),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(task.description.isEmpty ? 'No description' : task.description),
          const Divider(height: 40),
          DropdownButtonFormField<TaskStatus>(
            key: const Key('status_dropdown'),
            initialValue: task.status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: TaskStatus.values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(enumLabel(v.name)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null)
                bloc.save(
                  task.projectId,
                  _request(task.copyWith(status: v)),
                  id: task.id,
                );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            initialValue: task.priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: TaskPriority.values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(enumLabel(v.name)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null)
                bloc.save(
                  task.projectId,
                  _request(task.copyWith(priority: v)),
                  id: task.id,
                );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: task.assigneeId,
            decoration: const InputDecoration(labelText: 'Assignee'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Unassigned')),
              ...bloc.state.members.map(
                (u) => DropdownMenuItem(value: u.id, child: Text(u.name)),
              ),
            ],
            onChanged: (v) => bloc.assign(task.id, v),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Due date'),
            subtitle: Text(
              '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
            ),
          ),
        ],
      ),
    );
  }
}

TaskRequest _request(TaskItem t) => TaskRequest(
  title: t.title,
  description: t.description,
  status: t.status,
  priority: t.priority,
  dueDate: t.dueDate,
  assigneeId: t.assigneeId,
);

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, required this.projectId, this.task});
  final String projectId;
  final TaskItem? task;
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, description;
  late TaskStatus status;
  late TaskPriority priority;
  String? assignee;
  late DateTime due;
  @override
  void initState() {
    super.initState();
    final t = widget.task;
    title = TextEditingController(text: t?.title);
    description = TextEditingController(text: t?.description);
    status = t?.status ?? TaskStatus.todo;
    priority = t?.priority ?? TaskPriority.medium;
    assignee = t?.assigneeId;
    due = t?.dueDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TasksBloc>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create task' : 'Edit task'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.listPadding(context, maxWidth: 760),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: form,
              child: Column(
                children: [
                  TextFormField(
                    controller: title,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Task title is required.'
                        : null,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: TaskStatus.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(enumLabel(v.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => status = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: TaskPriority.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(enumLabel(v.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => priority = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: assignee,
                    decoration: const InputDecoration(labelText: 'Assignee'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...bloc.state.members.map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => assignee = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: const Text('Due date'),
                    subtitle: Text('${due.day}/${due.month}/${due.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: due,
                      );
                      if (date != null) setState(() => due = date);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        final ok = await bloc.save(
                          widget.projectId,
                          TaskRequest(
                            title: title.text,
                            description: description.text,
                            status: status,
                            priority: priority,
                            dueDate: due,
                            assigneeId: assignee,
                          ),
                          id: widget.task?.id,
                        );
                        if (context.mounted && ok) Navigator.pop(context);
                        if (context.mounted && !ok)
                          showError(context, bloc.state.error!);
                      },
                      child: const Text('Save task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
