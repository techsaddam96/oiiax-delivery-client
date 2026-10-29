import 'dart:async';

import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/session_refresh_queue.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/models/shipment_financial.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/order_services.dart';
import 'package:blockatie/utils/client_shipment_cancellation_eligibility.dart';
import 'package:blockatie/utils/instant_shipment_progress.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:dio/dio.dart';

enum InstantShipmentFilter {
  all,
  waiting,
  waitingDriver,
  inDelivery,
  completed,
  cancelled,
}

enum InstantShipmentErrorType {
  none,
  unauthorized,
  network,
  generic,
}

class InstantShipmentActionResult {
  const InstantShipmentActionResult({
    required this.success,
    required this.message,
    this.driverCustodyHeld = false,
  });

  final bool success;
  final String message;
  final bool driverCustodyHeld;
}

class InstantShipmentCancellationCheck {
  const InstantShipmentCancellationCheck({
    required this.eligible,
    this.preview,
  });

  const InstantShipmentCancellationCheck.notEligible()
      : eligible = false,
        preview = null;

  final bool eligible;
  final CancellationPreview? preview;
}

class ShipmentInstantprovider extends UserScopedNotifier {
  @override
  void clearUserState() {
    shipmentInstantResponse = null;
    _busyShipmentIds.clear();
    _revalidatingCancellationIds.clear();
    _cancellationEligibility.clear();
    _cancellationEligibilityEpoch = 0;
    _allShipments = [];
    _visibleShipments = [];
    isLoading = false;
    _hasLoaded = false;
    _hasError = false;
    _errorMessage = null;
    _errorType = InstantShipmentErrorType.none;
    _currentPage = 1;
    _searchQuery = '';
    _selectedFilter = InstantShipmentFilter.all;
  }

