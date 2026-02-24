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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerController.forward();

    context.read<ScholarshipBloc>()
      ..add(LoadFeaturedEvent())
      ..add(LoadRecommendedEvent())
      ..add(LoadScholarshipsEvent());
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticatedState
        ? authState.user['name']?.split(' ').first ?? ''
        : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          context.read<ScholarshipBloc>()
            ..add(LoadFeaturedEvent())
            ..add(LoadRecommendedEvent())
            ..add(LoadScholarshipsEvent(refresh: true));
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${_getGreeting()}, ',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                                Text(userName.isEmpty ? 'Explorer' : userName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                                const Text(' 👋', style: TextStyle(fontSize: 17)),
                              ],
                            ),
                            const Text('Trouvez votre bourse idéale',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                        Row(
                          children: [
                            BlocBuilder<NotificationBloc, NotificationState>(
                              builder: (context, state) {
                                int count = 0;
                                if (state is NotificationsLoadedState) count = state.unreadCount;
                                return _IconButton(
                                  onTap: () => context.push('/notifications'),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 22),
                                      if (count > 0)
                                        Positioned(
                                          top: -4, right: -4,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 16, height: 16,
                                            decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                                            child: Center(
                                              child: Text(count > 9 ? '9+' : '$count',
                                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.go('/profile'),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.go('/explore'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Rechercher des bourses...',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stats
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _StatCard(label: '500+', sublabel: 'Bourses', icon: Icons.school_rounded, color: AppTheme.primary),
                    SizedBox(width: 10),
                    _StatCard(label: '54', sublabel: 'Pays', icon: Icons.public_rounded, color: AppTheme.secondary),
                    SizedBox(width: 10),
                    _StatCard(label: '10k+', sublabel: 'Étudiants', icon: Icons.people_rounded, color: AppTheme.accent),
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
                    curr is ScholarshipsLoadedState || curr is ScholarshipLoadingState,
                builder: (context, state) {
                  if (state is ScholarshipLoadingState) return const ShimmerHorizontalList();
                  if (state is ScholarshipsLoadedState && state.featured.isNotEmpty) {
                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.featured.length,
                        itemBuilder: (_, i) => _AnimatedListItem(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: FeaturedCard(scholarship: state.featured[i]),
                          ),
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
                child: _SectionHeader(title: 'Recommandations', route: '/explore'),
              ),
            ),
            BlocBuilder<ScholarshipBloc, ScholarshipState>(
              buildWhen: (prev, curr) =>
                  curr is ScholarshipsLoadedState || curr is ScholarshipLoadingState,
              builder: (context, state) {
                if (state is ScholarshipsLoadedState) {
                  final scholarships = state.recommended.isEmpty
                      ? state.scholarships.take(5).toList()
                      : state.recommended;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AnimatedListItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: ScholarshipCard(scholarship: scholarships[i]),
                        ),
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

class _IconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconButton({required this.child, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.border : AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedListItem({required this.child, required this.index});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.sublabel, required this.icon, required this.color});

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
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text(sublabel, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

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
              style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}