import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_primary_button.dart';

/// Screen for entering 6-digit OTP received via SMS.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  Timer? _timer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() {
          _resendCountdown = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _onVerifyOtp([String? code]) {
    final pin = code ?? _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).verifyOtp(pin);
  }

  void _onResendOtp() {
    if (!_canResend) return;
    _pinController.clear();
    ref.read(authControllerProvider.notifier).resendOtp();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final phone = authState.phoneNumber ?? '';

    // Listen to error states
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

    // Pinput theme definitions
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.borderFocused, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primaryContainer.withAlpha(80),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'Verify Phone Number',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle with Phone Number and Change Button
              Row(
                children: [
                  Text(
                    'Code sent to ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Edit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Pinput 6-digit Code
              Center(
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  errorPinTheme: errorPinTheme,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onCompleted: _onVerifyOtp,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Verify Action Button
              AuthPrimaryButton(
                label: 'Verify & Continue',
                isLoading: authState.isLoading,
                onPressed: () => _onVerifyOtp(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Resend Timer Row
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _onResendOtp,
                        child: const Text(
                          'Resend OTP via SMS',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Resend code in ${_resendCountdown}s',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
