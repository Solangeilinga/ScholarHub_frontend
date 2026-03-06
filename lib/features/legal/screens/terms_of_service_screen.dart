import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = [
    _Section(
      icon: '✅',
      title: "Acceptation des conditions",
      content: "En téléchargeant et utilisant l'application ScholarHub, vous acceptez d'être lié par les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser le service.",
    ),
    _Section(
      icon: '🎓',
      title: "Description du service",
      content: "ScholarHub est une plateforme de recherche de bourses d'études destinée aux étudiants africains. Le service comprend un catalogue de bourses, un algorithme de recommandation personnalisé, un système de sauvegarde, un service d'assistance et des alertes deadline.",
    ),
    _Section(
      icon: '👤',
      title: "Inscription et compte",
      content: "Pour accéder aux fonctionnalités complètes, vous devez créer un compte avec des informations exactes et à jour. Vous êtes responsable de la confidentialité de vos identifiants et de toutes les activités effectuées depuis votre compte.",
    ),
    _Section(
      icon: '🚫',
      title: "Utilisation acceptable",
      content: "Vous vous engagez à ne pas publier de fausses informations, accéder aux données d'autres utilisateurs, automatiser l'accès au service (scraping/bots), contourner les mesures de sécurité ou harceler d'autres utilisateurs.",
    ),
    _Section(
      icon: '⚠️',
      title: "Exactitude des informations",
      content: "ScholarHub fait tout son possible pour fournir des informations exactes sur les bourses, mais ne garantit pas leur complétude. Vérifiez toujours les informations directement auprès de l'organisme prestataire avant de postuler.",
    ),
    _Section(
      icon: '©️',
      title: "Propriété intellectuelle",
      content: "Tout le contenu de ScholarHub (logo, design, algorithmes) est protégé par les droits de propriété intellectuelle. Vous disposez d'une licence limitée et non commerciale pour utiliser l'application à des fins personnelles.",
    ),
    _Section(
      icon: '⚖️',
      title: "Limitation de responsabilité",
      content: "ScholarHub ne saurait être tenu responsable des pertes résultant de l'utilisation du service, de l'interruption temporaire du service, ou des décisions prises concernant des candidatures à des bourses.",
    ),
    _Section(
      icon: '🔒',
      title: "Suspension et résiliation",
      content: "ScholarHub peut suspendre ou supprimer votre compte en cas de violation de ces conditions, comportement frauduleux ou inactivité prolongée (plus de 24 mois). Vous pouvez supprimer votre compte depuis Profil → Paramètres.",
    ),
    _Section(
      icon: '📝',
      title: "Modifications",
      content: "ScholarHub se réserve le droit de modifier ces conditions à tout moment. Les modifications importantes vous seront notifiées par email ou via l'application. La poursuite de l'utilisation vaut acceptation des nouvelles conditions.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0D0E2E),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                "Conditions d'utilisation",
                style: TextStyle(
                    fontSize: AppTheme.fsBodyLg,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D0E2E), Color(0xFF1B2FBE)],
                  ),
                ),
                child: const Center(
                  child: Text('📋', style: TextStyle(fontSize: 56)),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EAF0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update_rounded, size: 14, color: AppTheme.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'Dernière mise à jour : 23 février 2026',
                          style: TextStyle(
                              fontSize: AppTheme.fsLabelSm,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Résumé
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0E2E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0D0E2E).withValues(alpha: 0.12)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📌', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En résumé',
                                style: TextStyle(
                                    fontSize: AppTheme.fsBodySm,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D0E2E)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ScholarHub est un service gratuit pour trouver des bourses. Fournissez des informations exactes, utilisez le service honnêtement et vérifiez toujours les infos auprès des organismes. Nous ne garantissons pas l\'obtention d\'une bourse.',
                                style: TextStyle(
                                    fontSize: AppTheme.fsBodySm,
                                    color: AppTheme.textSecondary,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sections accordéon
                  ...List.generate(_sections.length, (i) => _SectionCard(section: _sections[i])),

                  // Contact
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EAF0)),
                    ),
                    child: const Column(
                      children: [
                        Text('⚖️', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'Des questions sur nos conditions ?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: AppTheme.fsBodyMd),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'legal@scholarhub.app',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: AppTheme.fsBodyMd),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String icon;
  final String title;
  final String content;
  const _Section({required this.icon, required this.title, required this.content});
}

class _SectionCard extends StatefulWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(widget.section.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.section.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTheme.fsBodyMd),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFF6B7299),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                widget.section.content,
                style: const TextStyle(
                    fontSize: AppTheme.fsBodySm,
                    color: Color(0xFF6B7299),
                    height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}