  ShipmentInstantprovider()
      : _dio = sessionDio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        );

  static const int _itemsPerPage = 5;
  static const Set<int> _completedStatusIds = {6, 11};
  static const Set<int> _cancelledStatusIds = {7, 8, 9};
  static const Set<int> _finalStatusIds = {6, 7, 8, 9, 11};

  final Dio _dio;
  final Set<int> _busyShipmentIds = <int>{};
  final Set<int> _revalidatingCancellationIds = <int>{};
  final Map<int, bool> _cancellationEligibility = <int, bool>{};
  int _cancellationEligibilityEpoch = 0;

  ShipmentsResponse? shipmentInstantResponse;

  List<Shipment> _allShipments = const <Shipment>[];
  List<Shipment> _visibleShipments = const <Shipment>[];

  bool isLoading = false;
  bool _hasLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  InstantShipmentErrorType _errorType = InstantShipmentErrorType.none;

  int _currentPage = 1;
  String _searchQuery = '';
  InstantShipmentFilter _selectedFilter = InstantShipmentFilter.all;

  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => (_visibleShipments.length / _itemsPerPage).ceil();
  int get totalCount => _allShipments.length;
  int get filteredCount => _visibleShipments.length;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  InstantShipmentFilter get selectedFilter => _selectedFilter;
  InstantShipmentErrorType get errorType => _errorType;

  List<Shipment> get allShipments => List<Shipment>.unmodifiable(_allShipments);
  List<Shipment> get displayShipments =>
      List<Shipment>.unmodifiable(_visibleShipments);

  List<Shipment> get paginatedShipments {
    if (_visibleShipments.isEmpty) {
      return const <Shipment>[];
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= _visibleShipments.length) {
      return const <Shipment>[];
    }

    final endIndex = startIndex + _itemsPerPage;
    return _visibleShipments.sublist(
      startIndex,
      endIndex > _visibleShipments.length ? _visibleShipments.length : endIndex,
    );
  }

  int get waitingCount => _allShipments.where(_matchesWaiting).length;
  int get waitingDriverCount =>
      _allShipments.where(_matchesWaitingDriver).length;
  int get inDeliveryCount => _allShipments.where(_matchesInDelivery).length;
  int get completedCount => _allShipments.where(_matchesCompleted).length;
  int get cancelledCount => _allShipments.where(_matchesCancelled).length;

  bool isShipmentBusy(int shipmentId) =>
      _busyShipmentIds.contains(shipmentId) ||
      _revalidatingCancellationIds.contains(shipmentId);

  bool canCancelShipment(Shipment shipment) {
    return ClientShipmentCancellationEligibility.isListEligible(shipment) &&
        _cancellationEligibility[shipment.id] == true;
  }

  /// Refreshes both the list and this shipment's details before a client is
  /// allowed to open or submit a cancellation.  The legacy list endpoint does
  /// not expose `cancellation.allowed`, so missing or stale details are not
  /// treated as permission.
  Future<InstantShipmentCancellationCheck> revalidateCancellation(
    int shipmentId,
  ) async {
    if (shipmentId <= 0 || _revalidatingCancellationIds.contains(shipmentId)) {
      return const InstantShipmentCancellationCheck.notEligible();
    }

    final sessionGeneration = stateGeneration;
    _revalidatingCancellationIds.add(shipmentId);
    notifyListeners();

    try {
      await guardSession(
        getShipmentsInstant(force: true, silent: true),
        sessionGeneration,
      );
      if (!acceptsState(sessionGeneration) || _hasError) {
        return const InstantShipmentCancellationCheck.notEligible();
      }

      final shipment = _shipmentById(shipmentId);
      if (shipment == null ||
          !ClientShipmentCancellationEligibility.isListEligible(shipment)) {
        _setCancellationEligibility(shipmentId, false, notify: false);
        return const InstantShipmentCancellationCheck.notEligible();
      }

      final details = await guardSession(
        OrderServices.getOrderDetails(orderId: shipmentId),
        sessionGeneration,
      );
      if (!acceptsState(sessionGeneration)) {
        return const InstantShipmentCancellationCheck.notEligible();
      }

      final eligible = ClientShipmentCancellationEligibility.isDetailsEligible(
        shipmentId: shipmentId,
        response: details,
      );
      _setCancellationEligibility(shipmentId, eligible, notify: false);
      return InstantShipmentCancellationCheck(
        eligible: eligible,
        preview: eligible ? details?.data.cancellation : null,
      );
    } on SessionChanged {
      return const InstantShipmentCancellationCheck.notEligible();
    } finally {
      if (acceptsState(sessionGeneration)) {
        _revalidatingCancellationIds.remove(shipmentId);
        notifyListeners();
      }
    }
  }

  late final _refreshQueue = SessionRefreshQueue(() => stateGeneration);
  Future<void> getShipmentsInstant({bool force = false, bool silent = false}) =>
      _refreshQueue.run(() => _fetchShipments(force: force, silent: silent),
          trailing: force);

  Future<void> _fetchShipments(
      {required bool force, required bool silent}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading && !force) {
        return;
      }

      // Do not keep an old permission visible while a fresh list is being
      // requested. A failed refresh must fail closed just like an unknown
      // shipment state.
      _cancellationEligibility.clear();
      final eligibilityEpoch = ++_cancellationEligibilityEpoch;

      final clientId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);

      if (_isBlank(clientId?.toString()) || _isBlank(apiKey)) {
        _setError(
          type: InstantShipmentErrorType.unauthorized,
          message: _text(
            'Your session is no longer valid. Please log in again.',
            'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
          ),
        );
        return;
      }

      isLoading = !silent || !hasLoaded;
      _hasError = false;
      _errorMessage = null;
      _errorType = InstantShipmentErrorType.none;
      notifyListeners();

      try {
        final response = await guardSession(
            _dio.post(
              AppUrls.getClientShipmentInstant,
              options: Options(
                headers: <String, String>{
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey!,
                },
                validateStatus: (status) => status != null && status < 500,
              ),
              data: <String, dynamic>{'clientId': clientId},
            ),
            sessionGeneration);

        if (response.statusCode == 401 || response.statusCode == 403) {
          _setError(
            type: InstantShipmentErrorType.unauthorized,
            message: _text(
              'Your session is no longer valid. Please log in again.',
              'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
            ),
          );
          return;
        }

        if (response.data is! Map) {
          _setError(
            type: InstantShipmentErrorType.generic,
            message: _text(
              'Unable to load instant shipments right now.',
              'تعذر تحميل الشحنات الفورية حاليًا.',
            ),
          );
          return;
        }

        final data = Map<String, dynamic>.from(response.data as Map);
        if ((data['status']?.toString().toLowerCase() ?? '') != 'success') {
          _setError(
            type: InstantShipmentErrorType.generic,
            message: _messageFromData(
              data,
              fallback: _text(
                'Unable to load instant shipments right now.',
                'تعذر تحميل الشحنات الفورية حاليًا.',
              ),
            ),
          );
          return;
        }

        final parsed = ShipmentsResponse.fromJson(data);
        final instantOnly = parsed.shipments
            .where((shipment) => shipment.deliveryTypeId == 1)
            .toList(growable: false);

        shipmentInstantResponse = ShipmentsResponse(
          status: parsed.status,
          message: parsed.message,
          clientId: parsed.clientId,
          count: instantOnly.length,
          shipments: instantOnly,
        );

        _allShipments = instantOnly;
        _scheduleCancellationEligibilityChecks(
          instantOnly,
          sessionGeneration: sessionGeneration,
          epoch: eligibilityEpoch,
        );
        _hasLoaded = true;
        _applyFilters(notify: false);
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _setError(
          type: _resolveErrorType(error),
          message: _mapRequestError(error),
        );
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _setError(
          type: InstantShipmentErrorType.generic,
          message: _text(
            'Unable to load instant shipments right now.',
            'تعذر تحميل الشحنات الفورية حاليًا.',
          ),
        );
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> refresh() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(getShipmentsInstant(force: true), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  void setCurrentPage(int page) {
    if (page < 1 || page > totalPages || page == _currentPage) {
      return;
    }
    _currentPage = page;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized == _searchQuery) {
      return;
    }
    _searchQuery = normalized;
    _applyFilters(resetPage: true);
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) {
      return;
    }
    _searchQuery = '';
    _applyFilters(resetPage: true);
  }

  void setStatusFilter(InstantShipmentFilter filter) {
    if (filter == _selectedFilter) {
      return;
    }
    _selectedFilter = filter;
    _applyFilters(resetPage: true);
  }

  Future<InstantShipmentActionResult> cancelShipment(
    int shipmentId, {
    required int reasonId,
    String? note,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_busyShipmentIds.contains(shipmentId)) {
        return const InstantShipmentActionResult(
          success: false,
          message: 'Cancellation is already in progress.',
        );
      }

      final cancellationCheck = await revalidateCancellation(shipmentId);
      if (!cancellationCheck.eligible) {
        return InstantShipmentActionResult(
          success: false,
          message: _text(
            'This shipment can no longer be cancelled.',
            'لم يعد من الممكن إلغاء هذه الشحنة.',
          ),
        );
      }

      final shipment = _shipmentById(shipmentId);
      if (shipment == null) {
        return InstantShipmentActionResult(
          success: false,
          message: _text(
            'This shipment can no longer be cancelled.',
            'لم يعد من الممكن إلغاء هذه الشحنة.',
          ),
        );
      }

      if (reasonId <= 0) {
        return InstantShipmentActionResult(
          success: false,
          message: _text(
            'Please select a cancellation reason.',
            'يرجى اختيار سبب الإلغاء.',
          ),
        );
      }

      final clientId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);

      if (_isBlank(clientId?.toString()) || _isBlank(apiKey)) {
        return InstantShipmentActionResult(
          success: false,
          message: _text(
            'Your session is no longer valid. Please log in again.',
            'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
          ),
        );
      }

      _busyShipmentIds.add(shipmentId);
      notifyListeners();

      try {
        final response = await guardSession(
            _dio.post(
              AppUrls.cancelShipment,
              options: Options(
                headers: <String, String>{
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey!,
                },
                validateStatus: (status) => status != null && status < 500,
              ),
              data: <String, dynamic>{
                'shipment_id': shipmentId,
                'client_id': clientId,
                'reason_id': reasonId,
                if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
              },
            ),
            sessionGeneration);

        if (response.statusCode == 401 || response.statusCode == 403) {
          return InstantShipmentActionResult(
            success: false,
            message: _text(
              'Your session is no longer valid. Please log in again.',
              'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
            ),
          );
        }

        if (response.data is! Map) {
          return InstantShipmentActionResult(
            success: false,
            message: _text(
              'Unable to cancel this shipment right now.',
              'تعذر إلغاء هذه الشحنة حاليًا.',
            ),
          );
        }

        final data = Map<String, dynamic>.from(response.data as Map);
        if ((data['status']?.toString().toLowerCase() ?? '') == 'success') {
          final custodyHeld = _asBool(data['custody_held']);
          await guardSession(
              getShipmentsInstant(force: true), sessionGeneration);
          return InstantShipmentActionResult(
            success: true,
            driverCustodyHeld: custodyHeld &&
                InstantShipmentProgressHelper.hasAssignedDriver(shipment),
            message: _messageFromData(
              data,
              fallback: _text(
                'Shipment cancelled successfully.',
                'تم إلغاء الشحنة بنجاح.',
              ),
            ),
          );
        }

        return InstantShipmentActionResult(
          success: false,
          message: _messageFromData(
            data,
            fallback: _text(
              'Unable to cancel this shipment.',
              'تعذر إلغاء هذه الشحنة.',
            ),
          ),
        );
      } on DioException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return InstantShipmentActionResult(
          success: false,
          message: _mapRequestError(error),
        );
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return InstantShipmentActionResult(
          success: false,
          message: _text(
            'Unable to cancel this shipment right now.',
            'تعذر إلغاء هذه الشحنة حاليًا.',
          ),
        );
      } finally {
        if (acceptsState(sessionGeneration)) {
          _busyShipmentIds.remove(shipmentId);
          notifyListeners();
        }
      }
    } on SessionChanged {
      return const InstantShipmentActionResult(
          success: false, message: 'Session changed.');
    }
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  Shipment? _shipmentById(int shipmentId) {
    return _allShipments.cast<Shipment?>().firstWhere(
          (item) => item?.id == shipmentId,
          orElse: () => null,
        );
  }

  void _scheduleCancellationEligibilityChecks(
    List<Shipment> shipments, {
    required int sessionGeneration,
    required int epoch,
  }) {
    for (final shipment in shipments) {
      if (!ClientShipmentCancellationEligibility.isListEligible(shipment)) {
        continue;
      }
      unawaited(
        _loadCancellationEligibility(
          shipment.id,
          sessionGeneration: sessionGeneration,
          epoch: epoch,
        ),
      );
    }
  }

  Future<void> _loadCancellationEligibility(
    int shipmentId, {
    required int sessionGeneration,
    required int epoch,
  }) async {
    final details = await OrderServices.getOrderDetails(orderId: shipmentId);
    if (!acceptsState(sessionGeneration) ||
        epoch != _cancellationEligibilityEpoch) {
      return;
    }

    final shipment = _shipmentById(shipmentId);
    if (shipment == null ||
        !ClientShipmentCancellationEligibility.isListEligible(shipment)) {
      return;
    }

    final eligible = ClientShipmentCancellationEligibility.isDetailsEligible(
      shipmentId: shipmentId,
      response: details,
    );
    _setCancellationEligibility(shipmentId, eligible);
  }

  void _setCancellationEligibility(
    int shipmentId,
    bool eligible, {
    bool notify = true,
  }) {
    if (_cancellationEligibility[shipmentId] == eligible) {
      return;
    }
    _cancellationEligibility[shipmentId] = eligible;
    if (notify) {
      notifyListeners();
    }
  }

  void _applyFilters({bool resetPage = false, bool notify = true}) {
    var filtered = List<Shipment>.from(_allShipments);

    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((shipment) {
        final recipient = shipment.recipientName.toLowerCase();
        final policy = shipment.policyNum.toLowerCase();
        final statusEn = shipment.statusNameEn?.toLowerCase() ?? '';
        final statusAr = shipment.statusNameAr?.toLowerCase() ?? '';
        final driver = shipment.driverName?.toLowerCase() ?? '';
        return recipient.contains(searchLower) ||
            policy.contains(searchLower) ||
            statusEn.contains(searchLower) ||
            statusAr.contains(searchLower) ||
            driver.contains(searchLower);
      }).toList(growable: false);
    }

    filtered = filtered
        .where((shipment) => _matchesSelectedFilter(shipment, _selectedFilter))
        .toList(growable: false);

    _visibleShipments = filtered;

    final computedTotalPages = totalPages == 0 ? 1 : totalPages;
    if (resetPage) {
      _currentPage = 1;
    } else if (_currentPage > computedTotalPages) {
      _currentPage = computedTotalPages;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _matchesSelectedFilter(
    Shipment shipment,
    InstantShipmentFilter filter,
  ) {
    switch (filter) {
      case InstantShipmentFilter.all:
        return true;
      case InstantShipmentFilter.waiting:
        return _matchesWaiting(shipment);
      case InstantShipmentFilter.waitingDriver:
        return _matchesWaitingDriver(shipment);
      case InstantShipmentFilter.inDelivery:
        return _matchesInDelivery(shipment);
      case InstantShipmentFilter.completed:
        return _matchesCompleted(shipment);
      case InstantShipmentFilter.cancelled:
        return _matchesCancelled(shipment);
    }
  }

  bool _matchesWaiting(Shipment shipment) {
    return shipment.shipmentStatusId == 1 || shipment.shipmentStatusId == 2;
  }

  bool _matchesWaitingDriver(Shipment shipment) {
    return shipment.driverId == null &&
        !_isFinalStatus(shipment.shipmentStatusId);
  }

  bool _matchesInDelivery(Shipment shipment) {
    return shipment.driverId != null &&
        !_isFinalStatus(shipment.shipmentStatusId) &&
        !_matchesWaiting(shipment);
  }

  bool _matchesCompleted(Shipment shipment) {
    return _completedStatusIds.contains(shipment.shipmentStatusId);
  }

  bool _matchesCancelled(Shipment shipment) {
    return _cancelledStatusIds.contains(shipment.shipmentStatusId) ||
        shipment.shipmentStatus == 0;
  }

  bool _isFinalStatus(int statusId) => _finalStatusIds.contains(statusId);

  void _setError({
    required InstantShipmentErrorType type,
    required String message,
  }) {
    _hasLoaded = _hasLoaded || _allShipments.isNotEmpty;
    _hasError = true;
    _errorType = type;
    _errorMessage = message;
  }

  String _messageFromData(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final preferredKey =
        AppLocalizations.isArabic ? 'message_ar' : 'message_en';
    final fallbackKey = AppLocalizations.isArabic ? 'message_en' : 'message_ar';
    for (final key in <String>[preferredKey, 'message', fallbackKey, 'error']) {
      final message = data[key]?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  String _mapRequestError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return _text(
        'Unable to reach the server. Please try again.',
        'تعذر الوصول إلى الخادم. حاول مرة أخرى.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return _text(
        'Network connection failed. Please check your internet and try again.',
        'فشل الاتصال بالشبكة. تحقق من الإنترنت وحاول مرة أخرى.',
      );
    }

    final data = error.response?.data;
    if (data is Map) {
      return _messageFromData(
        Map<String, dynamic>.from(data),
        fallback: _text(
          'Unable to load instant shipments right now.',
          'تعذر تحميل الشحنات الفورية حاليًا.',
        ),
      );
    }

    return _text(
      'Unable to load instant shipments right now.',
      'تعذر تحميل الشحنات الفورية حاليًا.',
    );
  }

  String _text(String en, String ar) => AppLocalizations.isArabic ? ar : en;

  InstantShipmentErrorType _resolveErrorType(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    if (statusCode == 401 || statusCode == 403) {
      return InstantShipmentErrorType.unauthorized;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return InstantShipmentErrorType.network;
    }
    return InstantShipmentErrorType.generic;
  }

  bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  void markDriverRated({
    required int shipmentId,
    required int rating,
  }) {
    if (shipmentId <= 0 || _allShipments.isEmpty) {
      return;
    }

    _allShipments = _allShipments
        .map((shipment) => shipment.id == shipmentId
            ? shipment.copyWith(
                isDriverRated: true,
                canRateDriver: false,
                driverRating: rating,
              )
            : shipment)
        .toList(growable: false);

    if (shipmentInstantResponse != null) {
      shipmentInstantResponse = ShipmentsResponse(
        status: shipmentInstantResponse!.status,
        message: shipmentInstantResponse!.message,
        clientId: shipmentInstantResponse!.clientId,
        count: shipmentInstantResponse!.count,
        shipments: _allShipments,
      );
    }

    _applyFilters(notify: false);
    notifyListeners();
  }
}
