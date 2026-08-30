import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/country_code_prefix.dart';

/// Screen for entering 10-digit Indian phone number to request OTP.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _validationError = 'Please enter your mobile number');
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _validationError = 'Enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _validationError = null);
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Listen to auth state transitions
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.codeSent &&
          previous?.status != AuthStatus.codeSent) {
        context.push(AppRoutes.otp);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // App Icon / Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Headline
                Text(
                  'Welcome to\n${AppConstants.appName}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your mobile number to get started with your neighborhood kirana orders.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Phone Input Field
                Text(
                  'Mobile Number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (value) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    counterText: '',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: CountryCodePrefix(),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    errorText: _validationError,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: const BorderSide(
                        color: AppColors.borderFocused,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Button
                AuthPrimaryButton(
                  label: 'Get OTP',
                  isLoading: authState.isLoading,
                  onPressed: _onSendOtp,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Terms disclaimer
                Center(
                  child: Text(
                    'By continuing, you agree to Allz Bharat Terms & Privacy Policy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
