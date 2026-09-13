import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../products/data/product_repository.dart';
import '../../data/shop_repository.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_header.dart';

class ShopDetailsScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailsScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopAsync = ref.watch(shopByIdProvider(shopId));
    final productsAsync = ref.watch(productsByShopProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColors.border),
        ),
      ),
      body: shopAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to load shop details right now.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.store_mall_directory_outlined,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Shop not found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'The requested shop could not be found or is no longer active.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Shop Header Card
                ShopHeader(shop: shop),
                const SizedBox(height: AppSpacing.lg),

                // 2. Products Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    productsAsync.maybeWhen(
                      data: (products) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs / 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          '${products.length} items',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Products List
                productsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'Unable to load products right now.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderMd,
                          border:
                              Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No products listed in this shop yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(product: product);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }
}
