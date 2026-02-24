import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const int onboardingVersion = 2;

  static Future<void> resetIfNewVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt('onboarding_version') ?? 0;
    if (savedVersion < OnboardingScreen.onboardingVersion) {
      await prefs.remove('has_seen_onboarding');
      await prefs.setInt('onboarding_version', OnboardingScreen.onboardingVersion);
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _floatAnim;
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    const _OnboardingData(
      icon: Icons.search_rounded,
      emoji: '🎓',
      title: 'Trouvez votre\nbourse idéale',
      description: 'Plus de 500 bourses pour étudiants africains, centralisées en un seul endroit.',
      stats: [('500+', 'Bourses'), ('54', 'Pays'), ('10k+', 'Étudiants')],
    ),
    const _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      emoji: '🎯',
      title: 'Recommandations\npersonnalisées',
      description: 'Notre algorithme analyse votre profil et vous suggère les meilleures opportunités.',
      stats: [('AI', 'Powered'), ('98%', 'Précision'), ('24/7', 'Dispo')],
    ),
    const _OnboardingData(
      icon: Icons.notifications_active_rounded,
      emoji: '🔔',
      title: 'Ne ratez plus\naucune deadline',
      description: 'Alertes automatiques avant chaque deadline. Votre succès commence maintenant.',
      stats: [('100%', 'Gratuit'), ('Alertes', 'Auto'), ('Simple', 'Rapide')],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    _animController.reset();
    _animController.forward();
    setState(() => _currentPage = index);
  }

  Future<void> _finishOnboarding(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setInt('onboarding_version', OnboardingScreen.onboardingVersion);
    if (mounted) context.go(route);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding('/auth/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: const Color(0xFF1B2FBE),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar (fixe)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text('ScholarHub',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        // Skip
                        TextButton(
                          onPressed: () => _finishOnboarding('/auth/login'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Passer',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PageView avec Expanded pour prendre l'espace disponible
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => _OnboardingPage(
                        data: _pages[i],
                        fadeAnim: _fadeAnim,
                        slideAnim: _slideAnim,
                        floatAnim: _floatAnim,
                        isActive: i == _currentPage,
                        availableHeight: constraints.maxHeight - 180, // Ajusté pour laisser de l'espace
                      ),
                    ),
                  ),

                  // Bottom (fixe) - avec SingleChildScrollView pour éviter les débordements
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicateurs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == i ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Bouton principal
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B2FBE),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Commencer gratuitement'
                                      : 'Suivant',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Connexion
                        GestureDetector(
                          onTap: () => _finishOnboarding('/auth/login'),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                              children: const [
                                TextSpan(text: 'Déjà un compte ? '),
                                TextSpan(
                                  text: 'Se connecter',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Animation<double> floatAnim;
  final bool isActive;
  final double availableHeight;

  const _OnboardingPage({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
    required this.floatAnim,
    required this.isActive,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight,
          maxHeight: availableHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration flottante
              AnimatedBuilder(
                animation: floatAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, floatAnim.value),
                  child: child,
                ),
                child: Container(
                  width: 180, height: 180, // Réduit légèrement
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cercle intérieur
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Icône principale
                      Icon(data.icon, size: 64, color: Colors.white),
                      // Emoji flottant
                      Positioned(
                        top: 15, right: 15,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                            ],
                          ),
                          child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 20))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Texte animé
              FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28, // Réduit légèrement
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14, // Réduit légèrement
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: data.stats.map((stat) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              children: [
                                Text(stat.$1,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                Text(stat.$2,
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String emoji;
  final String title;
  final String description;
  final List<(String, String)> stats;

  const _OnboardingData({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.description,
    required this.stats,
  });
}