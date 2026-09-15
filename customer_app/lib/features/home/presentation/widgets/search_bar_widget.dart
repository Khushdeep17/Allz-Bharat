import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final bool showFilterIcon;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search groceries, essentials...',
    this.onChanged,
    this.onTap,
    this.controller,
    this.onClear,
    this.showFilterIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller != null && controller!.text.isNotEmpty;

    return TextField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  controller?.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
              )
            : (showFilterIcon
                ? Container(
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: AppComponentSizes.iconSm,
                    ),
                  )
                : null),
      ),
    );
  }
}
