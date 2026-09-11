import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_primary_button.dart';

/// Screen for collecting user's name on first-time login.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSaveProfile() {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _validationError = 'Please enter your full name');
      return;
    }

    if (name.length < 2) {
      setState(() => _validationError = 'Name must be at least 2 characters');
      return;
    }

    setState(() => _validationError = null);
    ref.read(authControllerProvider.notifier).saveUserProfile(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Listen to errors
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
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
        automaticallyImplyLeading: false,
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

                // Icon / Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Headline
                Text(
                  'What should we\ncall you?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your full name so your neighborhood kirana stores know who placed the order.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Name Input Field
                Text(
                  'Full Name',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  onChanged: (value) {
                    if (_validationError != null) {
                      setState(() => _validationError = null);
                    }
                  },
                  onFieldSubmitted: (_) => _onSaveProfile(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    errorText: _validationError,
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
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
                  label: 'Continue',
                  isLoading: authState.isLoading,
                  onPressed: _onSaveProfile,
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
