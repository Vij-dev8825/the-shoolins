import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/shine_effect.dart';
import 'complete_profile_screen.dart';
import 'main_shell.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String? devOtp;

  const OtpScreen({super.key, required this.mobile, this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _devOtp;
  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthService>();
      final isNewUser = await auth.verifyOtp(widget.mobile, _otpController.text.trim());
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isNewUser ? const CompleteProfileScreen() : const MainShell(),
        ),
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

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final devOtp = await context.read<AuthService>().requestOtp(widget.mobile);
      if (!mounted) return;
      setState(() => _devOtp = devOtp);
      _startCooldown();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('otpTitle'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '${strings.t('otpSubtitle')} +91 ${widget.mobile}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted,
                  ),
                  if (_devOtp != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        'Dev OTP: $_devOtp',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(color: AppColors.secondaryDark),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(counterText: ''),
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ShineEffect(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _verify,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                            )
                          : Text(strings.t('otpVerify')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: (_resendCooldown == 0 && !_isResending) ? _resend : null,
                    child: Text(
                      _resendCooldown == 0
                          ? strings.t('otpResend')
                          : '${strings.t('otpResend')} (${_resendCooldown}s)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
