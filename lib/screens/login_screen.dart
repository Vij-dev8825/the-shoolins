import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/shine_effect.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final mobile = _mobileController.text.trim();
      final devOtp = await context.read<AuthService>().requestOtp(mobile);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpScreen(mobile: mobile, devOtp: devOtp)),
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
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'THE SHOOLINS',
                      textAlign: TextAlign.center,
                      style: AppTypography.wordmark.copyWith(color: AppColors.accentDark),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      strings.t('loginTitle'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyMuted.copyWith(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: strings.t('loginMobileLabel'),
                        counterText: '',
                        prefixText: '+91  ',
                      ),
                      validator: (value) {
                        final digits = value?.trim() ?? '';
                        if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
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
