import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import 'projects_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state.session!;
    final tasksBloc = context.watch<TasksBloc>();
    final members = tasksBloc.state.members;
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Members')),
      body: RefreshIndicator(
        onRefresh: () => tasksBloc.load(session.orgId),
        child: ListView.separated(
          padding: Responsive.listPadding(context, maxWidth: 760),
          itemCount: members.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final member = members[index];
            final isCurrentUser = member.id == session.user.id;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              leading: CircleAvatar(child: Text(member.name.substring(0, 1))),
              title: Text(member.name),
              subtitle: Text(member.email),
              trailing: session.isAdmin && !isCurrentUser
                  ? IconButton(
                      tooltip: 'Remove member',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () =>
                          _remove(context, tasksBloc, member.id, member.name),
                    )
                  : Chip(label: Text(isCurrentUser ? session.role : 'Member')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    TasksBloc bloc,
    String memberUserId,
    String memberName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove $memberName from this organization? Their assigned tasks will become unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove Member'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final actor = context.read<AuthBloc>().state.session!.user.id;
    final removed = await bloc.removeMember(memberUserId, actorUserId: actor);
    if (!removed && context.mounted) {
      showError(context, bloc.state.error ?? 'Could not remove member.');
    }
  }
}
