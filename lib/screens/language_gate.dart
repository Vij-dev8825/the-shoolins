import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_service.dart';
import 'language_select_screen.dart';
import 'startup_gate.dart';

class LanguageGate extends StatelessWidget {
  const LanguageGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleService>(
      builder: (context, locale, _) {
        if (locale.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return locale.hasChosenLanguage ? const StartupGate() : const LanguageSelectScreen();
      },
    );
  }
}
