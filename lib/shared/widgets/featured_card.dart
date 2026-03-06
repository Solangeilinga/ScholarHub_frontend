import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/scholarships/models/scholarship_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/display_formatters.dart';

class FeaturedCard extends StatelessWidget {
  final Scholarship scholarship;
  const FeaturedCard({super.key, required this.scholarship});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scholarships/${scholarship.id}'),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scholarship.typeLabel,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: AppTheme.gold, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Provider avec logo (CORRIGÉ - identique à ScholarshipCard)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: scholarship.providerLogo != null
                        ? DecorationImage(
                            image: NetworkImage(scholarship.providerLogo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: scholarship.providerLogo == null
                      ? const Icon(Icons.school_rounded,
                          color: AppTheme.primary, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scholarship.provider,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              scholarship.title,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),
            const Divider(color: AppTheme.border, height: 24),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deadline',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                    Text(
                      formatDateFr(scholarship.deadline),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (scholarship.amount != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scholarship.amountFormatted,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
