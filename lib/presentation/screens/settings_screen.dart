import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/projects/projects_bloc.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../widgets/user_avatar.dart';
import 'members_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>();
    final settings = context.watch<SettingsCubit>();
    final session = auth.state.session!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.text('profileSettings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: Responsive.listPadding(context, maxWidth: 760),
        children: [
          _ProfileHeader(
            user: session.user,
            role: session.role,
            orgId: session.orgId,
          ),
          const SizedBox(height: 26),
          const _SettingsSectionTitle(
            icon: Icons.apartment_rounded,
            title: 'Organization',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _SettingsTile(
              icon: Icons.groups_rounded,
              title: 'Organization members',
              subtitle: session.isAdmin
                  ? 'View and manage organization access'
                  : 'View people in your organization',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MembersScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionTitle(
            icon: Icons.palette_outlined,
            title: 'Preferences',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: settings.state.darkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: context.l10n.text('darkMode'),
                  subtitle: settings.state.darkMode
                      ? 'Using the TaskFlow dark theme'
                      : 'Using the TaskFlow light theme',
                  value: settings.state.darkMode,
                  onChanged: settings.toggleTheme,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: context.l10n.text('language'),
                  subtitle: 'Choose the application language',
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.state.locale.languageCode,
                      borderRadius: BorderRadius.circular(14),
                      onChanged: (value) {
                        if (value != null) {
                          settings.setLocale(Locale(value));
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(context.l10n.text('english')),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Text(context.l10n.text('hindi')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionTitle(
            icon: Icons.security_rounded,
            title: 'Security',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric unlock',
                  subtitle: settings.state.biometricAvailable == false
                      ? 'No enrolled biometrics detected on this device'
                      : settings.state.biometricEnabled
                      ? 'Required when restoring your saved session'
                      : 'Use fingerprint or face authentication to unlock',
                  value: settings.state.biometricEnabled,
                  onChanged: (value) async {
                    final message = await settings.setBiometricEnabled(value);
                    if (!context.mounted) return;
                    if (message != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    } else if (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Biometric unlock enabled.'),
                        ),
                      );
                    }
                  },
                ),
                const _SettingsDivider(),
                const _SettingsTile(
                  icon: Icons.lock_clock_rounded,
                  title: 'Automatic session timeout',
                  subtitle: 'Signs you out after 5 minutes of inactivity',
                  trailing: _SecurityStatusBadge(text: 'Active'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionTitle(
            icon: Icons.science_outlined,
            title: 'Testing & connectivity',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.wifi_off_rounded,
                  title: 'Simulate offline',
                  subtitle: 'Preserve loaded projects and tasks as stale data',
                  value: settings.state.offline,
                  onChanged: (value) async {
                    settings.setOffline(value);
                    if (!value && context.mounted) {
                      await Future.wait([
                        context.read<ProjectsBloc>().load(session.orgId),
                        context.read<TasksBloc>().load(session.orgId),
                      ]);
                    }
                  },
                ),
                const _SettingsDivider(),
                _SettingsSwitchTile(
                  icon: Icons.timer_off_outlined,
                  title: 'Simulate timeout',
                  subtitle: 'Enable this, then pull a list to refresh',
                  value: settings.state.forcedError != null,
                  onChanged: (value) => settings.simulateError(
                    value ? 'Request timed out. Please retry.' : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionTitle(
            icon: Icons.manage_accounts_outlined,
            title: 'Account',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.state.phase == LoadPhase.loading
                      ? null
                      : auth.logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.l10n.text('logout')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.role,
    required this.orgId,
  });

  final AppUser user;
  final String role;
  final String orgId;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary, width: 2),
              color: theme.colorScheme.surface,
            ),
            child: UserAvatar(user: user, radius: 46),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileBadge(
                icon: Icons.verified_user_outlined,
                text: roleLabel,
              ),
              _ProfileBadge(icon: Icons.apartment_rounded, text: orgId),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 6),
          Text(
            text,
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

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
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _SettingsTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: Switch(value: value, onChanged: onChanged),
    onTap: () => onChanged(!value),
  );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 72,
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
  );
}

class _SecurityStatusBadge extends StatelessWidget {
  const _SecurityStatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
