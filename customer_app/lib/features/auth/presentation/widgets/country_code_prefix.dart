import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Clean prefix widget showing Indian flag and +91 country code.
class CountryCodePrefix extends StatelessWidget {
  const CountryCodePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🇮🇳',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            '+91',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
