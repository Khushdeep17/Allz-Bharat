import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routing/app_routes.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Discover Nearby Kirana Shops',
      description: 'Connect with trusted neighborhood stores in your area for fast and reliable daily supplies.',
      icon: Icons.storefront_rounded,
    ),
    OnboardingPageData(
      title: 'Order Everyday Essentials',
      description: 'Browse fresh groceries, flours, dairy, and household items from stores you already know.',
      icon: Icons.shopping_basket_rounded,
    ),
    OnboardingPageData(
      title: 'Local Convenience, Digital Ease',
      description: 'Enjoy neighborhood shop trust with seamless mobile ordering and doorstep delivery.',
      icon: Icons.local_shipping_rounded,
    ),
  ];

  void _finishOnboarding() {
    context.go(AppRoutes.login);
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentIndex == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _finishOnboarding, child: const Text('Skip')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 72,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots & Bottom Action
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: AppRadius.borderFull,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(isLastPage ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
