import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/firebase_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AuthCheckEvent extends AuthEvent {}
class AuthLoginEvent extends AuthEvent {
  final String email, password;
  AuthLoginEvent({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}
class AuthRegisterEvent extends AuthEvent {
  final String name, email, password;
  final String? country;
  AuthRegisterEvent({required this.name, required this.email, required this.password, this.country});
  @override List<Object?> get props => [name, email, password, country];
}
class AuthLogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitialState extends AuthState {}
class AuthLoadingState extends AuthState {}
class AuthAuthenticatedState extends AuthState {
  final Map<String, dynamic> user;
  AuthAuthenticatedState({required this.user});
  @override List<Object?> get props => [user];
}
class AuthUnauthenticatedState extends AuthState {}
class AuthErrorState extends AuthState {
  final String message;
  AuthErrorState({required this.message});
  @override List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(AuthInitialState()) {
    on<AuthCheckEvent>(_onCheck);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final token = await apiClient.getToken();
      if (token == null) return emit(AuthUnauthenticatedState());
      final response = await apiClient.getMe();
      emit(AuthAuthenticatedState(user: response.data['user']));
      // Envoyer le token FCM si déjà connecté
      FirebaseService.onLogin(apiClient);
    } catch (_) {
      await apiClient.deleteToken();
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final response = await apiClient.login({'email': event.email, 'password': event.password});
      await apiClient.saveToken(response.data['token']);
      // Envoyer le token FCM au backend après login
      await FirebaseService.onLogin(apiClient);
      emit(AuthAuthenticatedState(user: response.data['user']));
    } catch (e) {
      emit(AuthErrorState(message: _parseError(e)));
    }
  }

  Future<void> _onRegister(AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final response = await apiClient.register({
        'name': event.name,
        'email': event.email,
        'password': event.password,
        if (event.country != null) 'country': event.country,
      });
      await apiClient.saveToken(response.data['token']);
      // Envoyer le token FCM au backend après inscription
      await FirebaseService.onLogin(apiClient);
      emit(AuthAuthenticatedState(user: response.data['user']));
    } catch (e) {
      emit(AuthErrorState(message: _parseError(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    // Supprimer le token FCM du backend avant déconnexion
    await FirebaseService.onLogout(apiClient);
    await apiClient.deleteToken();
    emit(AuthUnauthenticatedState());
  }

  String _parseError(dynamic e) {
    try {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
        }
        final data = e.response?.data;
        if (data == null) return 'Erreur de connexion au serveur';
        if (data['error'] != null) return data['error'];
        if (data['message'] != null) return data['message'];
        if (data['errors'] != null && data['errors'] is List) {
          final errors = data['errors'] as List;
          return errors.map((e) => e['msg']).join('\n');
        }
      }
      return 'Une erreur est survenue';
    } catch (_) {
      return 'Une erreur est survenue';
    }
  }
}