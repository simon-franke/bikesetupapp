import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

class AccountSettings extends StatelessWidget {
  final User? user;
  final Future<void> Function() onSignOut;
  final VoidCallback onSignIn;

  const AccountSettings(
      {super.key,
      required this.user,
      required this.onSignOut,
      required this.onSignIn});

  String _initials(User u) {
    final name = u.displayName?.trim() ?? '';
    if (name.isEmpty) return u.isAnonymous ? 'G' : '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final u = user;
    final name = u == null
        ? 'Signed out'
        : (u.displayName ?? (u.isAnonymous ? 'Guest' : 'Signed in'));
    final email = u?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accent,
              image: (u?.photoURL != null)
                  ? DecorationImage(
                      image: NetworkImage(u!.photoURL!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: (u?.photoURL == null)
                ? Text(
                    u == null ? '?' : _initials(u),
                    style: AppTextStyles.label.copyWith(color: p.accentInk),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(color: p.ink),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted),
                  ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed:
                    u == null || u.isAnonymous ? onSignIn : () => onSignOut(),
                child: Text(u == null
                    ? 'Sign in'
                    : u.isAnonymous
                        ? 'Save account'
                        : 'Sign out'))),
      ],
    );
  }
}
