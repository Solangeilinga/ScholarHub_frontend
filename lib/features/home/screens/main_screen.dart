import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../../core/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _tabs = [
    _TabData(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _TabData(path: '/explore', icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Explorer'),
    _TabData(path: '/chat', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'ScholarBot'),
    _TabData(path: '/saved', icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'Sauvegardés'),
    _TabData(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  void _onTabTapped(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    HapticFeedback.lightImpact();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000), // ⚡ alpha en dur pour const
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                return _TabItem(
                  key: ValueKey(i), // ⚡ key pour éviter les rebuilds
                  tab: _tabs[i],
                  isSelected: currentIndex == i,
                  onTap: () => _onTabTapped(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ⚡ Classe de données constante
class _TabData {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _TabData({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ⚡ Widget optimisé sans animation
class _TabItem extends StatelessWidget {
  final _TabData tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isChat = tab.path == '/chat';
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur + icône
            Container(
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
                  // ⚡ Plus d'AnimatedSwitcher, simple condition
                  Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    color: isSelected
                        ? (isChat ? Colors.white : AppTheme.primary)
                        : AppTheme.textSecondary,
                    size: 22,
                  ),
                  
                  // Badge AI
                  if (isChat && !isSelected)
                    const Positioned(
                      top: -8,
                      right: -10,
                      child: _AIBadge(), // ⚡ Widget extrait
                    ),
                  
                  // Badge notifications (uniquement pour l'onglet notifications)
                  if (tab.path == '/notifications')
                    const _NotificationBadge(),
                ],
              ),
            ),
            const SizedBox(height: 3),
            
            // Label
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTheme.fsNavLabel,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⚡ Widget extrait pour le badge AI (constant)
class _AIBadge extends StatelessWidget {
  const _AIBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
            fontSize: AppTheme.fsBadgeXs,
            fontWeight: FontWeight.w900,
            color: Colors.white),
      ),
    );
  }
}

// ⚡ Widget extrait pour le badge notification (optimisé avec BlocSelector)
class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context) {
    // ⚡ BlocSelector au lieu de BlocBuilder pour ne rebuild que le texte
    return BlocSelector<NotificationBloc, NotificationState, int>(
      selector: (state) {
        if (state is NotificationsLoadedState) return state.unreadCount;
        return 0;
      },
      builder: (context, count) {
        if (count == 0) return const SizedBox.shrink();
        
        return Positioned(
          top: -8,
          right: -10,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                fontSize: AppTheme.fsBadgeSm,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
