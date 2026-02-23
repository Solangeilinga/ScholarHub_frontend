import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../features/scholarships/bloc/scholarship_bloc.dart';
import '../../../features/scholarships/models/scholarship_model.dart';
import '../../../core/theme/app_theme.dart';

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

    // 1. Marquer comme en cours de suppression → animation
    setState(() => _removingIds.add(s.id));

    try {
      // 2. Appel API
      await context.read<ApiClient>().unsaveScholarship(s.id);

      // 3. Notifier le ScholarshipBloc pour sync home/explore
      context.read<ScholarshipBloc>().add(ToggleSaveEvent(id: s.id, isSaved: true));

      // 4. Attendre l'animation de sortie
      await Future.delayed(const Duration(milliseconds: 350));

      // 5. Supprimer de la liste locale
      if (mounted) {
        setState(() {
          _saved.removeWhere((item) => item.id == s.id);
          _removingIds.remove(s.id);
        });
      }
    } catch (_) {
      // Rollback
      if (mounted) setState(() => _removingIds.remove(s.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la suppression'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocListener<ScholarshipBloc, ScholarshipState>(
        // Écouter si une bourse est unsavée depuis une autre page (ex: detail)
        listenWhen: (_, curr) => curr is ScholarshipSavedToggledState,
        listener: (context, state) {
          if (state is ScholarshipSavedToggledState && !state.isSaved) {
            setState(() => _saved.removeWhere((s) => s.id == state.scholarshipId));
          }
        },
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              pinned: true,
              toolbarHeight: 64,
              flexibleSpace: Padding(
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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text(
                          _saved.isEmpty
                              ? 'Aucune bourse'
                              : '${_saved.length} bourse${_saved.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    if (_saved.isNotEmpty)
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
                            Text('${_saved.length}',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Contenu
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_saved.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_outline_rounded, size: 48, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 20),
                      const Text('Aucune bourse sauvegardée',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Explorez et sauvegardez des bourses\npour les retrouver ici',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/explore'),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Explorer les bourses'),
                      ),
                    ],
                  ),
                ),
              )
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
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bande bleue en haut
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.provider,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 2),
                              Text(s.title,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // Bouton unsave avec confirmation
                        _UnsaveButton(onUnsave: widget.onUnsave),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Infos
                    Row(
                      children: [
                        _InfoTag(Icons.monetization_on_outlined, s.amountFormatted, AppTheme.primary),
                        const SizedBox(width: 12),
                        _InfoTag(
                          Icons.calendar_today_outlined,
                          DateFormat('dd MMM yyyy', 'fr_FR').format(s.deadline),
                          s.isExpiringSoon ? AppTheme.accent : AppTheme.textSecondary,
                        ),
                      ],
                    ),

                    if (s.isExpiringSoon) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⏰ Expire dans ${s.daysLeft} jour(s) !',
                          style: const TextStyle(
                              color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    if (s.fields.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: s.fields.take(2).map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(f,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bouton unsave avec confirmation via long press ou tap
class _UnsaveButton extends StatefulWidget {
  final VoidCallback onUnsave;
  const _UnsaveButton({required this.onUnsave});

  @override
  State<_UnsaveButton> createState() => _UnsaveButtonState();
}

class _UnsaveButtonState extends State<_UnsaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward(from: 0);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer la sauvegarde ?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Cette bourse sera retirée de votre liste de sauvegarde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onUnsave();
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
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bookmark_rounded, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoTag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}