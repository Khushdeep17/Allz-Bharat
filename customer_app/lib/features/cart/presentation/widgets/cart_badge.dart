import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/cart_controller.dart';

class CartBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const CartBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref.watch(cartTotalItemsProvider);

    return InkWell(
      onTap: onTap ?? () => context.push(AppRoutes.cart),
      borderRadius: AppRadius.borderFull,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.textPrimary,
              size: AppComponentSizes.iconMd,
            ),
            if (totalItems > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: AppRadius.borderFull,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    totalItems > 99 ? '99+' : totalItems.toString(),
                    style: const TextStyle(
                      color: AppColors.onSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
