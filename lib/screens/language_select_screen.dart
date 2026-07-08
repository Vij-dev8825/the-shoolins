import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/shine_effect.dart';
import 'startup_gate.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  AppLanguage _selected = AppLanguage.en;

  Future<void> _continue() async {
    await context.read<LocaleService>().setLanguage(_selected);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StartupGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_selected);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'THE SHOOLINS',
                    textAlign: TextAlign.center,
                    style: AppTypography.wordmark.copyWith(color: AppColors.accentDark),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    strings.t('languageSelectTitle'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final language in AppLanguage.values) ...[
                    _LanguageTile(
                      language: language,
                      selected: _selected == language,
                      onTap: () => setState(() => _selected = language),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ShineEffect(
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: Text(strings.t('continueLabel')),
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

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSurface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: selected ? AppColors.accent : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language.nativeName,
                style: AppTypography.title.copyWith(
                  color: selected ? AppColors.accentDark : AppColors.ink,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
