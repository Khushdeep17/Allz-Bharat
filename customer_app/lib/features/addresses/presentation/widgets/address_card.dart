import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../models/address.dart';

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase().trim()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'office':
        return Icons.business_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label icon + Label text + Default Badge + Menu/Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.primaryContainer
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getLabelIcon(address.label),
                  color: address.isDefault
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: AppComponentSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                address.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    'DEFAULT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Edit Address',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.error,
                tooltip: 'Delete Address',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Full Address Text
          Text(
            address.fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Phone Number
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Contact: ${address.phoneNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Set as default button (if not default)
          if (!address.isDefault) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onSetDefault,
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Set as Default',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
