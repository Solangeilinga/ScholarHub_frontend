import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'https://scholarhubbackend-production.up.railway.app/api';

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

    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }
          handler.next(error);
        },
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: false,
      ),
    ]);

    _wakeUpServer();
  }

  Future<void> _wakeUpServer() async {
    try {
      await Dio().get(
        'https://scholarhubbackend-production.up.railway.app/health',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {}
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);
  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);
  Future<Response> getMe() => _dio.get('/auth/me');
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
  Future<Response> deleteScholarship(String id) =>
      _dio.delete('/admin/scholarships/$id');

  // Users
  Future<Response> getProfile() => _dio.get('/users/profile');
  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/users/profile', data: data);
  Future<Response> getSaved() => _dio.get('/users/saved');
  Future<Response> getApplications() => _dio.get('/users/applications');
  Future<Response> getAdminUsers() => _dio.get('/admin/users');

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
  
  // NOUVELLES MÉTHODES DE SUPPRESSION
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

  // Support
  Future<Response> createSupportTicket(Map<String, dynamic> data) =>
      _dio.post('/support', data: data);
  Future<Response> getMyTickets() => _dio.get('/support/my');
}