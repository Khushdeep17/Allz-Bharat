import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../products/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? shopName;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.shopName,
  });

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '₹${price.toInt()}';
    }
    return '₹${price.toStringAsFixed(2)}';
  }

  Widget _buildProductImage() {
    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.borderMd,
        child: Image.network(
          product.imageUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
        ),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textMuted,
        size: AppComponentSizes.iconLg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border, width: 1),
        borderRadius: AppRadius.borderMd,
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product Image or Placeholder
            _buildProductImage(),
            const SizedBox(width: AppSpacing.md),

            // Product Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (shopName != null && shopName!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shopName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      product.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatPrice(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs / 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.inStock
                              ? AppColors.primaryContainer
                              : AppColors.errorContainer,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          product.inStock ? 'In Stock' : 'Out of Stock',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: product.inStock
                                ? AppColors.primary
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
