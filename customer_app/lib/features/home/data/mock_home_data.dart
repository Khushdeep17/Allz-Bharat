import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/shop.dart';

/// Centralized mock data repository for Allz Bharat Home & Shop Discovery.
class MockHomeData {
  MockHomeData._();

  static const String currentLocation = 'Shastri Nagar, Meerut, UP';

  static const List<Category> categories = [
    Category(
      id: 'cat_atta_rice',
      name: 'Atta & Rice',
      icon: Icons.grain_rounded,
    ),
    Category(id: 'cat_dairy', name: 'Dairy', icon: Icons.local_drink_rounded),
    Category(id: 'cat_snacks', name: 'Snacks', icon: Icons.cookie_rounded),
    Category(
      id: 'cat_beverages',
      name: 'Beverages',
      icon: Icons.local_cafe_rounded,
    ),
    Category(
      id: 'cat_personal',
      name: 'Personal Care',
      icon: Icons.clean_hands_rounded,
    ),
    Category(
      id: 'cat_household',
      name: 'Household',
      icon: Icons.home_repair_service_rounded,
    ),
    Category(id: 'cat_oils', name: 'Oils & Ghee', icon: Icons.opacity_rounded),
    Category(id: 'cat_spices', name: 'Spices', icon: Icons.restaurant_rounded),
  ];

  static const List<Shop> nearbyShops = [
    Shop(
      id: 'shop_sharma',
      name: 'Sharma General Store',
      rating: 4.8,
      distance: '0.4 km',
      deliveryTime: '15-20 mins',
      isOpen: true,
      tag: 'Trusted Kirana',
      badgeText: 'Verified Store',
      locality: 'Shastri Nagar, Meerut',
    ),
    Shop(
      id: 'shop_gupta',
      name: 'Gupta Kirana',
      rating: 4.6,
      distance: '0.8 km',
      deliveryTime: '20-25 mins',
      isOpen: true,
      tag: 'Fast Delivery',
      badgeText: 'Top Rated',
      locality: 'Central Market, Meerut',
    ),
    Shop(
      id: 'shop_verma',
      name: 'Verma Daily Needs',
      rating: 4.5,
      distance: '1.2 km',
      deliveryTime: '10-15 mins',
      isOpen: true,
      tag: 'Local Favorite',
      badgeText: 'Quick Pickups',
      locality: 'Saket Colony, Meerut',
    ),
    Shop(
      id: 'shop_jain',
      name: 'Jain Super Store',
      rating: 4.9,
      distance: '1.5 km',
      deliveryTime: '25-30 mins',
      isOpen: false,
      tag: 'Popular',
      badgeText: 'Wide Range',
      locality: 'Begum Bridge, Meerut',
    ),
  ];

  static const List<Shop> featuredShops = [
    Shop(
      id: 'shop_aggarwal',
      name: 'Aggarwal Super Mart',
      rating: 4.9,
      distance: '1.0 km',
      deliveryTime: '15 mins',
      isOpen: true,
      tag: 'Express Delivery',
      badgeText: 'Up to 20% OFF Essentials',
      locality: 'Central Market, Meerut',
    ),
    Shop(
      id: 'shop_balaji',
      name: 'Bala Ji Organic & Dairy',
      rating: 4.7,
      distance: '1.4 km',
      deliveryTime: '20 mins',
      isOpen: true,
      tag: 'Farm Fresh',
      badgeText: 'Fresh Daily Milk & Paneer',
      locality: 'Shastri Nagar, Meerut',
    ),
  ];
}
