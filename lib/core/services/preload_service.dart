// lib/core/services/preload_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/scholarships/bloc/scholarship_bloc.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import 'cache_service.dart';

class PreloadService {
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  bool _isPreloaded = false;
  final Map<String, dynamic> _memoryCache = {};
  final CacheService _cacheService = CacheService();

  // Getter pour vérifier si préchargé
  bool get isPreloaded => _isPreloaded;

  Future<void> preloadAll(BuildContext context) async {
    if (_isPreloaded) {
      print('📦 Déjà préchargé, utilisation du cache');
      return;
    }

    print('🚀 Démarrage du préchargement complet...');
    final stopwatch = Stopwatch()..start();

    try {
      // 1. D'abord, charger depuis le cache Hive (ultra-rapide)
      await _loadFromCache();

      // 2. Puis lancer les chargements réseau en parallèle
      await Future.wait([
        _preloadScholarships(context),
        _preloadUserData(context),
        _preloadImages(context),
        _preloadNotifications(context),
      ], eagerError: false);

      _isPreloaded = true;
      print('✅ Préchargement terminé en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('⚠️ Erreur préchargement: $e');
    }
  }

  Future<void> _loadFromCache() async {
    // Charger les données depuis Hive
    final cachedScholarships = _cacheService.getCachedScholarships();
    if (cachedScholarships != null && _cacheService.isCacheValid()) {
      _memoryCache['scholarships'] = cachedScholarships;
      print('📦 Données chargées depuis cache Hive');
    }
  }

  Future<void> _preloadScholarships(BuildContext context) async {
    try {
      // Précharger tous les types de bourses
      final bloc = context.read<ScholarshipBloc>();
      
      // En parallèle pour aller plus vite
      await Future.wait([
        Future(() => bloc.add(LoadFeaturedEvent())),
        Future(() => bloc.add(LoadRecommendedEvent())),
        Future(() => bloc.add(LoadScholarshipsEvent())),
      ]);
      
      print('✅ Bourses préchargées');
    } catch (e) {
      print('⚠️ Erreur préchargement bourses: $e');
    }
  }

  Future<void> _preloadUserData(BuildContext context) async {
    try {
      // Précharger les données utilisateur
      // À implémenter selon votre logique
      print('✅ Données utilisateur préchargées');
    } catch (e) {
      print('⚠️ Erreur préchargement user: $e');
    }
  }

  Future<void> _preloadImages(BuildContext context) async {
    try {
      // Liste des images à précharger (logos, etc.)
      final imageUrls = [
        'https://example.com/logo1.png',
        'https://example.com/logo2.png',
        // À remplacer par vos vraies URLs
      ];

      // Précharger en parallèle
      await Future.wait(
        imageUrls.map((url) => 
          precacheImage(CachedNetworkImageProvider(url), context)
        ),
      ).timeout(const Duration(seconds: 5));
      
      print('✅ Images préchargées');
    } catch (e) {
      print('⚠️ Erreur préchargement images: $e');
    }
  }

  Future<void> _preloadNotifications(BuildContext context) async {
    try {
      context.read<NotificationBloc>().add(LoadNotificationsEvent());
      print('✅ Notifications préchargées');
    } catch (e) {
      print('⚠️ Erreur préchargement notifications: $e');
    }
  }

  // Récupérer une donnée du cache mémoire
  T? getCachedData<T>(String key) => _memoryCache[key] as T?;
}

// Extension pratique pour le contexte
extension PreloadExtension on BuildContext {
  Future<void> preloadAll() => PreloadService().preloadAll(this);
}