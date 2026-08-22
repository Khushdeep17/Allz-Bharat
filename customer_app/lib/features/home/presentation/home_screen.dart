import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/mock_home_data.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_shop_card.dart';
import 'widgets/location_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/section_header.dart';
import 'widgets/shop_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                child: LocationHeader(address: MockHomeData.currentLocation),
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
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: MockHomeData.categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final category = MockHomeData.categories[index];
                    return CategoryChip(category: category);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Featured Express Stores Section
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
                  itemCount: MockHomeData.featuredShops.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final shop = MockHomeData.featuredShops[index];
                    return FeaturedShopCard(shop: shop);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Nearby Kirana Shops Section
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
                  itemCount: MockHomeData.nearbyShops.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final shop = MockHomeData.nearbyShops[index];
                    return ShopCard(shop: shop);
                  },
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
