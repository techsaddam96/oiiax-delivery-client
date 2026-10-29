import 'package:flutter/material.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';

class LanguageSelector extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    super.key,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppLocalizations.isArabic ? Icons.language : Icons.translate,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.isArabic ? 'العربية' : 'English',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
      onSelected: (String languageCode) async {
        final locale = languageCode == 'ar'
            ? AppLocalizations.arabic
            : AppLocalizations.english;

        await AppLocalizations.changeLanguage(locale);

        if (onLanguageChanged != null) {
          onLanguageChanged!();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('🇺🇸'),
              const SizedBox(width: 8),
              Text(AppTranslations.getTextWithLocale('language', 'en')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'ar',
          child: Row(
            children: [
              const Text('🇸🇦'),
              const SizedBox(width: 8),
              Text(AppTranslations.getTextWithLocale('language', 'ar')),
            ],
          ),
        ),
      ],
    );
  }
}

// Compact language selector for smaller spaces
class CompactLanguageSelector extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const CompactLanguageSelector({
    super.key,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        AppLocalizations.isArabic ? Icons.language : Icons.translate,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        _showLanguageDialog(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppTranslations.getText('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title:
                    Text(AppTranslations.getTextWithLocale('language', 'en')),
                onTap: () async {
                  await AppLocalizations.changeLanguage(
                      AppLocalizations.english);
                  Navigator.of(context).pop();
                  if (onLanguageChanged != null) {
                    onLanguageChanged!();
                  }
                },
              ),
              ListTile(
                leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                title:
                    Text(AppTranslations.getTextWithLocale('language', 'ar')),
                onTap: () async {
                  await AppLocalizations.changeLanguage(
                      AppLocalizations.arabic);
                  Navigator.of(context).pop();
                  if (onLanguageChanged != null) {
                    onLanguageChanged!();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
