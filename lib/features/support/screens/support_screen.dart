import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  List<dynamic> _myTickets = [];
  bool _loadingTickets = true;
  final Set<String> _deletingIds =
      {}; // Pour gérer les animations de suppression

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      final res = await context.read<ApiClient>().dio.get('/support/my');
      setState(() {
        _myTickets = res.data['tickets'] ?? [];
        _loadingTickets = false;
      });
    } catch (_) {
      setState(() => _loadingTickets = false);
    }
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<ApiClient>().dio.post('/support', data: {
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });
      _subjectCtrl.clear();
      _messageCtrl.clear();
      await _loadTickets();
      _tabController.animateTo(1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('✅ Demande envoyée ! Nous vous répondrons bientôt.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de l\'envoi'),
              backgroundColor: AppTheme.accent),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  // NOUVELLE FONCTION : Supprimer une demande
  Future<void> _deleteTicket(String ticketId, int index) async {
    // Confirmation avant suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la demande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Marquer comme en cours de suppression (pour animation)
    setState(() {
      _deletingIds.add(ticketId);
    });

    try {
      // Appel API pour supprimer
      await context.read<ApiClient>().dio.delete('/support/$ticketId');

      // Attendre l'animation
      await Future.delayed(const Duration(milliseconds: 300));

      // Supprimer de la liste locale
      if (mounted) {
        setState(() {
          _myTickets.removeAt(index);
          _deletingIds.remove(ticketId);
        });

        // Message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Demande supprimée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur, annuler le marquage
      if (mounted) {
        setState(() {
          _deletingIds.remove(ticketId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la suppression'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Assistance candidature',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Nouvelle demande'),
            Tab(text: 'Mes demandes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Formulaire
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent_rounded,
                          color: AppTheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Besoin d\'aide ?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                                'Notre équipe vous aide à préparer et soumettre vos candidatures.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Sujet',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Ex: Aide pour bourse Eiffel Excellence'),
                ),
                const SizedBox(height: 16),
                Text('Message',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'Décrivez votre situation, votre profil, et comment on peut vous aider...',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Envoi...' : 'Envoyer la demande'),
                  ),
                ),
              ],
            ),
          ),

          // Mes tickets avec option de suppression
          _loadingTickets
              ? const Center(child: CircularProgressIndicator())
              : _myTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_rounded,
                              size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          const Text('Aucune demande pour le moment',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _tabController.animateTo(0),
                            child: const Text('Créer une demande'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myTickets.length,
                        itemBuilder: (_, i) {
                          final t = _myTickets[i];
                          final ticketId = t['id'].toString();
                          final status = t['status'] as String;
                          final isDeleting = _deletingIds.contains(ticketId);
                          final createdAt = t['createdAt'] != null
                              ? DateFormat('dd MMM yyyy', 'fr_FR')
                                  .format(DateTime.parse(t['createdAt']))
                              : null;

                          // Animation de disparition
                          if (isDeleting) {
                            return const SizedBox.shrink();
                          }

                          return Dismissible(
                            key: Key(ticketId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Confirmation'),
                                  content: const Text(
                                      'Voulez-vous vraiment supprimer cette demande ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                            onDismissed: (_) => _deleteTicket(ticketId, i),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppTheme.border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t['subject'],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                            if (createdAt != null) ...[
                                              const SizedBox(height: 2),
                                              Text(createdAt,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textSecondary)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'OPEN'
                                              ? Colors.amber
                                                  .withValues(alpha: 0.1)
                                              : status == 'ANSWERED'
                                                  ? Colors.green
                                                      .withValues(alpha: 0.1)
                                                  : AppTheme.border,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status == 'OPEN'
                                              ? '⏳ En attente'
                                              : status == 'ANSWERED'
                                                  ? '✅ Répondu'
                                                  : '🔒 Fermé',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: status == 'OPEN'
                                                    ? Colors.amber[700]
                                                    : status == 'ANSWERED'
                                                        ? Colors.green[700]
                                                        : AppTheme
                                                            .textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(t['message'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: AppTheme.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  if (t['reply'] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.green
                                                .withValues(alpha: 0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Réponse de l\'équipe :',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green)),
                                          const SizedBox(height: 4),
                                          Text(t['reply'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                      color:
                                                          AppTheme.textPrimary,
                                                      height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
