import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../categories/data/category_repository.dart';
import '../../shops/data/shop_repository.dart';
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Location Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: LocationHeader(address: 'Shastri Nagar, Meerut, UP'),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Search Bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SearchBarWidget(
                  hintText: 'Search groceries, essentials...',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Categories Section
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

              // 4 & 5. Shops Sections (Featured and Nearby)
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
                              onTap: () =>
                                  context.push(AppRoutes.shopDetails(shop.id)),
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
                              onTap: () =>
                                  context.push(AppRoutes.shopDetails(shop.id)),
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
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 3) {
            _showSignOutDialog();
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
