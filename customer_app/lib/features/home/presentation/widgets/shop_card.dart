import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../shops/models/shop.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;

  const ShopCard({super.key, required this.shop, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Card(
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: AppComponentSizes.iconMd,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: AppSpacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: shop.isOpen
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      shop.isOpen ? 'Open Now' : 'Closed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: shop.isOpen
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Shop Name
              Text(
                shop.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Locality Address
              Text(
                shop.address.isNotEmpty
                    ? shop.address
                    : 'Shastri Nagar, Meerut',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Rating & Status Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
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
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          shop.rating > 0
                              ? shop.rating.toStringAsFixed(1)
                              : '4.5',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      shop.isOpen ? '• Open' : '• Closed',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '15m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
