import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../features/scholarships/bloc/scholarship_bloc.dart';
import '../../../features/scholarships/models/scholarship_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Scholarship> _saved = [];
  bool _loading = true;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.getSaved();
      setState(() {
        _saved = (res.data['saved'] as List).map((s) => Scholarship.fromJson(s)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _unsave(Scholarship s) async {
    if (_removingIds.contains(s.id)) return;
    HapticFeedback.lightImpact();

    setState(() => _removingIds.add(s.id));

    try {
      await context.read<ApiClient>().unsaveScholarship(s.id);
      context
          .read<ScholarshipBloc>()
          .add(SyncSaveStateEvent(id: s.id, isSaved: false));
      
      // ⚡ Animation plus courte
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() {
          _saved.removeWhere((item) => item.id == s.id);
          _removingIds.remove(s.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _removingIds.remove(s.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocListener<ScholarshipBloc, ScholarshipState>(
        listenWhen: (_, curr) => curr is ScholarshipSavedToggledState,
        listener: (context, state) {
          if (state is! ScholarshipSavedToggledState) return;

          if (!mounted) return;

          if (state.isSaved) {
            // Un save peut venir d'une autre page (home/liste).
            // On resynchronise la liste complète pour éviter tout décalage.
            _loadData();
            return;
          }

          setState(() => _saved.removeWhere((s) => s.id == state.scholarshipId));
        },
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              pinned: true,
              toolbarHeight: 64,
              flexibleSpace: const _AppBarContent(), // ⚡ Widget extrait
            ),

            // Contenu
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_saved.isEmpty)
              const _EmptyState() // ⚡ Widget extrait
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final s = _saved[i];
                      return _SavedScholarshipCard(
                        key: ValueKey(s.id),
                        scholarship: s,
                        isRemoving: _removingIds.contains(s.id),
                        onTap: () => context.push('/scholarships/${s.id}'),
                        onUnsave: () => _unsave(s),
                      );
                    },
                    childCount: _saved.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ⚡ Widget AppBar extrait
class _AppBarContent extends StatelessWidget {
  const _AppBarContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SavedScreenState>();
    final count = state?._saved.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sauvegardées',
                  style: TextStyle(
                      fontSize: AppTheme.fsHeadlineMd,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              Text(
                count == 0 ? 'Aucune bourse' : '$count bourse${count > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: AppTheme.fsBodySm, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('$count',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTheme.fsBodySm)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ⚡ Widget état vide extrait
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_outline_rounded, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text('Aucune bourse sauvegardée',
                style: TextStyle(
                    fontSize: AppTheme.fsTitleLg,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Explorez et sauvegardez des bourses\npour les retrouver ici',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/explore'),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Explorer les bourses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⚡ Carte optimisée avec moins d'animations
class _SavedScholarshipCard extends StatefulWidget {
  final Scholarship scholarship;
  final bool isRemoving;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedScholarshipCard({
    super.key,
    required this.scholarship,
    required this.isRemoving,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  State<_SavedScholarshipCard> createState() => _SavedScholarshipCardState();
}

class _SavedScholarshipCardState extends State<_SavedScholarshipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // ⚡ Plus court
    );
  }

  @override
  void didUpdateWidget(_SavedScholarshipCard old) {
    super.didUpdateWidget(old);
    if (widget.isRemoving && !old.isRemoving) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scholarship;

    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 1.0, end: 0.0)),
      child: SizeTransition( // ⚡ Animation plus légère que Transform.scale
        sizeFactor: _controller.drive(Tween(begin: 1.0, end: 0.0)),
        axisAlignment: -1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)), // ⚡ alpha en dur
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bande bleue
                const _TopBar(),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardHeader(
                        provider: s.provider,
                        title: s.title,
                        providerLogo: s.providerLogo,
                        onUnsave: widget.onUnsave,
                      ),
                      const SizedBox(height: 12),

                      // Infos
                      Row(
                        children: [
                          _InfoTag(
                            icon: Icons.monetization_on_outlined,
                            label: s.amountFormatted,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          _InfoTag(
                            icon: Icons.calendar_today_outlined,
                            label: formatDateFr(s.deadline),
                            color: s.isExpiringSoon ? AppTheme.accent : AppTheme.textSecondary,
                          ),
                        ],
                      ),

                      if (s.isExpiringSoon) ...[
                        const SizedBox(height: 8),
                        const _ExpiringBadge(), // ⚡ Widget constant
                      ],

                      if (s.fields.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _FieldsList(fields: s.fields), // ⚡ Widget extrait
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ⚡ Widgets extraits pour la carte
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String provider;
  final String title;
  final String? providerLogo;
  final VoidCallback onUnsave;

  const _CardHeader({
    required this.provider,
    required this.title,
    required this.providerLogo,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: providerLogo != null && providerLogo!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    providerLogo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
                  ),
                )
              : const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider,
                  style: const TextStyle(
                      fontSize: AppTheme.fsLabelSm, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      fontSize: AppTheme.fsBodyMd,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Bouton unsave sans animation
        _UnsaveButton(onUnsave: onUnsave),
      ],
    );
  }
}

class _FieldsList extends StatelessWidget {
  final List<String> fields;

  const _FieldsList({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: fields.take(2).map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(formatFieldLabel(f),
            style: const TextStyle(
                fontSize: AppTheme.fsBodySm,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }
}

class _ExpiringBadge extends StatelessWidget {
  const _ExpiringBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '⏰ Expire bientôt !',
        style: TextStyle(
            color: AppTheme.accent,
            fontSize: AppTheme.fsBodySm,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ⚡ Bouton unsave simplifié (sans animation)
class _UnsaveButton extends StatelessWidget {
  final VoidCallback onUnsave;

  const _UnsaveButton({required this.onUnsave});

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer la sauvegarde ?',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: AppTheme.fsBodyLg)),
        content: const Text('Cette bourse sera retirée de votre liste de sauvegarde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onUnsave();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showConfirmDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bookmark_rounded, color: AppTheme.primary, size: 20),
      ),
    );
  }
}

// ⚡ Widget InfoTag (constant-friendly)
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: AppTheme.fsLabelSm,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
