import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/address_fields.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/shine_effect.dart';
import 'main_shell.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _city = '';
  String _state = '';
  String _pincode = '';
  String? _photoBase64;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthService>().updateProfile(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            city: _city,
            state: _state,
            pincode: _pincode,
            photoBase64: _photoBase64,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      strings.t('registerNameTitle'),
                      textAlign: TextAlign.center,
                      style: AppTypography.headline,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: ProfilePhotoPicker(
                        photoBase64: _photoBase64,
                        fallbackInitial: '?',
                        onChanged: (base64) => setState(() => _photoBase64 = base64),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMuted.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: strings.t('registerNameHint')),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: strings.t('address')),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AddressFields(
                      onChanged: (city, state, pincode) {
                        _city = city;
                        _state = state;
                        _pincode = pincode;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ShineEffect(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              )
                            : Text(strings.t('continueLabel')),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
