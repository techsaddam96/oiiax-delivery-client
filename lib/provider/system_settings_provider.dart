import 'package:blockatie/services/system_settings_service.dart';
import 'package:flutter/material.dart';

class SystemSettingsProvider with ChangeNotifier {
  SystemSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  SystemSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSettings => _settings != null;

  // Contact information getters
  String get contactPhone => _settings?.contactPhone ?? '';
  String get contactEmail => _settings?.contactEmail ?? '';
  String get contactAddress => _settings?.contactAddress ?? '';
  String get whatsAppNumber => _settings?.socialWhatsapp ?? '';
  String get facebookUrl => _settings?.socialFacebook ?? '';
  String get instagramUrl => _settings?.socialInstagram ?? '';
  String get linkedInUrl => _settings?.socialLinkedin ?? '';
  String get workingHours => _settings?.workingHours ?? '';
  String get siteName => _settings?.siteName ?? 'OIIAX';
  String get siteTagline => _settings?.siteTagline ?? '';

  /// Load system settings
  Future<bool> loadSystemSettings() async {
    if (_isLoading) return false;
    if (_settings != null) return true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await SystemSettingsService.getSystemSettings();
      _settings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh system settings (force reload)
  Future<bool> refreshSystemSettings() async {
    SystemSettingsService.clearCache();
    _settings = null;
    return await loadSystemSettings();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get WhatsApp URL for launching WhatsApp
  String getWhatsAppUrl({String? message}) {
    final phone = whatsAppNumber.replaceAll(RegExp(r'[^\d]'), '');
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
    return 'https://wa.me/$phone${encodedMessage.isNotEmpty ? '?text=$encodedMessage' : ''}';
  }

  /// Get WhatsApp URL with fallback to web version
  String getWhatsAppUrlWithFallback({String? message}) {
    final phone = whatsAppNumber.replaceAll(RegExp(r'[^\d]'), '');
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
    // Try app first, fallback to web
    return 'whatsapp://send?phone=$phone${encodedMessage.isNotEmpty ? '&text=$encodedMessage' : ''}';
  }

  /// Get phone call URL
  String getPhoneCallUrl() {
    final phone = contactPhone.replaceAll(RegExp(r'[^\d]'), '');
    return 'tel:$phone';
  }

  /// Get email URL
  String getEmailUrl({String? subject, String? body}) {
    final email = contactEmail;
    final encodedSubject = subject != null ? Uri.encodeComponent(subject) : '';
    final encodedBody = body != null ? Uri.encodeComponent(body) : '';

    String url = 'mailto:$email';
    if (encodedSubject.isNotEmpty || encodedBody.isNotEmpty) {
      url += '?';
      if (encodedSubject.isNotEmpty) {
        url += 'subject=$encodedSubject';
      }
      if (encodedBody.isNotEmpty) {
        url += '${encodedSubject.isNotEmpty ? '&' : ''}body=$encodedBody';
      }
    }
    return url;
  }

  /// Check if social media URLs are available
  bool get hasFacebook => facebookUrl.isNotEmpty;
  bool get hasInstagram => instagramUrl.isNotEmpty;
  bool get hasLinkedIn => linkedInUrl.isNotEmpty;
  bool get hasWhatsApp => whatsAppNumber.isNotEmpty;
  bool get hasPhone => contactPhone.isNotEmpty;
  bool get hasEmail => contactEmail.isNotEmpty;
}
