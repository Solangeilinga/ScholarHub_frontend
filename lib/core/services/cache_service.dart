import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // Pour kReleaseMode

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _scholarshipBox = 'scholarships';
  static const String _userBox = 'user';
  static const String _settingsBox = 'settings';
  static const String _lastUpdateKey = 'last_update';

  // ⚡ Getter pour les logs conditionnels
  static void _log(String message) {
    if (!kReleaseMode) {
      debugPrint('📦 CacheService: $message');
    }
  }

  Future<void> init() async {
    try {
      // Ouvrir les boxes Hive
      await Hive.openBox(_scholarshipBox);
      await Hive.openBox(_userBox);
      await Hive.openBox(_settingsBox);
      
      _log('initialisé avec succès');
    } catch (e) {
      _log('Erreur initialisation: $e');
    }
  }

  // Méthodes pour les bourses
  Future<void> cacheScholarships(List<Map<String, dynamic>> scholarships) async {
    try {
      final box = Hive.box(_scholarshipBox);
      await box.put('all', scholarships);
      await box.put(_lastUpdateKey, DateTime.now().toIso8601String());
      _log('${scholarships.length} bourses mises en cache');
    } catch (e) {
      _log('Erreur cacheScholarships: $e');
    }
  }

  List<Map<String, dynamic>>? getCachedScholarships() {
    try {
      final box = Hive.box(_scholarshipBox);
      return box.get('all');
    } catch (e) {
      _log('Erreur getCachedScholarships: $e');
      return null;
    }
  }

  // Vérifier si le cache est encore valide (24h)
  bool isCacheValid() {
    try {
      final box = Hive.box(_scholarshipBox);
      final lastUpdate = box.get(_lastUpdateKey);
      if (lastUpdate == null) return false;
      
      final lastDate = DateTime.parse(lastUpdate);
      final age = DateTime.now().difference(lastDate);
      return age.inHours < 24; // Cache valide 24h
    } catch (e) {
      _log('Erreur isCacheValid: $e');
      return false;
    }
  }

  // Méthodes pour les données utilisateur
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final box = Hive.box(_userBox);
      await box.put('user', userData);
      await box.put('user_last_update', DateTime.now().toIso8601String());
    } catch (e) {
      _log('Erreur cacheUserData: $e');
    }
  }

  Map<String, dynamic>? getCachedUserData() {
    try {
      final box = Hive.box(_userBox);
      return box.get('user');
    } catch (e) {
      _log('Erreur getCachedUserData: $e');
      return null;
    }
  }

  // Méthodes pour les paramètres
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = Hive.box(_settingsBox);
      await box.put(key, value);
    } catch (e) {
      _log('Erreur saveSetting: $e');
    }
  }

  dynamic getSetting(String key) {
    try {
      final box = Hive.box(_settingsBox);
      return box.get(key);
    } catch (e) {
      _log('Erreur getSetting: $e');
      return null;
    }
  }

  // Nettoyer le cache
  Future<void> clearCache() async {
    try {
      await Hive.box(_scholarshipBox).clear();
      await Hive.box(_userBox).clear();
      await Hive.box(_settingsBox).clear();
      
      // Nettoyer aussi le cache des images si disponible
      await _clearImageCache();
      
      _log('Cache nettoyé avec succès');
    } catch (e) {
      _log('Erreur clearCache: $e');
    }
  }

  // ⚡ Méthode pour nettoyer le cache des images
  Future<void> _clearImageCache() async {
    try {
      // Vider le cache des images
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Si vous utilisez cached_network_image, vider aussi son cache
      await CachedNetworkImage.evictFromCache(''); // Vide tout le cache
      
      _log('Cache images nettoyé');
    } catch (e) {
      _log('Erreur clearImageCache: $e');
    }
  }

  // ⚡ Méthode pour obtenir la taille du cache
  Future<Map<String, int>> getCacheSize() async {
    try {
      final scholarshipsBox = Hive.box(_scholarshipBox);
      final userBox = Hive.box(_userBox);
      final settingsBox = Hive.box(_settingsBox);
      
      return {
        'scholarships': scholarshipsBox.length,
        'user': userBox.length,
        'settings': settingsBox.length,
        'total': scholarshipsBox.length + userBox.length + settingsBox.length,
      };
    } catch (e) {
      _log('Erreur getCacheSize: $e');
      return {};
    }
  }

  // ⚡ Méthode pour supprimer les vieilles données
  Future<void> cleanOldCache({Duration olderThan = const Duration(days: 7)}) async {
    try {
      final box = Hive.box(_scholarshipBox);
      final lastUpdate = box.get(_lastUpdateKey);
      
      if (lastUpdate != null) {
        final lastDate = DateTime.parse(lastUpdate);
        if (DateTime.now().difference(lastDate) > olderThan) {
          _log('Cache trop vieux, nettoyage...');
          await box.clear();
        }
      }
    } catch (e) {
      _log('Erreur cleanOldCache: $e');
    }
  }
}

// ⚡ Extension pour faciliter l'utilisation
extension CacheExtension on BuildContext {
  CacheService get cacheService => CacheService();
}