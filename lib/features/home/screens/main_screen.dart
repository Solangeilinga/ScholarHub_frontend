import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../../core/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _controllers;

  final List<({String path, IconData icon, IconData activeIcon, String label})> _tabs = [
    (path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    (path: '/explore', icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Explorer'),
    (path: '/chat', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'ScholarBot'),
    (path: '/saved', icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'Sauvegardés'),
    (path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _tabs.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.path));
    if (index != -1 && index != _currentIndex) {
      _animateTo(index);
    }
  }

  void _animateTo(int index) {
    _controllers[_currentIndex].reverse();
    _controllers[index].forward();
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _animateTo(index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isSelected = _currentIndex == i;
                final isChat = tab.path == '/chat';

                return GestureDetector(
                  onTap: () => _onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: _TabItem(
                    tab: tab,
                    isSelected: isSelected,
                    isChat: isChat,
                    controller: _controllers[i],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final ({String path, IconData icon, IconData activeIcon, String label}) tab;
  final bool isSelected;
  final bool isChat;
  final AnimationController controller;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.isChat,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnim.value,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur + icône
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isChat ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? (isChat ? Colors.white : AppTheme.primary)
                              : AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                      // Badge AI
                      if (isChat && !isSelected)
                        Positioned(
                          top: -8,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ),
                      // Badge notifications
                      if (tab.path == '/notifications')
                        BlocBuilder<NotificationBloc, NotificationState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is NotificationsLoadedState) count = state.unreadCount;
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: -8,
                              right: -10,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isChat ? AppTheme.primary : AppTheme.primary)
                        : AppTheme.textSecondary,
                  ),
                  child: Text(tab.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}