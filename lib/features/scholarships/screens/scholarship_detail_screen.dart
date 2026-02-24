import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../bloc/scholarship_bloc.dart';
import '../models/scholarship_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/countries.dart';

class ScholarshipDetailScreen extends StatefulWidget {
  final String id;
  const ScholarshipDetailScreen({super.key, required this.id});

  @override
  State<ScholarshipDetailScreen> createState() => _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState extends State<ScholarshipDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Fonction pour traduire les niveaux d'études
  String _getLevelLabel(String level) {
    const labels = {
      'BEPC': 'BEPC',
      'BACCALAUREAT': 'Baccalauréat',
      'LICENCE_1': 'Licence 1',
      'LICENCE_2': 'Licence 2',
      'LICENCE_3': 'Licence 3',
      'LICENCE': 'Licence',
      'MAITRISE': 'Maîtrise',
      'MASTER_1': 'Master 1',
      'MASTER_2': 'Master 2',
      'MASTER': 'Master',
      'DOCTORAT_1': 'Doctorat 1',
      'DOCTORAT_2': 'Doctorat 2',
      'DOCTORAT': 'Doctorat',
    };
    return labels[level] ?? level;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    context.read<ScholarshipBloc>().add(LoadScholarshipDetailEvent(widget.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScholarshipBloc, ScholarshipState>(
      builder: (context, state) {
        if (state is ScholarshipLoadingState) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state is ScholarshipDetailLoadedState) {
          _controller.forward();
          return _buildDetail(context, state.scholarship);
        }
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Bourse introuvable')),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, Scholarship s) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              // AppBar SANS le bouton de sauvegarde
              SliverAppBar(
                backgroundColor: AppTheme.surface,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  s.provider,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                // SUPPRESSION des actions (plus de bookmark)
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec logo
                    Container(
                      color: AppTheme.surface,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Logo du fournisseur (avec gestion d'image)
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border),
                                  image: s.providerLogo != null
                                      ? DecorationImage(
                                          image: NetworkImage(s.providerLogo!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: s.providerLogo == null
                                    ? const Icon(Icons.school_rounded, color: AppTheme.primary, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.provider, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(s.typeLabel, 
                                        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (s.isExpiringSoon)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('⏰ Expire bientôt',
                                      style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(s.title, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 20),
                          
                          // Badges principaux
                          Row(
                            children: [
                              _InfoBadge(Icons.monetization_on_outlined, s.amountFormatted, AppTheme.primary),
                              const SizedBox(width: 12),
                              _InfoBadge(Icons.calendar_today_outlined,
                                  DateFormat('dd MMM yyyy').format(s.deadline), AppTheme.accent),
                            ],
                          ),

                          // Date de début et durée
                          if (s.startDate != null || s.duration != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (s.startDate != null)
                                  Expanded(
                                    child: _InfoBadge(
                                      Icons.play_circle_outline,
                                      'Début: ${DateFormat('dd MMM yyyy').format(s.startDate!)}',
                                      AppTheme.secondary,
                                    ),
                                  ),
                                if (s.startDate != null && s.duration != null) 
                                  const SizedBox(width: 12),
                                if (s.duration != null)
                                  Expanded(
                                    child: _InfoBadge(
                                      Icons.schedule_outlined,
                                      'Durée: ${s.duration}',
                                      AppTheme.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Section(
                            title: 'Description',
                            icon: Icons.info_outline_rounded,
                            child: Text(s.description,
                                style: const TextStyle(height: 1.7, color: AppTheme.textSecondary, fontSize: 15)),
                          ),

                          if (s.requirements != null && s.requirements!.isNotEmpty)
                            _Section(
                              title: 'Conditions requises',
                              icon: Icons.checklist_rounded,
                              child: Text(s.requirements!,
                                  style: const TextStyle(height: 1.7, color: AppTheme.textSecondary, fontSize: 15)),
                            ),

                          if (s.benefits.isNotEmpty)
                            _Section(
                              title: 'Avantages',
                              icon: Icons.card_giftcard_rounded,
                              child: Column(
                                children: s.benefits.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 7, height: 7,
                                        decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(b, 
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5)
                                      )),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),

                          if (s.countries.isNotEmpty)
                            _Section(
                              title: 'Pays éligibles',
                              icon: Icons.public_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: s.countries.map((c) => _CountryChip(c)).toList(),
                              ),
                            ),

                          if (s.fields.isNotEmpty)
                            _Section(
                              title: 'Domaines',
                              icon: Icons.menu_book_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: s.fields.map((f) => _Chip(f, AppTheme.secondary)).toList(),
                              ),
                            ),

                          if (s.level.isNotEmpty)
                            _Section(
                              title: 'Niveaux requis',
                              icon: Icons.school_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: s.level.map((l) => _Chip(_getLevelLabel(l), AppTheme.primary)).toList(),
                              ),
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Boutons du bas
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            // Bouton assistance
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/support'),
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Être assisté'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Bouton postuler
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final rawLink = s.link.trim();
                  final urlString = rawLink.startsWith('http') ? rawLink : 'https://$rawLink';
                  final uri = Uri.parse(urlString);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    try {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lien : $urlString'),
                            action: SnackBarAction(
                              label: 'Copier',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: urlString));
                              },
                            ),
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Postuler'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final String code;
  const _CountryChip(this.code);

  @override
  Widget build(BuildContext context) {
    final country = countryByCode[code];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country?.flag ?? '🌍', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            country?.name ?? code,
            style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoBadge(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, 
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)
            )),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, 
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}