import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../blocs/tasks/tasks_bloc.dart';
import 'projects_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool deleting = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<TasksBloc>();
    final matches = bloc.state.tasks.where((t) => t.id == widget.taskId);
    if (matches.isEmpty && deleting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting task…'),
            ],
          ),
        ),
      );
    }
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('404 — task not found.')));
    }
    final task = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit task',
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
            tooltip: 'Delete task',
            onPressed: deleting ? null : () => _deleteTask(bloc, task),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: Responsive.listPadding(context, maxWidth: 760),
        children: [
          _TaskOverviewCard(task: task),
          const SizedBox(height: 26),
          Text(
            'Manage task',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _TaskManagementCard(task: task, bloc: bloc),
          const SizedBox(height: 18),
          _TaskDueDateCard(dueDate: task.dueDate),
        ],
      ),
    );
  }

  Future<void> _deleteTask(TasksBloc bloc, TaskItem task) async {
    if (!await confirmTaskDelete(context, task.title) || !mounted) return;
    setState(() => deleting = true);
    final ok = await bloc.delete(task.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => deleting = false);
      showError(context, bloc.state.error ?? 'Could not delete task.');
    }
  }
}

class _TaskOverviewCard extends StatelessWidget {
  const _TaskOverviewCard({required this.task});

  final TaskItem task;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Description',
            style: theme.textTheme.labelLarge?.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.description.trim().isEmpty
                ? 'No description added for this task.'
                : task.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskManagementCard extends StatelessWidget {
  const _TaskManagementCard({required this.task, required this.bloc});

  final TaskItem task;
  final TasksBloc bloc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: primary),
                const SizedBox(width: 9),
                Text(
                  'Progress and assignment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final status = DropdownButtonFormField<TaskStatus>(
                  key: const Key('status_dropdown'),
                  initialValue: task.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: TaskStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(enumLabel(value.name)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      bloc.save(
                        task.projectId,
                        _request(task.copyWith(status: value)),
                        id: task.id,
                      );
                    }
                  },
                );
                final priority = DropdownButtonFormField<TaskPriority>(
                  initialValue: task.priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.low_priority_rounded),
                  ),
                  items: TaskPriority.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(enumLabel(value.name)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      bloc.save(
                        task.projectId,
                        _request(task.copyWith(priority: value)),
                        id: task.id,
                      );
                    }
                  },
                );
                if (constraints.maxWidth >= 580) {
                  return Row(
                    children: [
                      Expanded(child: status),
                      const SizedBox(width: 14),
                      Expanded(child: priority),
                    ],
                  );
                }
                return Column(
                  children: [status, const SizedBox(height: 14), priority],
                );
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              key: const Key('assignee_dropdown'),
              initialValue: task.assigneeId,
              decoration: const InputDecoration(
                labelText: 'Assignee',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...bloc.state.members.map(
                  (user) =>
                      DropdownMenuItem(value: user.id, child: Text(user.name)),
                ),
              ],
              onChanged: (value) => bloc.assign(task.id, value),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDueDateCard extends StatelessWidget {
  const _TaskDueDateCard({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.calendar_month_rounded, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Due date',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
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

Future<bool> confirmTaskDelete(BuildContext context, String taskTitle) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete “$taskTitle”? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_delete_task'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Task'),
          ),
        ],
      ),
    ) ??
    false;

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
        title: Text(
          widget.task == null ? 'Create task' : 'Edit task',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: Responsive.listPadding(context, maxWidth: 760),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskFormHeader(isEditing: widget.task != null),
                  const SizedBox(height: 26),
                  _FormSectionTitle(
                    icon: Icons.edit_note_rounded,
                    title: 'Task information',
                  ),
                  const SizedBox(height: 12),
                  _TaskFormSection(
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('task_title'),
                          controller: title,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Task title is required.'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('task_description'),
                          controller: description,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 68),
                              child: Icon(Icons.notes_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle(
                    icon: Icons.tune_rounded,
                    title: 'Planning and assignment',
                  ),
                  const SizedBox(height: 12),
                  _TaskFormSection(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final statusField =
                                DropdownButtonFormField<TaskStatus>(
                                  initialValue: status,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    prefixIcon: Icon(Icons.flag_outlined),
                                  ),
                                  items: TaskStatus.values
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(enumLabel(value.name)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => status = value);
                                    }
                                  },
                                );
                            final priorityField =
                                DropdownButtonFormField<TaskPriority>(
                                  initialValue: priority,
                                  decoration: const InputDecoration(
                                    labelText: 'Priority',
                                    prefixIcon: Icon(
                                      Icons.low_priority_rounded,
                                    ),
                                  ),
                                  items: TaskPriority.values
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(enumLabel(value.name)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => priority = value);
                                    }
                                  },
                                );
                            if (constraints.maxWidth >= 520) {
                              return Row(
                                children: [
                                  Expanded(child: statusField),
                                  const SizedBox(width: 14),
                                  Expanded(child: priorityField),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                statusField,
                                const SizedBox(height: 14),
                                priorityField,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String?>(
                          key: const Key('task_assignee'),
                          initialValue: assignee,
                          decoration: const InputDecoration(
                            labelText: 'Assignee',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ...bloc.state.members.map(
                              (user) => DropdownMenuItem(
                                value: user.id,
                                child: Text(user.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => assignee = value),
                        ),
                        const SizedBox(height: 14),
                        _TaskFormDueDate(dueDate: due, onTap: _pickDueDate),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _save(bloc),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save task'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
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

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: due,
    );
    if (date != null && mounted) setState(() => due = date);
  }

  Future<void> _save(TasksBloc bloc) async {
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
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showError(context, bloc.state.error ?? 'Could not save task.');
    }
  }
}

class _TaskFormHeader extends StatelessWidget {
  const _TaskFormHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update task details' : 'Create a new task',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Keep the task information and ownership up to date.'
                      : 'Add the information your team needs to get started.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _TaskFormSection extends StatelessWidget {
  const _TaskFormSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withValues(alpha: 0.15)),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _TaskFormDueDate extends StatelessWidget {
  const _TaskFormDueDate({required this.dueDate, required this.onTap});

  final DateTime dueDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Material(
      color: primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
