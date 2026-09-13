import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../models/shop.dart';

class ShopHeader extends StatelessWidget {
  final Shop shop;

  const ShopHeader({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: AppComponentSizes.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shop.address.isNotEmpty
                                ? shop.address
                                : 'Local Kirana Store',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs / 2,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating > 0
                          ? shop.rating.toStringAsFixed(1)
                          : '4.5',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Open / Closed Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: shop.isOpen
                      ? AppColors.primaryContainer
                      : AppColors.surfaceVariant,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      shop.isOpen
                          ? Icons.check_circle_outline_rounded
                          : Icons.access_time_rounded,
                      size: 14,
                      color: shop.isOpen
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.isOpen ? 'Open Now' : 'Closed',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: shop.isOpen
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
