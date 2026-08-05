import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/services/preload_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/scholarships/bloc/scholarship_bloc.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/widgets/app_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de base
  await initializeDateFormatting('fr_FR', null);
  await OnboardingScreen.resetIfNewVersion();

  // 2. Initialisation Hive pour le cache local
  // Sur web, pas de vrai système de fichiers : path_provider n'y est pas
  // disponible, Hive utilise IndexedDB automatiquement sans chemin.
  try {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    }
    await CacheService().init(); // Initialise toutes les boxes Hive
    debugPrint('✅ Hive initialisé');
  } catch (e) {
    debugPrint('⚠️ Erreur Hive: $e');
  }

  // 3. Configuration du cache des images
  _configureImageCache();

  // 4. Configuration des orientations (no-op sur web, mais sans danger)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 5. Configuration de la barre système
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ScholarHubApp());
}

void _configureImageCache() {
  // Désactiver les logs du cache en production
  CachedNetworkImage.logLevel = CacheManagerLogLevel.none;

  // Configurer la taille du cache d'images de Flutter
  PaintingBinding.instance.imageCache.maximumSize =
      200 * 1024 * 1024; // 200 MB en bytes
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      200 * 1024 * 1024; // 200 MB

  debugPrint('✅ Cache images configuré: 200MB max');
}

class ScholarHubApp extends StatefulWidget {
  const ScholarHubApp({super.key});

  @override
  State<ScholarHubApp> createState() => _ScholarHubAppState();
}

class _ScholarHubAppState extends State<ScholarHubApp> {
  late final ApiClient _apiClient;
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _initFirebase();
    _startPreloading();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await FirebaseService.initialize(_apiClient);
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  Future<void> _startPreloading() async {
    // Attendre que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // On considère l'app prête dès le premier frame pour laisser le router
      // afficher la page correspondante (splash, login, home...).
      // Le préchargement se poursuivra en arrière-plan sans bloquer l'UI.
      setState(() => _isPreloaded = true);

      // Lancer le préchargement en arrière-plan (on ne bloque pas la vue)
      await context.read<PreloadService>().preloadAll(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _apiClient),
        RepositoryProvider(create: (_) => PreloadService()),
        RepositoryProvider(create: (_) => CacheService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(apiClient: ctx.read<ApiClient>())
              ..add(AuthCheckEvent()),
          ),
          BlocProvider(
            create: (ctx) => ScholarshipBloc(
              apiClient: ctx.read<ApiClient>(),
              cacheService: ctx.read<CacheService>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => NotificationBloc(
              apiClient: ctx.read<ApiClient>(),
            ),
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
            builder: (context, child) {
              // Afficher un écran de chargement si pas préchargé
              if (!_isPreloaded) {
                return const _PreloadingScreen();
              }
              return child!;
            },
          ),
        ),
      ),
    );
  }
}

// Écran de préchargement
class _PreloadingScreen extends StatelessWidget {
  const _PreloadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (assurez-vous que le fichier existe)
            const AppLogo(
              size: 120,
              radius: 60,
              isDarkBackground: true,
            ),
            const SizedBox(height: 40),
            Text(
              'ScholarHub',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Préparation de votre expérience...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
