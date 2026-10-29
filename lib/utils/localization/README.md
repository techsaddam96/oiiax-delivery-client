# Language Change Notifier - Automatic UI Updates

This system automatically updates the UI when the language changes, without requiring manual saves or hot reloads.

## How It Works

1. **Language Change Notifier**: A singleton `ChangeNotifier` that notifies all listeners when the language changes
2. **Automatic UI Updates**: Widgets wrapped with the notifier automatically rebuild when language changes
3. **Reactive Fonts**: Fonts automatically switch between Montserrat (English) and Almarai (Arabic) when language changes
4. **No Static Changes**: The existing `AppLocalizations` static structure remains unchanged

## Usage Examples

### Method 1: LanguageAwareWidget (Recommended)

Wrap any widget that needs to update when language changes:

```dart
LanguageAwareWidget(
  builder: (context) {
    return Text(AppTranslations.getText('hello'));
  },
)
```

### Method 2: Consumer

Use Consumer to listen for language changes:

```dart
Consumer<LanguageChangeNotifier>(
  builder: (context, notifier, child) {
    return Text(AppTranslations.getText('hello'));
  },
)
```

### Method 3: Provider.of

Access the notifier directly:

```dart
Provider.of<LanguageChangeNotifier>(context, listen: true)
```

## Reactive Font System

### Fonts Automatically Update When Language Changes!

**English**: Montserrat (clean, modern, readable)  
**Arabic**: Almarai (beautiful Arabic script, optimized for readability)

### Method 1: ReactiveText (Recommended for simple text)

```dart
ReactiveText(
  'This text automatically updates font when language changes',
  fontSize: 16,
  weight: FontWeight.w600,
)
```

### Method 2: ReactiveFontBuilder (For custom widgets)

```dart
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
)
```

### Method 3: LanguageAwareWidget with AppFonts

```dart
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
)
```

### Method 4: Consumer directly

```dart
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
)
```

## Implementation Details

- **Provider Setup**: The language notifier is provided at the app level in `main.dart`
- **Automatic Notification**: When `AppLocalizations.changeLanguage()` is called, all listeners are notified
- **Reactive Theme**: Theme automatically rebuilds with new fonts when language changes
- **Font Switching**: Fonts automatically switch between Montserrat (English) and Almarai (Arabic)
- **RTL Support**: Text direction and alignment automatically adjust for Arabic

## Benefits

✅ **No Manual Saves**: UI updates automatically when language changes  
✅ **No Hot Reloads**: Changes are immediate and smooth  
✅ **Reactive Fonts**: Fonts automatically switch when language changes  
✅ **Performance**: Only widgets that need updates are rebuilt  
✅ **Maintainable**: Centralized language change management  
✅ **Backward Compatible**: Existing code continues to work  

## Example: Settings Page

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LanguageAwareWidget(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: ReactiveText(
              'Settings',
              fontSize: 18,
              weight: FontWeight.w600,
            ),
          ),
          body: Column(
            children: [
              ReactiveText(
                'Language',
                fontSize: 16,
                weight: FontWeight.w500,
              ),
              ReactiveText(
                'Notifications',
                fontSize: 16,
                weight: FontWeight.w500,
              ),
              // All text and fonts will automatically update when language changes!
            ],
          ),
        );
      },
    );
  }
}
```

## Troubleshooting

**Widget not updating?** Make sure it's wrapped with `LanguageAwareWidget` or `Consumer<LanguageChangeNotifier>`

**Fonts not changing?** Use `ReactiveText` or `ReactiveFontBuilder` instead of static `AppFonts` styles

**Provider not found?** Ensure `AppLocalizations.languageNotifier` is provided in your widget tree

**Theme not updating?** The theme now automatically rebuilds when language changes
