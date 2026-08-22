import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../models/shop.dart';

class FeaturedShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;

  const FeaturedShopCard({super.key, required this.shop, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderLg,
      child: Card(
        color: AppColors.secondaryContainer,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.secondary, width: 1),
          borderRadius: AppRadius.borderLg,
        ),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Highlight Tag & Express Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs / 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        shop.tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        shop.rating.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Shop Title
              Text(
                shop.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSecondaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Badge Offer / Description
              Text(
                shop.badgeText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Bottom Row with locality & ETA
              Row(
                children: [
                  const Icon(
                    Icons.flash_on_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${shop.deliveryTime} • ${shop.distance}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.secondary,
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
