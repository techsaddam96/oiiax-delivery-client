import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:blockatie/constants/fonts.dart';

/*
 * App Localizations with Language Change Notifier
 * 
 * This file provides localization support with automatic UI updates when language changes.
 * 
 * To make your widgets automatically rebuild when language changes:
 * 
 * 1. Wrap your widget with ChangeNotifierProvider:
 *    ChangeNotifierProvider.value(
 *      value: AppLocalizations.languageNotifier,
 *      child: YourWidget(),
 *    )
 * 
 * 2. Use Consumer to listen for changes:
 *    Consumer<LanguageChangeNotifier>(
 *      builder: (context, notifier, child) {
 *        return Text(AppTranslations.getText('hello'));
 *      },
 *    )
 * 
 * 3. Or use Provider.of to access the notifier:
 *    Provider.of<LanguageChangeNotifier>(context, listen: true)
 * 
 * 4. EASIEST WAY - Use LanguageAwareWidget:
 *    LanguageAwareWidget(
 *      builder: (context) {
 *        return Text(AppTranslations.getText('hello'));
 *      },
 *    )
 * 
 * The UI will automatically rebuild whenever changeLanguage() is called!
 */
class LanguageChangeNotifier extends ChangeNotifier {
  static final LanguageChangeNotifier _instance =
      LanguageChangeNotifier._internal();
  factory LanguageChangeNotifier() => _instance;
  LanguageChangeNotifier._internal();

  void notifyLanguageChanged() {
    notifyListeners();
  }
}

class AppLocalizations {
  static const Locale english = Locale('en', 'US');
  static const Locale arabic = Locale('ar', 'SA');

  static const List<Locale> supportedLocales = [english, arabic];

  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';

  static Locale _currentLocale = english;

  static Locale get currentLocale => _currentLocale;

  static bool get isRTL => _currentLocale.languageCode == 'ar';

  static bool get isArabic => _currentLocale.languageCode == 'ar';

  static bool get isEnglish => _currentLocale.languageCode == 'en';

  // Initialize localization
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Arabic unless the user explicitly chose English.
    final languageCode =
        prefs.getString(_languageCodeKey) == 'en' ? 'en' : 'ar';
    final countryCode = prefs.getString(_countryCodeKey) ??
        (languageCode == 'ar' ? 'SA' : 'US');

    _currentLocale = Locale(languageCode, countryCode);

    // Set system UI overlay style based on language
    _updateSystemUI();
  }

  // Change language
  static Future<void> changeLanguage(Locale locale) async {
    _currentLocale = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');

    _updateSystemUI();

    // Notify all listeners that language has changed
    LanguageChangeNotifier().notifyLanguageChanged();
  }

  // Update system UI for RTL/LTR
  static void _updateSystemUI() {
    if (isRTL) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  // Get text direction
  static TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Get alignment based on language
  static Alignment get textAlignment =>
      isRTL ? Alignment.centerRight : Alignment.centerLeft;

  // Get start alignment for RTL support
  static Alignment get startAlignment =>
      isRTL ? Alignment.centerRight : Alignment.centerLeft;

  // Get end alignment for RTL support
  static Alignment get endAlignment =>
      isRTL ? Alignment.centerLeft : Alignment.centerRight;

  // Get cross axis alignment for RTL support
  static CrossAxisAlignment get crossAxisAlignment =>
      isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start;

  // Get main axis alignment for RTL support
  static MainAxisAlignment get mainAxisAlignment =>
      isRTL ? MainAxisAlignment.end : MainAxisAlignment.start;

  // Get language change notifier for listening to language changes
  static LanguageChangeNotifier get languageNotifier =>
      LanguageChangeNotifier();
}

// Helper widget to make any widget automatically rebuild when language changes
class LanguageAwareWidget extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const LanguageAwareWidget({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageChangeNotifier>(
      builder: (context, notifier, child) {
        return builder(context);
      },
    );
  }
}

// Demo widget showing different ways to use reactive fonts
class ReactiveFontDemo extends StatelessWidget {
  const ReactiveFontDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Method 1: ReactiveText (Recommended for simple text)
        ReactiveText(
          'This text automatically updates font when language changes',
          fontSize: 16,
          weight: FontWeight.w600,
        ),

        const SizedBox(height: 16),

        // Method 2: ReactiveFontBuilder (For custom widgets)
        ReactiveFontBuilder(
          fontSize: 18,
          weight: FontWeight.w700,
          color: Colors.blue,
          builder: (context, fontStyle) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Custom styled text', style: fontStyle),
            );
          },
        ),

        const SizedBox(height: 16),

        // Method 3: LanguageAwareWidget with AppFonts
        LanguageAwareWidget(
          builder: (context) {
            return Text(
              'Text using AppFonts.currentFontStyle',
              style: AppFonts.currentFontStyle(
                fontSize: 16,
                weight: FontWeight.w500,
                color: Colors.green,
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Method 4: Consumer directly
        Consumer<LanguageChangeNotifier>(
          builder: (context, notifier, child) {
            return Text(
              'Text using Consumer directly',
              style: TextStyle(
                fontFamily: AppFonts.currentFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }
}

// Localization Delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
