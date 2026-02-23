import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/notification_bloc.dart';
import '../../../core/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoadedState && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationBloc>().add(MarkAllReadEvent()),
                  child: const Text('Tout lire'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationsLoadedState) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text('Aucune notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<NotificationBloc>().add(LoadNotificationsEvent()),
              child: ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (_, i) {
                  final notif = state.notifications[i];
                  final isRead = notif['isRead'] as bool;
                  return Dismissible(
                    key: Key(notif['id']),
                    onDismissed: (_) => context.read<NotificationBloc>().add(MarkReadEvent(notif['id'])),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.05),
                        border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _notifColor(notif['type']).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_notifIcon(notif['type']), color: _notifColor(notif['type']), size: 20),
                        ),
                        title: Text(
                          notif['title'],
                          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif['body'], style: const TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM · HH:mm').format(DateTime.parse(notif['createdAt'])),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        trailing: !isRead
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))
                            : null,
                        onTap: () {
                          if (!isRead) {
                            context.read<NotificationBloc>().add(MarkReadEvent(notif['id']));
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Color _notifColor(String? type) {
    switch (type) {
      case 'NEW_SCHOLARSHIP': return AppTheme.primary;
      case 'DEADLINE_REMINDER': return AppTheme.accent;
      case 'APPLICATION_UPDATE': return AppTheme.secondary;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _notifIcon(String? type) {
    switch (type) {
      case 'NEW_SCHOLARSHIP': return Icons.school_rounded;
      case 'DEADLINE_REMINDER': return Icons.timer_outlined;
      case 'APPLICATION_UPDATE': return Icons.assignment_turned_in_outlined;
      default: return Icons.notifications_outlined;
    }
  }
}
