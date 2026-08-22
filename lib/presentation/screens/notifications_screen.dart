import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/notifications/notifications_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/skeleton_loading.dart';
import 'task_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state.session!;
    final bloc = context.watch<NotificationsBloc>();
    final state = bloc.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: switch (state.phase) {
        LoadPhase.initial || LoadPhase.loading => const SkeletonList(items: 4),
        LoadPhase.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 56),
              const SizedBox(height: 12),
              Text(state.error ?? 'Could not load notifications'),
              TextButton(
                onPressed: () => bloc.load(session.user.id),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        LoadPhase.empty => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 56),
              SizedBox(height: 12),
              Text('No notifications yet'),
            ],
          ),
        ),
        _ => RefreshIndicator(
          onRefresh: () => bloc.load(session.user.id),
          child: ListView.separated(
            padding: Responsive.listPadding(context, maxWidth: 760),
            itemCount: state.notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return FadeSlideIn(
                delay: Duration(milliseconds: index * 40),
                child: Semantics(
                  button: true,
                  label:
                      '${notification.read ? 'Read' : 'Unread'} notification: ${notification.message}',
                  child: Card(
                    color: notification.read
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: .45),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        child: Icon(
                          notification.read
                              ? Icons.notifications_outlined
                              : Icons.notifications_active,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: notification.read
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(_date(notification.createdAt)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openTask(context, bloc, notification),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      },
    );
  }

  Future<void> _openTask(
    BuildContext context,
    NotificationsBloc bloc,
    TaskNotification notification,
  ) async {
    if (!notification.read) await bloc.markRead(notification.id);
    if (!context.mounted) return;
    final exists = context.read<TasksBloc>().state.tasks.any(
      (task) => task.id == notification.taskId,
    );
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The related task is no longer available.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: notification.taskId),
      ),
    );
  }
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
