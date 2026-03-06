import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _Section(
      icon: '📊',
      title: 'Données collectées',
      content: 'Lors de votre inscription, nous collectons votre nom, email, pays de résidence, niveau d\'études, domaines d\'intérêt et langues. Nous collectons également des données d\'utilisation (bourses consultées, sauvegardées) et des données techniques (type d\'appareil, version de l\'app).',
    ),
    _Section(
      icon: '🎯',
      title: 'Utilisation des données',
      content: 'Vos données sont utilisées pour vous recommander des bourses adaptées, vous envoyer des alertes avant les dates limites, répondre à vos demandes d\'assistance et améliorer nos services. Nous ne vous envoyons des notifications qu\'avec votre consentement.',
    ),
    _Section(
      icon: '🤝',
      title: 'Partage des données',
      content: 'ScholarHub ne vend jamais vos données personnelles. Nous pouvons les partager uniquement avec nos prestataires techniques (hébergement, emails) soumis à des obligations de confidentialité strictes, ou si la loi l\'exige.',
    ),
    _Section(
      icon: '🔒',
      title: 'Sécurité',
      content: 'Nous protégeons vos données avec le chiffrement des mots de passe, des communications HTTPS/TLS, un accès restreint au personnel autorisé et des audits de sécurité réguliers.',
    ),
    _Section(
      icon: '⏳',
      title: 'Conservation des données',
      content: 'Vos données sont conservées pendant toute la durée de votre utilisation. En cas de suppression de compte, vos données personnelles sont effacées sous 30 jours. Les logs de sécurité sont conservés 12 mois.',
    ),
    _Section(
      icon: '✅',
      title: 'Vos droits',
      content: 'Vous disposez des droits d\'accès, de rectification, d\'effacement, d\'opposition et de portabilité de vos données. Pour exercer ces droits, contactez-nous à privacy@scholarhub.app ou via le menu Assistance.',
    ),
    _Section(
      icon: '🍪',
      title: 'Cookies',
      content: 'Notre application mobile n\'utilise pas de cookies. Notre site web utilise uniquement des cookies essentiels au fonctionnement du service. Aucun cookie publicitaire ou de tracking tiers n\'est utilisé.',
    ),
    _Section(
      icon: '📝',
      title: 'Modifications',
      content: 'Nous pouvons mettre à jour cette politique. En cas de modification substantielle, vous serez notifié par email ou via l\'application. La date de mise à jour est indiquée en bas de cette page.',
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
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'Politique de confidentialité',
                style: TextStyle(
                  fontSize: AppTheme.fsBodyLg,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B2FBE), Color(0xFF111E8A)],
                  ),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 56)),
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
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
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
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Vos données restent vos données. Nous les utilisons uniquement pour améliorer votre expérience ScholarHub et vous aider à trouver des bourses. Nous ne les vendons jamais.',
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

                  // Sections
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
                        Text('📬', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'Des questions sur vos données ?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: AppTheme.fsBodyMd),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'privacy@scholarhub.app',
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
