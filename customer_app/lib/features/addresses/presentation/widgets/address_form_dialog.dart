import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/address_repository.dart';
import '../../models/address.dart';

class AddressFormBottomSheet extends ConsumerStatefulWidget {
  final Address? existingAddress;

  const AddressFormBottomSheet({
    super.key,
    this.existingAddress,
  });

  static Future<void> show(BuildContext context, {Address? existingAddress}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormBottomSheet(
        existingAddress: existingAddress,
      ),
    );
  }

  @override
  ConsumerState<AddressFormBottomSheet> createState() =>
      _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState
    extends ConsumerState<AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedLabel;
  late final TextEditingController _customLabelController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late bool _isDefault;

  bool _isLoading = false;

  final List<String> _labelOptions = const ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final address = widget.existingAddress;

    if (address != null) {
      if (_labelOptions.contains(address.label)) {
        _selectedLabel = address.label;
        _customLabelController = TextEditingController();
      } else {
        _selectedLabel = 'Other';
        _customLabelController = TextEditingController(text: address.label);
      }
      _addressController = TextEditingController(text: address.fullAddress);
      _phoneController = TextEditingController(text: address.phoneNumber);
      _isDefault = address.isDefault;
    } else {
      _selectedLabel = 'Home';
      _customLabelController = TextEditingController();
      _addressController = TextEditingController();
      _phoneController = TextEditingController();
      _isDefault = false;
    }
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authStateChangesProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to manage your addresses.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final finalLabel = _selectedLabel == 'Other' &&
            _customLabelController.text.trim().isNotEmpty
        ? _customLabelController.text.trim()
        : _selectedLabel;

    setState(() {
      _isLoading = true;
    });

    try {
      final addressRepo = ref.read(addressRepositoryProvider);

      if (widget.existingAddress != null) {
        // Edit Mode
        final updatedAddress = widget.existingAddress!.copyWith(
          label: finalLabel,
          fullAddress: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          isDefault: _isDefault,
        );

        await addressRepo.updateAddress(
          user.uid,
          widget.existingAddress!.addressId,
          updatedAddress,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated successfully!'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add Mode
        final newAddress = Address(
          addressId: '',
          label: finalLabel,
          fullAddress: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          isDefault: _isDefault,
        );

        await addressRepo.addAddress(user.uid, newAddress);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully!'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save address. Please check your connection and try again.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingAddress != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppColors.surface,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Address' : 'Add New Address',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 1. Label Selection
              Text(
                'Address Label',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: _labelOptions.map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedLabel = label;
                          });
                        }
                      },
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'Other') ...[
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _customLabelController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Grandma\'s Home, Studio',
                    labelText: 'Custom Label Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedLabel == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please specify a label name';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 2. Full Address
              Text(
                'Complete Address',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _addressController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'House/Flat No., Street, Landmark, City, Pincode',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your complete delivery address';
                  }
                  if (value.trim().length < 5) {
                    return 'Please enter a detailed address (at least 5 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Contact Phone Number
              Text(
                'Delivery Contact Number',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixText: '+91 ',
                  hintText: '10-digit mobile number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a contact phone number';
                  }
                  final cleanPhone = value.replaceAll(RegExp(r'\s+|-'), '');
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
                    return 'Please enter a valid 10-digit Indian mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // 4. Default Address Toggle
              SwitchListTile.adaptive(
                title: const Text(
                  'Set as default delivery address',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                value: _isDefault,
                activeTrackColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Submit Button
              SizedBox(
                width: double.infinity,
                height: AppComponentSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMd,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
