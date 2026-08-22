import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const AllzBharatCustomerApp());
}

class AllzBharatCustomerApp extends StatelessWidget {
  const AllzBharatCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
