import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'dart:async';
import 'dart:io';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/request_id_service.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/password_policy.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class ProfileUpdateResult {
  const ProfileUpdateResult({
    required this.success,
    required this.message,
    this.code,
  });

  final bool success;
  final String message;
  final String? code;
}

class ProfileProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    profileInfo = null;
    profileImage = null;
    location = null;
    latitude = null;
    longitude = null;
    streetNumber = null;
    city = null;
    _statistics = null;
    _statisticsRequest = null;
    _profileError = null;
    _statisticsError = null;
    _isLoading = false;
    _isUpdating = false;
    _isLoadingStatistics = false;
    for (final controller in [
      nameController,
      storeNameController,
      newPasswordController,
      confirmPasswordController,
      phoneController,
      locationController
    ]) {
      controller.clear();
    }
  }

  ProfileProvider({
    Dio? profileDio,
    Dio? statisticsDio,
    Future<ClientSession> Function()? statisticsSessionReader,
    Dio? updateDio,
  })  : _updateDio = updateDio != null ? protectSessionDio(updateDio) : null,
        _profileDio = profileDio != null
            ? protectSessionDio(profileDio)
            : sessionDio(BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20))),
        _statisticsDio = statisticsDio != null
            ? protectSessionDio(statisticsDio)
            : sessionDio(
                BaseOptions(connectTimeout: const Duration(seconds: 20))),
        _statisticsSessionReader =
            statisticsSessionReader ?? AuthService.getSession;

  final Dio _statisticsDio;
  final Dio _profileDio;

  /// Test seam for the profile update; production uses a fresh session Dio.
  final Dio? _updateDio;
  final Future<ClientSession> Function() _statisticsSessionReader;
  Future<void>? _statisticsRequest;
  bool _disposed = false;

  File? profileImage;
  String? location;
  final List<String> languages = ['English', 'Arabic'];
  String selectedLanguage = 'English';

  final nameController = TextEditingController();
  final storeNameController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  double? latitude;
  double? longitude;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ClientStatisticsData? _statistics;
  bool _isLoadingStatistics = false;
  String? _profileError;
  String? _statisticsError;

  ClientStatisticsData? get statistics => _statistics;
  bool get isLoadingStatistics => _isLoadingStatistics;
  String? get profileError => _profileError;
  String? get statisticsError => _statisticsError;

  ClientInfo? profileInfo;
  String? streetNumber;
  String? city;

  void setLanguage(String lang) {
    selectedLanguage = lang;
    notifyListeners();
  }

  void setLocationCoordinates(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final sessionGeneration = stateGeneration;
    try {
      final pickedFile = await guardSession(
          ImagePicker().pickImage(source: ImageSource.gallery),
          sessionGeneration);
      if (pickedFile == null) {
        return;
      }

      profileImage = File(pickedFile.path);
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  bool isPasswordMatch() {
    return newPasswordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  Future<ProfileUpdateResult> updateClientProfile({
    required String clientName,
    required String storeName,
    required String locationText,
    String password = '',
    File? imageFile,
    double? latitude,
    double? longitude,
  }) async {
    final sessionGeneration = stateGeneration;
    // AuthService compares the global session generation, not this provider's.
    final authGeneration = UserSessionState.generation;
    try {
      if (_isUpdating) {
        return ProfileUpdateResult(
          success: false,
          message: _genericMessage(
            en: 'A profile update is already in progress.',
            ar: 'يوجد تحديث جارٍ للملف الشخصي الآن.',
          ),
        );
      }

      final trimmedName = clientName.trim();
      final trimmedStore = storeName.trim();
      final trimmedLocation = locationText.trim();
      // Blank means "no change"; otherwise the password is sent exactly as
      // typed — the shared policy refuses edge spaces rather than trimming.
      final trimmedPassword = password.trim().isEmpty ? '' : password;

      if (trimmedName.length < 2 || trimmedStore.length < 2) {
        return ProfileUpdateResult(
          success: false,
          message: _genericMessage(
            en: 'Please complete the required fields correctly.',
            ar: 'يرجى تعبئة الحقول المطلوبة بشكل صحيح.',
          ),
        );
      }

      final policyMessage = trimmedPassword.isEmpty
          ? null
          : PasswordPolicy.message(trimmedPassword,
              isArabic: AppLocalizations.isArabic);
      if (policyMessage != null) {
        return ProfileUpdateResult(success: false, message: policyMessage);
      }

      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);
      final userId =
          await guardSession(AuthService.getUserId(), sessionGeneration);

      if (apiKey == null ||
          apiKey.trim().isEmpty ||
          userId == null ||
          userId.trim().isEmpty) {
        return ProfileUpdateResult(
          success: false,
          message: _genericMessage(
            en: 'Your session is no longer valid. Please login again.',
            ar: 'انتهت الجلسة الحالية. يرجى تسجيل الدخول مرة أخرى.',
          ),
        );
      }

      _isUpdating = true;
      notifyListeners();

      try {
        final payload = <String, dynamic>{
          'client_id': userId,
          'nclient': trimmedName,
          'nstore': trimmedStore,
          'lclient': trimmedLocation,
        };

        if (trimmedPassword.isNotEmpty) {
          payload['passclient'] = trimmedPassword;
        }

        if (imageFile != null) {
          payload['loshop'] = await guardSession(
              MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.path.split(Platform.pathSeparator).last,
              ),
              sessionGeneration);
        }

        if (latitude != null && longitude != null) {
          payload['latitude'] = latitude.toString();
          payload['longitude'] = longitude.toString();
        }

        final lease = RequestIdService.acquire(
          operation: trimmedPassword.isNotEmpty
              ? 'client.changePassword'
              : 'client.updateProfile',
          payload: payload,
        );
        final response = await guardSession(
            (_updateDio ?? sessionDio()).post(
              AppUrls.updateClientProfile,
              data: FormData.fromMap(payload),
              options: Options(
                headers: {
                  'X-API-KEY': apiKey,
                  'Accept': '*/*',
                  ...lease.headers(),
                },
                contentType: 'multipart/form-data',
              ),
            ),
            sessionGeneration);
        lease.complete();

        final data = _asMap(response.data);
        final success =
            response.statusCode == 200 && data['status'] == 'success';
        final message = _messageFrom(
          data,
          fallback: success
              ? _genericMessage(
                  en: 'Profile updated successfully.',
                  ar: 'تم تحديث معلومات الحساب بنجاح.',
                )
              : _genericMessage(
                  en: 'Unable to save changes. Please try again.',
                  ar: 'تعذر حفظ التغييرات. حاول مرة أخرى.',
                ),
        );

        if (!success) {
          return ProfileUpdateResult(
            success: false,
            message: message,
            code: data['code']?.toString(),
          );
        }

        // A password change rotates the key and revokes every remember token,
        // signing other devices out; this device continues with the new key.
        final rotatedKey = data['api_key']?.toString().trim() ?? '';
        if (rotatedKey.isNotEmpty) {
          await guardSession(
              AuthService.replaceApiKey(
                rotatedKey,
                expectedGeneration: authGeneration,
              ),
              sessionGeneration);
        }

        if (imageFile != null) {
          profileImage = imageFile;
        }

        nameController.text = trimmedName;
        storeNameController.text = trimmedStore;
        locationController.text = trimmedLocation;
        this.latitude = latitude ?? this.latitude;
        this.longitude = longitude ?? this.longitude;

        await guardSession(fetchClientProfile(silent: true), sessionGeneration);

        return ProfileUpdateResult(
          success: true,
          message: message,
          code: data['code']?.toString(),
        );
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        final data = _asMap(error.response?.data);
        return ProfileUpdateResult(
          success: false,
          message: _messageFrom(
            data,
            fallback: _networkMessage(),
          ),
          code: data['code']?.toString(),
        );
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return ProfileUpdateResult(
          success: false,
          message: _genericMessage(
            en: 'Unable to save changes. Please try again.',
            ar: 'تعذر حفظ التغييرات. حاول مرة أخرى.',
          ),
        );
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isUpdating = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return const ProfileUpdateResult(
          success: false, message: 'Session changed.');
    }
  }

  Future<ClientInfo?> fetchClientProfile({bool silent = false}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoading) {
        return profileInfo;
      }

      _isLoading = true;
      _profileError = null;
      notifyListeners();

      try {
        final userId =
            await guardSession(AuthService.getUserId(), sessionGeneration);
        final apiKey =
            await guardSession(AuthService.getApiKey(), sessionGeneration);

        if (userId == null ||
            userId.trim().isEmpty ||
            apiKey == null ||
            apiKey.trim().isEmpty) {
          _profileError = _genericMessage(
            en: 'Your session is no longer valid. Please login again.',
            ar: 'انتهت الجلسة الحالية. يرجى تسجيل الدخول مرة أخرى.',
          );
          return null;
        }

        final response = await guardSession(
            _profileDio.postUri(
              Uri.parse(AppUrls.profileInfo),
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey,
                },
              ),
              data: {
                'clientId': userId,
              },
            ),
            sessionGeneration);

        final data = _asMap(response.data);
        if (response.statusCode == 200 && data['status'] == 'success') {
          final model = ClientProfileModel.fromJson(data);
          profileInfo = model.profile;
          location = profileInfo?.lclient;
          setClientData();
          _profileError = null;
          return model.profile;
        }

        _profileError = _messageFrom(
          data,
          fallback: _genericMessage(
            en: 'Unable to load profile data. Please try again.',
            ar: 'تعذر تحميل بيانات الحساب. حاول مرة أخرى.',
          ),
        );
        if (!silent) {
          AppUtils.errorToast(_profileError!);
        }
        return null;
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        final data = _asMap(error.response?.data);
        _profileError = _messageFrom(
          data,
          fallback: _networkMessage(),
        );
        if (!silent) {
          AppUtils.errorToast(_profileError!);
        }
        return null;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _profileError = _genericMessage(
          en: 'Unable to load profile data. Please try again.',
          ar: 'تعذر تحميل بيانات الحساب. حاول مرة أخرى.',
        );
        if (!silent) {
          AppUtils.errorToast(_profileError!);
        }
        return null;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return null;
    }
  }

  Widget getProfileImageWidget() {
    if (profileImage != null) {
      return Image.file(profileImage!, fit: BoxFit.cover);
    }

    final imagePath = profileInfo?.loshop.trim() ?? '';
    if (imagePath.isNotEmpty) {
      final imageUrl = imagePath.startsWith('http')
          ? imagePath
          : 'https://dashboard.blockatie.com$imagePath';
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront_rounded, size: 40),
      );
    }

    return const Icon(Icons.storefront_rounded, size: 40);
  }

  void setClientData() {
    if (profileInfo == null) {
      return;
    }

    nameController.text = profileInfo!.nclient;
    storeNameController.text = profileInfo!.nstore;
    phoneController.text = profileInfo!.phclient;
    locationController.text =
        location?.trim().isNotEmpty == true ? location! : profileInfo!.lclient;
    latitude = profileInfo!.latitude;
    longitude = profileInfo!.longitude;
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final placemarks = await guardSession(
            placemarkFromCoordinates(latitude, longitude), sessionGeneration);
        if (placemarks.isEmpty) {
          return _genericMessage(
            en: 'Location not available',
            ar: 'الموقع غير متوفر',
          );
        }

        final place = placemarks.first;
        final parts = <String>[
          place.street ?? '',
          place.locality ?? '',
          place.administrativeArea ?? '',
          place.country ?? '',
        ].where((part) => part.trim().isNotEmpty).toList();

        if (parts.isEmpty) {
          return _genericMessage(
            en: 'Location not available',
            ar: 'الموقع غير متوفر',
          );
        }

        streetNumber = place.street?.trim();
        city = place.locality?.trim();
        return parts.join(', ');
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return _genericMessage(
          en: 'Location not available',
          ar: 'الموقع غير متوفر',
        );
      }
    } on SessionChanged {
      return '';
    }
  }

  // Home, wallet, and profile await the same request and consume one snapshot.
  Future<void> fetchClientStatistics() {
    if (_disposed) return Future<void>.value();
    if (_statisticsRequest != null) return _statisticsRequest!;
    final completion = Completer<void>();
    final generation = stateGeneration;
    _statisticsRequest = completion.future;
    _isLoadingStatistics = true;
    _statisticsError = null;
    _statistics = null;
    notifyListeners();
    unawaited(_fetchClientStatistics().whenComplete(() {
      if (acceptsState(generation)) {
        _statisticsRequest = null;
        _isLoadingStatistics = false;
        notifyListeners();
      }
      completion.complete();
    }));
    return completion.future;
  }

  Future<void> _fetchClientStatistics() async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final session =
            await guardSession(_statisticsSessionReader(), sessionGeneration);
        if (_disposed) return;
        if (!session.isValid) {
          _statisticsError = _genericMessage(
            en: 'Your session is no longer valid. Please login again.',
            ar: 'انتهت الجلسة الحالية. يرجى تسجيل الدخول مرة أخرى.',
          );
          return;
        }
        final response = await guardSession(
            _statisticsDio.post(
              AppUrls.clientStatistics,
              data: {
                'client_id': session.clientId,
              },
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': session.apiKey,
                  'Cache-Control': 'no-cache',
                },
                sendTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                validateStatus: (status) => status != null && status < 500,
              ),
            ),
            sessionGeneration);

        final currentSession =
            await guardSession(_statisticsSessionReader(), sessionGeneration);
        if (_disposed) return;
        if (currentSession.clientId != session.clientId ||
            currentSession.apiKey != session.apiKey ||
            !currentSession.isValid) {
          _statisticsError = _genericMessage(
            en: 'Your session changed. Please refresh the wallet.',
            ar: 'تغيرت الجلسة. يرجى تحديث المحفظة.',
          );
          return;
        }
        final data = _asMap(response.data);
        final success = response.statusCode == 200 &&
            (data['success'] == true || data['status'] == 'success');

        if (success && data['data'] is Map<String, dynamic>) {
          final nestedData = Map<String, dynamic>.from(data['data']);
          if (nestedData['wallet_version'] == 1 &&
              nestedData['wallet_review_required'] is bool &&
              const [
                'balance_total',
                'total_required',
                'final_total_value_order',
                'withdrawable_balance',
                'reserved_withdrawals',
              ].every((key) => nestedData[key] is String)) {
            _statistics = ClientStatisticsModel.fromJson({
              'success': true,
              'data': nestedData,
            }).data;
            _statisticsError = null;
            return;
          }
        }

        _statisticsError = _messageFrom(
          data,
          fallback: _genericMessage(
            en: 'Unable to load wallet data. Please try again.',
            ar: 'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
          ),
        );
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        final data = _asMap(error.response?.data);
        _statisticsError = _messageFrom(
          data,
          fallback: _networkMessage(),
        );
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _statisticsError = _genericMessage(
          en: 'Unable to load wallet data. Please try again.',
          ar: 'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
        );
      }
    } on SessionChanged {
      return;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _messageFrom(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = AppLocalizations.isArabic
        ? data['message_ar'] ?? data['message']
        : data['message_en'] ?? data['message'];
    final text = message?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _networkMessage() {
    return _genericMessage(
      en: 'Unable to connect to the server. Please try again.',
      ar: 'تعذر الاتصال بالخادم. حاول مرة أخرى.',
    );
  }

  String _genericMessage({required String en, required String ar}) {
    return AppLocalizations.isArabic ? ar : en;
  }

  @override
  void dispose() {
    _profileDio.close(force: true);
    _disposed = true;
    _statisticsDio.close(force: true);
    nameController.dispose();
    storeNameController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
