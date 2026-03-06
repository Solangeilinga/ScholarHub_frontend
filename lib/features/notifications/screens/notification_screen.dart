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

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la notification ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationBloc>().add(DeleteNotificationEvent(id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoadedState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.unreadCount > 0)
                      TextButton(
                        onPressed: () => context.read<NotificationBloc>().add(MarkAllReadEvent()),
                        child: const Text('Tout lire'),
                      ),
                    if (state.notifications.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Tout supprimer ?'),
                              content: const Text('Voulez-vous supprimer toutes vos notifications ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.read<NotificationBloc>().add(DeleteAllNotificationsEvent());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Tout supprimer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
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
                    Text(
                      'Aucune notification',
                      style: TextStyle(
                          fontSize: AppTheme.fsTitleLg,
                          fontWeight: FontWeight.w600),
                    ),
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
                  final isDeleting = state.deletingIds?.contains(notif['id']) ?? false;

                  // Animation de disparition pendant la suppression
                  if (isDeleting) {
                    return const SizedBox.shrink();
                  }

                  return Dismissible(
                    key: Key(notif['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Supprimer ?'),
                          content: const Text('Voulez-vous supprimer cette notification ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                              ),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) {
                      context.read<NotificationBloc>().add(DeleteNotificationEvent(notif['id']));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isRead ? Colors.transparent : AppTheme.primary.withValues(alpha: 0.05),
                        border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _notifColor(notif['type']).withValues(alpha: 0.15),
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
                              DateFormat('dd MMM · HH:mm', 'fr_FR')
                                  .format(DateTime.parse(notif['createdAt'])),
                              style: const TextStyle(
                                  fontSize: AppTheme.fsBodySm,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              Container(
                                width: 8, 
                                height: 8, 
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary, 
                                  shape: BoxShape.circle
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                              onPressed: () => _showDeleteConfirmation(context, notif['id']),
                            ),
                          ],
                        ),
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
