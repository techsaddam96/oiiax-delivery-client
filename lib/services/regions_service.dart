import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';

class Region {
  final int id;
  final String enregion;
  final String anregion;
  final int idDrivers;
  final int status;
  final int idcity;

  Region({
    required this.id,
    required this.enregion,
    required this.anregion,
    required this.idDrivers,
    required this.status,
    required this.idcity,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: int.parse(json['id'].toString()),
      enregion: json['enregion']?.toString() ?? '',
      anregion: json['anregion']?.toString() ?? '',
      idDrivers: int.parse(json['id_drivers'].toString()),
      status: int.parse(json['status'].toString()),
      idcity: int.parse(json['idcity'].toString()),
    );
  }
}

class RegionsResponse {
  final String status;
  final String message;
  final List<Region> regions;

  RegionsResponse({
    required this.status,
    required this.message,
    required this.regions,
  });

  factory RegionsResponse.fromJson(Map<String, dynamic> json) {
    return RegionsResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      regions: (json['regions'] as List<dynamic>? ?? const [])
          .map((entry) => Region.fromJson(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }
}

class RegionsService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  static List<Region> _regions = <Region>[];
  static bool _isLoaded = false;
  static bool _isLoading = false;

  static List<Region> get regions => List<Region>.unmodifiable(_regions);
  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;

  static Future<void> loadRegions({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _isLoaded && _regions.isNotEmpty) return;

    _isLoading = true;

    try {
      final apiKey = await AuthService.getApiKey();

      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception('Missing API key');
      }

      final response = await _dio.get(
        AppUrls.getRegions,
        options: Options(
          headers: {
            'X-API-KEY': apiKey,
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['status'] == 'success') {
        final regionsResponse = RegionsResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
        _regions = regionsResponse.regions;
        _isLoaded = true;
        return;
      }

      throw Exception('Failed to fetch regions');
    } catch (error) {
      _regions = <Region>[];
      _isLoaded = false;
      throw Exception('Unable to load regions');
    } finally {
      _isLoading = false;
    }
  }

  static List<Region> getRegionsByCity(int cityId) {
    return _regions.where((region) => region.idcity == cityId).toList();
  }

  static Region? getRegionById(int id) {
    try {
      return _regions.firstWhere((region) => region.id == id);
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _regions = <Region>[];
    _isLoaded = false;
  }
}
