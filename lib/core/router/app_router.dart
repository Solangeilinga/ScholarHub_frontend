import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/scholarships/screens/scholarship_list_screen.dart';
import '../../features/scholarships/screens/scholarship_detail_screen.dart';
import '../../features/scholarships/screens/filter_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/support/screens/support_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthStateNotifier(),
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is AuthAuthenticatedState;
      final isLoading = authState is AuthLoadingState || authState is AuthInitialState;
      final location = state.matchedLocation;

      // Sur le splash — attendre le chargement
      if (location == '/splash') {
        if (isLoading) return null; // reste sur splash
        if (isLoggedIn) return '/home';
        if (!hasSeenOnboarding) return '/onboarding';
        return '/auth/login';
      }

      // Pas encore chargé → reste là où on est
      if (isLoading) return null;

      // Non connecté → onboarding ou login
      if (!isLoggedIn && !location.startsWith('/auth') && location != '/onboarding') {
        return '/auth/login';
      }

      // Connecté → pas sur auth
      if (isLoggedIn && (location.startsWith('/auth') || location == '/onboarding')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/scholarships/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ScholarshipDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/filter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => FilterScreen(filters: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SupportScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/explore', builder: (_, __) => const ScholarshipListScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}

// Notifie le router quand l'AuthBloc change d'état
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier();
}