import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';

abstract class NotificationEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {}

class MarkReadEvent extends NotificationEvent {
  final String id;
  MarkReadEvent(this.id);
  @override List<Object?> get props => [id];
}

class MarkAllReadEvent extends NotificationEvent {}

// NOUVEAUX ÉVÉNEMENTS DE SUPPRESSION
class DeleteNotificationEvent extends NotificationEvent {
  final String id;
  DeleteNotificationEvent(this.id);
  @override List<Object?> get props => [id];
}

class DeleteAllNotificationsEvent extends NotificationEvent {}

abstract class NotificationState extends Equatable {
  @override List<Object?> get props => [];
}

class NotificationInitialState extends NotificationState {}

class NotificationsLoadedState extends NotificationState {
  final List<dynamic> notifications;
  final int unreadCount;
  final Set<String>? deletingIds; // ← Ajouté pour gérer les animations
  
  NotificationsLoadedState({
    required this.notifications, 
    required this.unreadCount,
    this.deletingIds,
  });
  
  @override List<Object?> get props => [notifications, unreadCount, deletingIds];
}

class NotificationErrorState extends NotificationState {}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient apiClient;

  NotificationBloc({required this.apiClient}) : super(NotificationInitialState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<MarkReadEvent>(_onMarkRead);
    on<MarkAllReadEvent>(_onMarkAllRead);
    
    // NOUVEAUX HANDLERS
    on<DeleteNotificationEvent>(_onDelete);
    on<DeleteAllNotificationsEvent>(_onDeleteAll);
  }

  Future<void> _onLoad(LoadNotificationsEvent event, Emitter<NotificationState> emit) async {
    try {
      final [notifRes, countRes] = await Future.wait([
        apiClient.getNotifications(),
        apiClient.getUnreadCount(),
      ]);
      emit(NotificationsLoadedState(
        notifications: notifRes.data['notifications'] as List,
        unreadCount: countRes.data['count'] as int,
        deletingIds: {}, // Initialiser avec un set vide
      ));
    } catch (_) {
      emit(NotificationErrorState());
    }
  }

  Future<void> _onMarkRead(MarkReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await apiClient.markNotificationRead(event.id);
      add(LoadNotificationsEvent());
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(MarkAllReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await apiClient.markAllNotificationsRead();
      add(LoadNotificationsEvent());
    } catch (_) {}
  }

  // NOUVEAU : Supprimer une notification
  Future<void> _onDelete(DeleteNotificationEvent event, Emitter<NotificationState> emit) async {
    try {
      // Marquer comme en cours de suppression pour animation
      if (state is NotificationsLoadedState) {
        final currentState = state as NotificationsLoadedState;
        final updatedDeletingIds = Set<String>.from(currentState.deletingIds ?? {})
          ..add(event.id);
        
        emit(NotificationsLoadedState(
          notifications: currentState.notifications,
          unreadCount: currentState.unreadCount,
          deletingIds: updatedDeletingIds,
        ));
      }

      // Appel API
      await apiClient.deleteNotification(event.id);

      // Recharger les notifications
      add(LoadNotificationsEvent());
    } catch (_) {
      // En cas d'erreur, recharger pour annuler le marquage
      add(LoadNotificationsEvent());
      
      // Optionnel : montrer une erreur
      emit(NotificationErrorState());
    }
  }

  // NOUVEAU : Supprimer toutes les notifications
  Future<void> _onDeleteAll(DeleteAllNotificationsEvent event, Emitter<NotificationState> emit) async {
    try {
      // Marquer toutes comme en cours de suppression (optionnel)
      if (state is NotificationsLoadedState) {
        final currentState = state as NotificationsLoadedState;
        final allIds = currentState.notifications.map((n) => n['id'] as String).toSet();
        
        emit(NotificationsLoadedState(
          notifications: currentState.notifications,
          unreadCount: currentState.unreadCount,
          deletingIds: allIds,
        ));
      }

      // Appel API
      await apiClient.deleteAllNotifications();

      // Recharger (normalement liste vide)
      add(LoadNotificationsEvent());
    } catch (_) {
      add(LoadNotificationsEvent());
      emit(NotificationErrorState());
    }
  }
}