import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routing/app_routes.dart';
import '../../addresses/data/address_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../cart/presentation/widgets/cart_badge.dart';
import '../../categories/data/category_repository.dart';
import '../../products/data/product_repository.dart';
import '../../shops/data/shop_repository.dart';
import '../../shops/models/shop.dart';
import '../../shops/presentation/widgets/product_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_shop_card.dart';
import 'widgets/location_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/section_header.dart';
import 'widgets/shop_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProfileBottomSheet() {
    final userProfile = ref.read(currentUserProfileProvider).valueOrNull;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (userProfile?.displayName?.isNotEmpty == true)
                        ? userProfile!.displayName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile?.displayName ?? 'Allz Bharat User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (userProfile?.phoneNumber != null)
                        Text(
                          userProfile!.phoneNumber!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'My Orders',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('View and track your orders'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.orders);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'My Addresses',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Manage saved delivery addresses'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.addresses);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showSignOutDialog();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out from Allz Bharat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final shopsAsync = ref.watch(shopsStreamProvider);
    final allProducts = ref.watch(allActiveProductsProvider);
    final defaultAddress = ref.watch(defaultAddressProvider);

    final addressDisplay = defaultAddress != null
        ? '${defaultAddress.label} • ${defaultAddress.fullAddress}'
        : 'Shastri Nagar, Meerut, UP';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Location Header & Cart Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: LocationHeader(
                        address: addressDisplay,
                        onChangePressed: () =>
                            context.push(AppRoutes.addresses),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const CartBadge(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search shops, groceries...',
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // If Search Query is NOT empty: Show Search Results
              if (_searchQuery.isNotEmpty)
                shopsAsync.when(
                  loading: () => const SizedBox(
                    height: 155,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Unable to load search results.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  data: (shops) {
                    final filteredShops = shops
                        .where((s) => s.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                    final filteredProducts = allProducts
                        .where((p) => p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                    if (filteredShops.isEmpty && filteredProducts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                color: AppColors.textMuted,
                                size: 48,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                "No results found for '$_searchQuery'",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Matching Shops Section (if any)
                        if (filteredShops.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Shops',
                            actionLabel: '${filteredShops.length} found',
                            onActionPressed: () {},
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 165,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: filteredShops.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final shop = filteredShops[index];
                                return ShopCard(
                                  shop: shop,
                                  onTap: () => context
                                      .push(AppRoutes.shopDetails(shop.id)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Matching Products Section (if any)
                        if (filteredProducts.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Products',
                            actionLabel: '${filteredProducts.length} found',
                            onActionPressed: () {},
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredProducts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final shop = shops.cast<Shop?>().firstWhere(
                                      (s) => s?.id == product.shopId,
                                      orElse: () => null,
                                    );
                                return ProductCard(
                                  product: product,
                                  shopName: shop?.name,
                                  onTap: () => context.push(
                                    AppRoutes.productDetails(
                                      shopId: product.shopId,
                                      productId: product.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                )
              else ...[
                // 3. Normal Categories Section
                SectionHeader(title: 'Categories', onActionPressed: () {}),
                const SizedBox(height: AppSpacing.sm),
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'No categories available',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return CategoryChip(category: category);
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 96,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Unable to load categories right now.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 4 & 5. Normal Shops Sections (Featured and Nearby)
                shopsAsync.when(
                  data: (shops) {
                    if (shops.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'No shops available in your area',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured Express Stores Section
                        SectionHeader(
                          title: 'Featured Express Stores',
                          actionLabel: 'Explore',
                          onActionPressed: () {},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 155,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: shops.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final shop = shops[index];
                              return FeaturedShopCard(
                                shop: shop,
                                onTap: () => context
                                    .push(AppRoutes.shopDetails(shop.id)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Nearby Kirana Shops Section
                        SectionHeader(
                          title: 'Nearby Kirana Shops',
                          onActionPressed: () {},
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 165,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: shops.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final shop = shops[index];
                              return ShopCard(
                                shop: shop,
                                onTap: () => context
                                    .push(AppRoutes.shopDetails(shop.id)),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 155,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Unable to load shops right now.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 2) {
            context.push(AppRoutes.orders);
            return;
          }
          if (index == 3) {
            _showProfileBottomSheet();
            return;
          }
          setState(() {
            _currentNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
