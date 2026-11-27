import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'https://scholarhub-backend-n8de.onrender.com/api';
  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Ne jamais journaliser les en-têtes, mots de passe, jetons ou réponses API.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await deleteToken();
          }
          handler.next(error);
        },
      ),
    );

    _wakeUpServer();
  }

  Future<void> _wakeUpServer() async {
    try {
      await Dio().get(
        'https://scholarhub-backend-n8de.onrender.com/health',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {}
  }

  // Migration transparente des anciennes sessions SharedPreferences
  // vers le stockage sécurisé du système (Keychain iOS / Keystore Android).
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;

    await _secureStorage.write(key: _tokenKey, value: legacyToken);
    await prefs.remove(_tokenKey);
    return legacyToken;
  }

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);
  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);
  Future<Response> getMe() => _dio.get('/auth/me');
  Future<Response> logout() => _dio.post('/auth/logout');
  Future<Response> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});
  Future<Response> resetPassword(String token, String password) =>
      _dio.post('/auth/reset-password',
          data: {'token': token, 'password': password});

  // Scholarships
  Future<Response> getScholarships(Map<String, dynamic> params) =>
      _dio.get('/scholarships', queryParameters: params);
  Future<Response> getFeaturedScholarships() =>
      _dio.get('/scholarships/featured');
  Future<Response> getScholarship(String id) => _dio.get('/scholarships/$id');
  Future<Response> getRecommended() =>
      _dio.get('/scholarships/user/recommended');
  Future<Response> saveScholarship(String id) =>
      _dio.post('/scholarships/$id/save');
  Future<Response> unsaveScholarship(String id) =>
      _dio.delete('/scholarships/$id/save');

  // Users
  Future<Response> getProfile() => _dio.get('/users/profile');
  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/users/profile', data: data);
  Future<Response> getSaved() => _dio.get('/users/saved');
  Future<Response> getApplications() => _dio.get('/users/applications');

  // FCM Token
  Future<void> updateFcmToken(String? token) =>
      _dio.patch('/users/fcm-token', data: {'fcmToken': token});

  // Notifications
  Future<Response> getNotifications() => _dio.get('/notifications');
  Future<Response> markNotificationRead(String id) =>
      _dio.patch('/notifications/$id/read');
  Future<Response> markAllNotificationsRead() =>
      _dio.patch('/notifications/read-all');
  Future<Response> getUnreadCount() => _dio.get('/notifications/unread-count');
  Future<Response> deleteNotification(String id) =>
      _dio.delete('/notifications/$id');
  Future<Response> deleteAllNotifications() =>
      _dio.delete('/notifications/all');

  // Chat
  Future<Response> sendChatMessage({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? userProfile,
  }) =>
      _dio.post('/chat', data: {
        'messages': messages,
        if (userProfile != null) 'userProfile': userProfile,
      });
  Future<Response> getChatHistory() => _dio.get('/chat/history');

  // Support
  Future<Response> createSupportTicket(Map<String, dynamic> data) =>
      _dio.post('/support', data: data);
  Future<Response> getMyTickets() => _dio.get('/support/my');
}
