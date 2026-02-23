import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/scholarships/bloc/scholarship_bloc.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);
  await OnboardingScreen.resetIfNewVersion();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ScholarHubApp());
}

class ScholarHubApp extends StatefulWidget {
  const ScholarHubApp({super.key});

  @override
  State<ScholarHubApp> createState() => _ScholarHubAppState();
}

class _ScholarHubAppState extends State<ScholarHubApp> {
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await FirebaseService.initialize(_apiClient);
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _apiClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(apiClient: ctx.read<ApiClient>())
              ..add(AuthCheckEvent()),
          ),
          BlocProvider(
            create: (ctx) => ScholarshipBloc(apiClient: ctx.read<ApiClient>()),
          ),
          BlocProvider(
            create: (ctx) => NotificationBloc(apiClient: ctx.read<ApiClient>()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Rafraîchit le router à chaque changement d'état auth
            AppRouter.router.refresh();
          },
          child: MaterialApp.router(
            title: 'ScholarHub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}