import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/widgets/cart_badge.dart';
import '../../../shops/data/shop_repository.dart';
import '../../data/product_repository.dart';
import '../../models/product.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.shopId,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '₹${price.toInt()}';
    }
    return '₹${price.toStringAsFixed(2)}';
  }

  void _setQuantity(Product product, int desiredQuantity) {
    final result =
        ref.read(cartProvider.notifier).setQuantity(product, desiredQuantity);

    if (result == AddToCartResult.shopConflict) {
      _showShopConflictDialog(product, desiredQuantity);
    }
  }

  void _showShopConflictDialog(Product product, int desiredQuantity) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace Cart Items?'),
        content: const Text(
          'Your cart already contains items from another store. Do you want to clear your cart and add items from this store instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref
                  .read(cartProvider.notifier)
                  .confirmClearAndAdd(product, desiredQuantity);
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart replaced and item added!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Image.network(
          imageUrl,
          height: 240,
          width: double.infinity,
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
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.textMuted,
          size: 64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final shopAsync = ref.watch(shopByIdProvider(widget.shopId));
    final cartState = ref.watch(cartProvider);

    final cartItemIndex = cartState.items
        .indexWhere((item) => item.productId == widget.productId);
    final cartQuantity =
        cartItemIndex >= 0 ? cartState.items[cartItemIndex].quantity : 0;
    final isInCart = cartQuantity > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/shop/${widget.shopId}');
            }
          },
        ),
        actions: const [
          CartBadge(),
          SizedBox(width: AppSpacing.sm),
        ],
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColors.border),
        ),
      ),
      body: productAsync.when(
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
                  'Unable to load product details.',
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
                      context.go('/shop/${widget.shopId}');
                    }
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Product not found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'This product is no longer available.',
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
                          context.go('/shop/${widget.shopId}');
                        }
                      },
                      child: const Text('Back to Shop'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isInStock = product.inStock;
          final displayedQuantity = isInCart ? cartQuantity : 1;
          final totalPrice = product.price * displayedQuantity;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      _buildProductImage(product.imageUrl),
                      const SizedBox(height: AppSpacing.md),

                      // Store tag / information
                      shopAsync.maybeWhen(
                        data: (shop) => shop != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs / 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.storefront_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      shop.name,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Product Title
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Price and Stock status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatPrice(product.price),
                            style: theme.textTheme.headlineSmall?.copyWith(
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
                              color: isInStock
                                  ? AppColors.primaryContainer
                                  : AppColors.errorContainer,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              isInStock ? 'In Stock' : 'Out of Stock',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isInStock
                                    ? AppColors.primary
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: AppSpacing.md),

                      // Description Section
                      Text(
                        'Description',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (product.description != null &&
                                product.description!.isNotEmpty)
                            ? product.description!
                            : 'Authentic quality product from local kirana store.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Quantity Section (enabled only when in stock)
                      if (isInStock) ...[
                        Text(
                          'Quantity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded),
                                    onPressed: isInCart
                                        ? () => _setQuantity(
                                              product,
                                              cartQuantity - 1,
                                            )
                                        : null,
                                    color: AppColors.textPrimary,
                                    disabledColor: AppColors.textMuted,
                                    iconSize: 20,
                                  ),
                                  Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 40),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$displayedQuantity',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded),
                                    onPressed: isInCart
                                        ? () => _setQuantity(
                                              product,
                                              cartQuantity + 1,
                                            )
                                        : () => _setQuantity(product, 2),
                                    color: AppColors.textPrimary,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: AppComponentSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed: isInStock
                          ? (isInCart
                              ? () => context.push(AppRoutes.cart)
                              : () => _setQuantity(product, 1))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor: AppColors.surfaceVariant,
                        disabledForegroundColor: AppColors.textMuted,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderMd,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isInStock
                            ? (isInCart
                                ? 'View Cart • ${_formatPrice(totalPrice)}'
                                : 'Add to Cart • ${_formatPrice(product.price)}')
                            : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
