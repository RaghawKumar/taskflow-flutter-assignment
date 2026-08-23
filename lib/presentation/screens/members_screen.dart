import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/user_avatar.dart';
import 'projects_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state.session!;
    final tasksBloc = context.watch<TasksBloc>();
    final members = tasksBloc.state.members;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.text('organizationMembers'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => tasksBloc.load(session.orgId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.listPadding(context, maxWidth: 760),
          children: [
            _MembersHeader(
              memberCount: members.length,
              orgId: session.orgId,
              isAdmin: session.isAdmin,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Text(
                  context.l10n.text('people'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${members.length} ${context.l10n.text('total')}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const _EmptyMembers()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 2 : 1;
                  final cardWidth =
                      (constraints.maxWidth - (12 * (columns - 1))) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: members.map((member) {
                      final isCurrentUser = member.id == session.user.id;
                      return SizedBox(
                        width: cardWidth,
                        child: _MemberCard(
                          member: member,
                          role: isCurrentUser ? session.role : 'member',
                          isCurrentUser: isCurrentUser,
                          canRemove: session.isAdmin && !isCurrentUser,
                          onRemove: () => _remove(
                            context,
                            tasksBloc,
                            member.id,
                            member.name,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
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
        icon: Icon(
          Icons.person_remove_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          context.l10n.text('removeMemberTitle'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '$memberName — ${context.l10n.text('memberRemoveConfirm')}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.text('removeMemberTitle')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final actor = context.read<AuthBloc>().state.session!.user.id;
    final removed = await bloc.removeMember(memberUserId, actorUserId: actor);
    if (!removed && context.mounted) {
      showError(
        context,
        bloc.state.error ?? context.l10n.text('couldNotRemoveMember'),
      );
    }
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({
    required this.memberCount,
    required this.orgId,
    required this.isAdmin,
  });

  final int memberCount;
  final String orgId;
  final bool isAdmin;

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
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 28,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAdmin
                      ? '${context.l10n.text('manageOrgAccess')} $orgId'
                      : '${context.l10n.text('peopleOrgAccess')} $orgId',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.text('admin'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.role,
    required this.isCurrentUser,
    required this.canRemove,
    required this.onRemove,
  });

  final AppUser member;
  final String role;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final roleLabel = role
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: UserAvatar(user: member, radius: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded, size: 18, color: primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCurrentUser ? '$roleLabel • You' : roleLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (canRemove) ...[
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: context.l10n.text('removeMember'),
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 44, color: primary),
          const SizedBox(height: 12),
          Text(
            context.l10n.text('noOrganizationMembers'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.text('pullMembersRefresh'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
