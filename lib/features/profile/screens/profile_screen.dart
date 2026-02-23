import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_service_screen.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showNotificationsDialog(BuildContext context, bool enabled) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Activer les notifications'),
                subtitle: const Text('Deadlines, nouvelles bourses...'),
                value: enabled,
                activeColor: AppTheme.primary,
                onChanged: (val) async {
                  try {
                    await context.read<ApiClient>().updateProfile({'notificationsEnabled': val});
                    context.read<AuthBloc>().add(AuthCheckEvent());
                    setState(() => enabled = val);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('ScholarHub', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 12),
            Text(
              'ScholarHub centralise les bourses d\'études pour les étudiants africains. Notre mission est de rendre l\'accès aux opportunités académiques plus simple et accessible.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('© 2026 ScholarHub. Tous droits réservés.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticatedState) return const SizedBox.shrink();
          final user = state.user;
          final name = user['name'] ?? '';
          final email = user['email'] ?? '';
          final country = user['country'] ?? '';
          final level = user['level'] ?? '';
          final notificationsEnabled = user['notificationsEnabled'] ?? true;

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                  child: Column(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      if (country.isNotEmpty || level.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (country.isNotEmpty) _Tag('🌍 $country'),
                            if (country.isNotEmpty && level.isNotEmpty) const SizedBox(width: 8),
                            if (level.isNotEmpty) _Tag('🎓 $level'),
                          ],
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 180, height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Modifier le profil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _MenuSection(
                        title: 'MON COMPTE',
                        items: [
                          _MenuItem(Icons.support_agent_rounded, 'Assistance candidature', () => context.push('/support')),
                          _MenuItem(Icons.person_outlined, 'Modifier le profil', () => context.push('/profile/edit')),
                          _MenuItem(
                            Icons.notifications_outlined,
                            'Notifications',
                            () => _showNotificationsDialog(context, notificationsEnabled),
                            trailing: Switch(
                              value: notificationsEnabled,
                              activeColor: AppTheme.primary,
                              onChanged: (val) async {
                                await context.read<ApiClient>().updateProfile({'notificationsEnabled': val});
                                context.read<AuthBloc>().add(AuthCheckEvent());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MenuSection(
                        title: 'APPLICATION',
                        items: [
                          _MenuItem(Icons.info_outlined, 'À propos', () => _showAboutDialog(context)),
                          _MenuItem(Icons.help_outlined, 'Aide & Support', () => context.push('/support')),
                          _MenuItem(
                            Icons.star_outline_rounded,
                            'Noter l\'app',
                            () async {
                              final url = Uri.parse('https://play.google.com/store/apps/details?id=com.scholarhub.scholarhub');
                              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ← SECTION LÉGAL
                      _MenuSection(
                        title: 'LÉGAL',
                        items: [
                          _MenuItem(
                            Icons.privacy_tip_outlined,
                            'Politique de confidentialité',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            ),
                          ),
                          _MenuItem(
                            Icons.description_outlined,
                            'Conditions d\'utilisation',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Logout
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border, width: 1.5),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout_rounded, color: AppTheme.accent, size: 22),
                          title: const Text('Se déconnecter', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w700)),
                                content: const Text('Voulez-vous vous déconnecter ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      context.read<AuthBloc>().add(AuthLogoutEvent());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Déconnexion'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
          ...items.map((item) => Column(
            children: [
              if (items.indexOf(item) > 0)
                const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.border),
              item,
            ],
          )),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;
  const _MenuItem(this.icon, this.label, this.onTap, {this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textPrimary, size: 20),
      title: Text(label, style: TextStyle(color: color ?? AppTheme.textPrimary, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}