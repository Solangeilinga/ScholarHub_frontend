import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/scholarships/models/scholarship_model.dart';
import '../../features/scholarships/bloc/scholarship_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display_formatters.dart';

class ScholarshipCard extends StatelessWidget {
  final Scholarship scholarship;
  const ScholarshipCard({super.key, required this.scholarship});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date flexible';
    return formatDateFr(date);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/scholarships/${scholarship.id}', extra: scholarship),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec logo
            Row(
              children: [
                // Logo du fournisseur
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: scholarship.providerLogo != null
                        ? DecorationImage(
                            image: NetworkImage(scholarship.providerLogo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: scholarship.providerLogo == null
                      ? const Icon(Icons.school_rounded,
                          color: AppTheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scholarship.provider,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                      Text(
                        scholarship.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _BookmarkButton(scholarship: scholarship),
              ],
            ),

            const SizedBox(height: 12),

            // Niveaux d'études (tableau)
            if (scholarship.level.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: scholarship.level
                    .map((level) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formatLevelLabel(level),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.secondary),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Footer avec type, deadline, durée et montant
            Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scholarship.typeLabel,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),

                // Deadline
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: scholarship.isExpiringSoon
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _formatDate(scholarship.deadline),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: scholarship.isExpiringSoon
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontWeight: scholarship.isExpiringSoon
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ),

                const Spacer(),

                // Durée (si disponible)
                if (scholarship.duration != null) ...[
                  Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    scholarship.duration!,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Montant
                if (scholarship.amount != null)
                  Text(
                    scholarship.amountFormatted,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                  ),
              ],
            ),

            // Badge expire bientôt
            if (scholarship.isExpiringSoon) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⏰ Expire dans ${scholarship.daysLeft} jour(s) !',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppTheme.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            // Date de début (si disponible)
            if (scholarship.startDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Début: ${_formatDate(scholarship.startDate)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  final Scholarship scholarship;
  const _BookmarkButton({required this.scholarship});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late bool _isSaved;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.scholarship.isSaved;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scholarship.isSaved != widget.scholarship.isSaved) {
      _isSaved = widget.scholarship.isSaved;
    }
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isSaved = !_isSaved);
    _controller.forward(from: 0);
    context.read<ScholarshipBloc>().add(
          ToggleSaveEvent(id: widget.scholarship.id, isSaved: !_isSaved),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScholarshipBloc, ScholarshipState>(
      listenWhen: (_, curr) =>
          curr is ScholarshipSavedToggledState &&
          curr.scholarshipId == widget.scholarship.id,
      listener: (context, state) {
        if (state is ScholarshipSavedToggledState) {
          setState(() => _isSaved = state.isSaved);
        }
      },
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSaved
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                key: ValueKey(_isSaved),
                color: _isSaved ? AppTheme.primary : AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
