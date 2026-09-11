import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../categories/models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.onTap});

  Widget _buildIcon() {
    final iconStr = category.icon.trim();
    if (iconStr.isNotEmpty) {
      return Text(
        iconStr,
        style: const TextStyle(fontSize: 24),
        textAlign: TextAlign.center,
      );
    }
    return const Icon(
      Icons.category_rounded,
      color: AppColors.primary,
      size: AppComponentSizes.iconMd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: _buildIcon(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 64,
            child: Text(
              category.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11.0,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
