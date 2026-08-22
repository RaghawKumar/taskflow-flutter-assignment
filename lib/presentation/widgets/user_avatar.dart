import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// Displays mock avatar URLs from locally bundled files, keeping the app
/// independent from runtime network access.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      _initials(user.name),
      style: TextStyle(fontSize: radius * 0.58, fontWeight: FontWeight.w700),
    );
    final hasAvatar = user.avatarUrl?.trim().isNotEmpty == true;

    return Semantics(
      image: true,
      label: 'Profile photo of ${user.name}',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: hasAvatar
            ? ClipOval(
                child: Image.asset(
                  'assets/avatars/${user.id}.jpg',
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(child: fallback),
                ),
              )
            : fallback,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
