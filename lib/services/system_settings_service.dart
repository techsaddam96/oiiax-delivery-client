import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';

class SystemSettings {
  final String siteName;
  final String siteTagline;
  final String logoPath;
  final String faviconPath;
  final String contactEmail;
  final String contactPhone;
  final String contactAddress;
  final String socialFacebook;
  final String socialWhatsapp;
  final String socialLinkedin;
  final String socialInstagram;
  final String timezone;
  final String currency;
  final String workingHours;
  final String workingHoursStart;
  final String workingHoursEnd;

  SystemSettings({
    required this.siteName,
    required this.siteTagline,
    required this.logoPath,
    required this.faviconPath,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactAddress,
    required this.socialFacebook,
    required this.socialWhatsapp,
    required this.socialLinkedin,
    required this.socialInstagram,
    required this.timezone,
    required this.currency,
    required this.workingHours,
    required this.workingHoursStart,
    required this.workingHoursEnd,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      siteName: json['site_name'] ?? '',
      siteTagline: json['site_tagline'] ?? '',
      logoPath: json['logo_path'] ?? '',
      faviconPath: json['favicon_path'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      contactAddress: json['contact_address'] ?? '',
      socialFacebook: json['social_facebook'] ?? '',
      socialWhatsapp: json['social_whatsapp'] ?? '',
      socialLinkedin: json['social_linkedin'] ?? '',
      socialInstagram: json['social_instagram'] ?? '',
      timezone: json['timezone'] ?? '',
      currency: json['currency'] ?? '',
      workingHours: json['working_hours'] ?? '',
      workingHoursStart: json['working_hours_start'] ?? '',
      workingHoursEnd: json['working_hours_end'] ?? '',
    );
  }
}

class SystemSettingsService {
  static final Dio _dio = Dio();
  static SystemSettings? _cachedSettings;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration =
      Duration(minutes: 30); // Cache for 30 minutes

  /// Get system settings with caching
  static Future<SystemSettings> getSystemSettings() async {
    // Check if we have cached settings and they're still valid
    if (_cachedSettings != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        return _cachedSettings!;
      }
    }

    try {
      final apiKey = await AuthService.getApiKey();

      final response = await _dio.get(
        '${AppUrls.baseUrl}/api_system_settings.php',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (apiKey != null) 'X-API-KEY': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['settings'] != null) {
          final settings = SystemSettings.fromJson(data['settings']);

          // Cache the settings
          _cachedSettings = settings;
          _lastFetchTime = DateTime.now();

          return settings;
        } else {
          throw Exception('Failed to load system settings');
        }
      } else {
        throw Exception('Network error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Server error occurred');
      } else {
        throw Exception('Network error occurred');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Clear cached settings (useful for testing or when settings change)
  static void clearCache() {
    _cachedSettings = null;
    _lastFetchTime = null;
  }

  /// Get WhatsApp contact number
  static Future<String> getWhatsAppNumber() async {
    final settings = await getSystemSettings();
    return settings.socialWhatsapp;
  }

  /// Get contact phone number
  static Future<String> getContactPhone() async {
    final settings = await getSystemSettings();
    return settings.contactPhone;
  }

  /// Get contact email
  static Future<String> getContactEmail() async {
    final settings = await getSystemSettings();
    return settings.contactEmail;
  }

  /// Get Facebook URL
  static Future<String> getFacebookUrl() async {
    final settings = await getSystemSettings();
    return settings.socialFacebook;
  }

  /// Get Instagram URL
  static Future<String> getInstagramUrl() async {
    final settings = await getSystemSettings();
    return settings.socialInstagram;
  }

  /// Get LinkedIn URL
  static Future<String> getLinkedInUrl() async {
    final settings = await getSystemSettings();
    return settings.socialLinkedin;
  }

  /// Get working hours
  static Future<String> getWorkingHours() async {
    final settings = await getSystemSettings();
    return settings.workingHours;
  }

  /// Get site name
  static Future<String> getSiteName() async {
    final settings = await getSystemSettings();
    return settings.siteName;
  }

  /// Get site tagline
  static Future<String> getSiteTagline() async {
    final settings = await getSystemSettings();
    return settings.siteTagline;
  }
}
