import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../scholarships/bloc/scholarship_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/scholarship_card.dart';
import '../../../shared/widgets/featured_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour, ';
    if (hour < 18) return 'Bon après-midi, ';
    return 'Bonsoir, ';
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerController.forward();

    final scholarshipBloc = context.read<ScholarshipBloc>();
    if (scholarshipBloc.state is! ScholarshipsLoadedState) {
      scholarshipBloc
        ..add(const LoadFeaturedEvent())
        ..add(const LoadRecommendedEvent())
        ..add(const LoadScholarshipsEvent());
    }
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticatedState
        ? (authState.user['name']?.split(' ').first ?? '')
        : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            context.read<ScholarshipBloc>()
            ..add(const LoadFeaturedEvent())
            ..add(const LoadRecommendedEvent())
            ..add(const LoadScholarshipsEvent(refresh: true));
            context.read<NotificationBloc>().add(LoadNotificationsEvent());
          },
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              pinned: true,
              expandedHeight: 0,
              toolbarHeight: 72,
              flexibleSpace: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Greeting part
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_getGreeting(),
                                    style: const TextStyle(
                                        fontSize: AppTheme.fsTitleLg,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary)),
                                Text(userName.isEmpty ? 'Explorer' : userName,
                                    style: const TextStyle(
                                        fontSize: AppTheme.fsTitleLg,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary)),
                                const Text(' 👋',
                                    style: TextStyle(fontSize: AppTheme.fsTitleLg)),
                              ],
                            ),
                            const Text('Trouvez votre bourse idéale',
                                style: TextStyle(
                                    fontSize: AppTheme.fsLabelSm,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        // Icons part
                        Row(
                          children: [
                            BlocBuilder<NotificationBloc, NotificationState>(
                              buildWhen: (prev, curr) =>
                                  curr is NotificationsLoadedState,
                              builder: (context, state) {
                                final count =
                                    (state is NotificationsLoadedState)
                                        ? state.unreadCount
                                        : 0;
                                return _IconButton(
                                  onTap: () => context.push('/notifications'),
                                  child: _NotificationIcon(count: count),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _ProfileAvatar(userName: userName),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Search bar
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SearchBar(), // ⚡ Extrait dans un widget séparé
              ),
            ),

            // Stats
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _StatCard(
                        label: '500+',
                        sublabel: 'Bourses',
                        icon: Icons.school_rounded,
                        color: AppTheme.primary),
                    SizedBox(width: 10),
                    _StatCard(
                        label: '54',
                        sublabel: 'Pays',
                        icon: Icons.public_rounded,
                        color: AppTheme.secondary),
                    SizedBox(width: 10),
                    _StatCard(
                        label: '10k+',
                        sublabel: 'Étudiants',
                        icon: Icons.people_rounded,
                        color: AppTheme.accent),
                  ],
                ),
              ),
            ),

            // Featured
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: _SectionHeader(title: 'À la une ⭐', route: '/explore'),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<ScholarshipBloc, ScholarshipState>(
                buildWhen: (prev, curr) =>
                    curr is ScholarshipsLoadedState ||
                    curr is ScholarshipLoadingState,
                builder: (context, state) {
                  if (state is ScholarshipLoadingState)
                    return const ShimmerHorizontalList();
                  if (state is ScholarshipsLoadedState &&
                      state.featured.isNotEmpty) {
                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.featured.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: FeaturedCard(
                              scholarship: state
                                  .featured[i]), // ⚡ Plus d'animation par item
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Recommended
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                child:
                    _SectionHeader(title: 'Recommandations', route: '/explore'),
              ),
            ),
            BlocBuilder<ScholarshipBloc, ScholarshipState>(
              buildWhen: (prev, curr) =>
                  curr is ScholarshipsLoadedState ||
                  curr is ScholarshipLoadingState,
              builder: (context, state) {
                if (state is ScholarshipsLoadedState) {
                  final scholarships = state.recommended.isEmpty
                      ? state.scholarships.take(5).toList()
                      : state.recommended;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: ScholarshipCard(
                          key: ValueKey(scholarships[i].id),
                          scholarship: scholarships[i],
                        ), // ⚡ Plus d'animation par item
                      ),
                      childCount: scholarships.length,
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: ShimmerList());
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ⚡ NOUVEAU : Widget stateless pour l'icône de notification
class _NotificationIcon extends StatelessWidget {
  final int count;
  const _NotificationIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined,
            color: AppTheme.textPrimary, size: 22),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                  color: AppTheme.accent, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      fontSize: AppTheme.fsBadgeSm,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ⚡ OPTIMISÉ : _IconButton transformé en StatelessWidget
class _IconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ⚡ NOUVEAU : Widget pour l'avatar
class _ProfileAvatar extends StatelessWidget {
  final String userName;
  const _ProfileAvatar({required this.userName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x4D0055FF), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fsBodyLg),
          ),
        ),
      ),
    );
  }
}

// ⚡ NOUVEAU : SearchBar extraite
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/explore'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Rechercher des bourses...',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fsBodyMd)),
            ),
            _SearchFilterIcon(),
          ],
        ),
      ),
    );
  }
}

// ⚡ NOUVEAU : Icône de filtre extraite
class _SearchFilterIcon extends StatelessWidget {
  const _SearchFilterIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 16),
    );
  }
}

// ⚡ OPTIMISÉ : _StatCard avec const
class _StatCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.sublabel,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: AppTheme.fsTitleLg,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: AppTheme.fsBodySm, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ⚡ OPTIMISÉ : _SectionHeader avec const
class _SectionHeader extends StatelessWidget {
  final String title;
  final String route;
  const _SectionHeader({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        GestureDetector(
          onTap: () => context.go(route),
          child: const Text('Voir tout',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: AppTheme.fsBodyMd,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
