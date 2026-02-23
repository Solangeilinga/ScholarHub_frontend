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

abstract class NotificationState extends Equatable {
  @override List<Object?> get props => [];
}
class NotificationInitialState extends NotificationState {}
class NotificationsLoadedState extends NotificationState {
  final List<dynamic> notifications;
  final int unreadCount;
  NotificationsLoadedState({required this.notifications, required this.unreadCount});
  @override List<Object?> get props => [notifications, unreadCount];
}
class NotificationErrorState extends NotificationState {}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient apiClient;

  NotificationBloc({required this.apiClient}) : super(NotificationInitialState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<MarkReadEvent>(_onMarkRead);
    on<MarkAllReadEvent>(_onMarkAllRead);
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
}
