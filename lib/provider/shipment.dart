import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/session_refresh_queue.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:dio/dio.dart';

class ShipmentProvider extends UserScopedNotifier {
  ShipmentProvider({Dio? dio}) {
    if (dio != null) _dio = protectSessionDio(dio);
  }
  @override
  void clearUserState() {
    shipmentsResponse = null;
    isLoading = false;
    unreadCount = null;
    currentPage = 1;
    _searchQuery = '';
    _filteredShipments = [];
    _isSearching = false;
    _selectedCategory = categoryAll;
    _selectedDeliveryTypeId = null;
    _selectedShipmentStatusId = null;
    _selectedShipmentDate = null;
    _errorMessage = null;
    _errorCode = null;
    _hasLoaded = false;
  }

  static const String categoryAll = 'all';
  static const String categoryPending = 'pending';
  static const String categoryInProgress = 'in_progress';
  static const String categoryCompleted = 'completed';
  static const String categoryIssues = 'issues';

  Dio _dio = sessionDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  int currentPage = 1;
  final int itemsPerPage = 6;

  // Search functionality
  String _searchQuery = '';
  List<Shipment> _filteredShipments = [];
  bool _isSearching = false;
  String _selectedCategory = categoryAll;
  int? _selectedDeliveryTypeId;
  int? _selectedShipmentStatusId;
  DateTime? _selectedShipmentDate;
  String? _errorMessage;
  String? _errorCode;
  bool _hasLoaded = false;

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  List<Shipment> get filteredShipments => _filteredShipments;
  String get selectedCategory => _selectedCategory;
  int? get selectedDeliveryTypeId => _selectedDeliveryTypeId;
  int? get selectedShipmentStatusId => _selectedShipmentStatusId;
  DateTime? get selectedShipmentDate => _selectedShipmentDate;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get hasLoaded => _hasLoaded;
  int get totalCount => shipmentsResponse?.count ?? allShipments.length;
  int get visibleCount => displayShipments.length;
  bool get hasViewFilters =>
      _selectedDeliveryTypeId != null ||
      _selectedShipmentStatusId != null ||
      _selectedShipmentDate != null;
  List<Shipment> get allShipments =>
      shipmentsResponse?.shipments ?? const <Shipment>[];

  List<Shipment> get displayShipments {
    final baseShipments = _applyViewFilters(_searchBaseShipments);
    final categoryShipments = _applyCategoryFilter(baseShipments);
    return _prioritizePendingShipments(categoryShipments);
  }

  List<Shipment> get paginatedShipments {
    final shipments = displayShipments;
    if (shipments.isEmpty) {
      return const <Shipment>[];
    }

    return shipments
        .skip((currentPage - 1) * itemsPerPage)
        .take(itemsPerPage)
        .toList();
  }

  int get totalPages {
    final shipments = displayShipments;
    if (shipments.isEmpty) {
      return 0;
    }
    return (shipments.length / itemsPerPage).ceil();
  }

  int countForCategory(String category) {
    final shipments = _applyViewFilters(_searchBaseShipments);
    if (category == categoryAll) {
      return shipments.length;
    }
    return shipments
        .where((shipment) => _matchesCategory(shipment, category))
        .length;
  }

  void setPage(int page) {
    // Validate page number
    if (page < 1) return;
    if (page > totalPages) return;

    currentPage = page;
    notifyListeners();
  }

  void goToNextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      notifyListeners();
    }
  }

  void goToPrevPage() {
    if (currentPage > 1) {
      currentPage--;
      notifyListeners();
    }
  }

  // Search functionality
  void searchShipments(String query) {
    final normalizedQuery = query.trim();
    if (_searchQuery == normalizedQuery) {
      return;
    }

    _searchQuery = normalizedQuery;
    _isSearching = normalizedQuery.isNotEmpty;
    _applySearchResults();
    currentPage = 1;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _filteredShipments = [];
    currentPage = 1;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }
    _selectedCategory = category;
    currentPage = 1;
    notifyListeners();
  }

  void applyViewFilters({
    int? deliveryTypeId,
    int? shipmentStatusId,
    DateTime? shipmentDate,
  }) {
    final normalizedDate = shipmentDate == null
        ? null
        : DateTime(shipmentDate.year, shipmentDate.month, shipmentDate.day);

    final hasChanged = _selectedDeliveryTypeId != deliveryTypeId ||
        _selectedShipmentStatusId != shipmentStatusId ||
        !_isSameDate(_selectedShipmentDate, normalizedDate);

    if (!hasChanged) {
      return;
    }

    _selectedDeliveryTypeId = deliveryTypeId;
    _selectedShipmentStatusId = shipmentStatusId;
    _selectedShipmentDate = normalizedDate;
    currentPage = 1;
    notifyListeners();
  }

  void clearViewFilters() {
    final hadFilters = hasViewFilters;
    _selectedDeliveryTypeId = null;
    _selectedShipmentStatusId = null;
    _selectedShipmentDate = null;
    currentPage = 1;
    if (hadFilters) {
      notifyListeners();
    }
  }

  ShipmentsResponse? shipmentsResponse;

  bool isLoading = false;
  int? unreadCount;

  late final _refreshQueue = SessionRefreshQueue(() => stateGeneration);
  Future<void> getClientShipments({bool force = false, bool silent = false}) =>
      _refreshQueue.run(() => _fetchShipments(force: force, silent: silent),
          trailing: force);

  Future<void> _fetchShipments(
      {required bool force, required bool silent}) async {
    final sessionGeneration = stateGeneration;
    try {
      isLoading = !silent || !hasLoaded;
      _errorMessage = null;
      _errorCode = null;
      if (!hasLoaded || force) {
        notifyListeners();
      }

      try {
        final clientId =
            await guardSession(AuthService.getUserId(), sessionGeneration);
        final apiKey =
            await guardSession(AuthService.getApiKey(), sessionGeneration);

        if (clientId == null ||
            clientId.trim().isEmpty ||
            apiKey == null ||
            apiKey.trim().isEmpty) {
          isLoading = false;
          _errorCode = 'unauthorized';
          _errorMessage = 'Unauthorized';
          notifyListeners();
          return;
        }

        final response = await guardSession(
            _dio.post(
              AppUrls.getClientShipments,
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey,
                },
              ),
              data: {'clientId': clientId},
            ),
            sessionGeneration);

        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
          shipmentsResponse = ShipmentsResponse.fromJson(response.data);
          _hasLoaded = true;
          _errorMessage = null;
          _errorCode = null;

          // Apply current search if any
          if (_isSearching && _searchQuery.isNotEmpty) {
            _applySearchResults();
          }

          if (totalPages > 0 && currentPage > totalPages) {
            currentPage = totalPages;
          } else if (currentPage < 1) {
            currentPage = 1;
          }
        } else {
          final statusCode = response.statusCode ?? 0;
          _errorCode = statusCode == 401 || statusCode == 403
              ? 'unauthorized'
              : 'generic';
          _errorMessage = response.data['message']?.toString() ??
              'Failed to fetch shipments';
        }
      } on DioException catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          _errorCode = 'unauthorized';
          _errorMessage = 'Unauthorized';
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          _errorCode = 'network';
          _errorMessage = 'Network error';
        } else {
          _errorCode = 'generic';
          _errorMessage = 'Unable to load shipments';
        }
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorCode = 'generic';
        _errorMessage = 'Unable to load shipments';
      }

      isLoading = false;
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  void _applySearchResults() {
    if (!_isSearching || shipmentsResponse == null) {
      _filteredShipments = [];
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredShipments = shipmentsResponse!.shipments.where((shipment) {
      if (shipment.policyNum.toLowerCase().contains(query)) {
        return true;
      }

      if (shipment.recipientName.toLowerCase().contains(query)) {
        return true;
      }

      if (shipment.recipientPhone.contains(_searchQuery)) {
        return true;
      }

      if (shipment.id.toString().contains(_searchQuery)) {
        return true;
      }

      if ((shipment.barcode ?? '').toLowerCase().contains(query)) {
        return true;
      }

      final statusEn = shipment.statusNameEn?.toLowerCase() ?? '';
      if (statusEn.contains(query)) {
        return true;
      }

      final statusAr = shipment.statusNameAr?.toLowerCase() ?? '';
      if (statusAr.contains(query)) {
        return true;
      }

      final typeEn = shipment.typeNameEn?.toLowerCase() ?? '';
      if (typeEn.contains(query)) {
        return true;
      }

      final typeAr = shipment.typeNameAr?.toLowerCase() ?? '';
      if (typeAr.contains(query)) {
        return true;
      }

      return shipment.deliveryAddress.toLowerCase().contains(query);
    }).toList();
  }

  List<Shipment> get _searchBaseShipments {
    return _isSearching && _searchQuery.isNotEmpty
        ? _filteredShipments
        : allShipments;
  }

  List<Shipment> _applyViewFilters(List<Shipment> shipments) {
    return shipments.where((shipment) {
      if (_selectedDeliveryTypeId != null &&
          shipment.deliveryTypeId != _selectedDeliveryTypeId) {
        return false;
      }

      if (_selectedShipmentStatusId != null) {
        final statusId = shipment.shipmentStatusId != 0
            ? shipment.shipmentStatusId
            : shipment.shipmentStatus;
        if (statusId != _selectedShipmentStatusId) {
          return false;
        }
      }

      if (_selectedShipmentDate != null) {
        final shipmentDate = _resolveShipmentDate(shipment);
        if (shipmentDate == null ||
            shipmentDate.year != _selectedShipmentDate!.year ||
            shipmentDate.month != _selectedShipmentDate!.month ||
            shipmentDate.day != _selectedShipmentDate!.day) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Shipment> _applyCategoryFilter(List<Shipment> shipments) {
    if (_selectedCategory == categoryAll) {
      return shipments;
    }
    return shipments
        .where((shipment) => _matchesCategory(shipment, _selectedCategory))
        .toList();
  }

  List<Shipment> _prioritizePendingShipments(List<Shipment> shipments) {
    if (shipments.length < 2) {
      return shipments;
    }

    final pendingShipments = <Shipment>[];
    final remainingShipments = <Shipment>[];

    for (final shipment in shipments) {
      final statusId = shipment.shipmentStatusId != 0
          ? shipment.shipmentStatusId
          : shipment.shipmentStatus;
      if (statusId == 1 || statusId == 2 || statusId == 10) {
        pendingShipments.add(shipment);
      } else {
        remainingShipments.add(shipment);
      }
    }

    return [...pendingShipments, ...remainingShipments];
  }

  bool _matchesCategory(Shipment shipment, String category) {
    final statusId = shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;

    switch (category) {
      case categoryPending:
        return statusId == 1 || statusId == 2 || statusId == 10;
      case categoryInProgress:
        return statusId == 3 || statusId == 4 || statusId == 5;
      case categoryCompleted:
        return statusId == 6 || statusId == 11;
      case categoryIssues:
        return statusId == 7 || statusId == 8 || statusId == 9;
      default:
        return true;
    }
  }

  DateTime? _resolveShipmentDate(Shipment shipment) {
    final candidates = [
      shipment.shipmentDate.trim(),
      shipment.createdAt.trim(),
      shipment.updatedAt.trim(),
    ];

    for (final candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  bool _isSameDate(DateTime? first, DateTime? second) {
    if (identical(first, second)) {
      return true;
    }
    if (first == null || second == null) {
      return false;
    }
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> acceptShipment(String? shipmentId) async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading) return;

      isLoading = true;
      //  notifyListeners();

      try {
        final dio = sessionDio();

        final driverId =
            await guardSession(AuthService.getUserId(), sessionGeneration);
        final apiKey =
            await guardSession(AuthService.getApiKey(), sessionGeneration);

        if (driverId == null || apiKey == null) {
          isLoading = false;
          notifyListeners();
          return;
        }

        final response = await guardSession(
            dio.post(
              AppUrls.acceptShipment,
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey,
                },
              ),
              data: {
                'shipment_id': shipmentId,
                'driver_id': driverId,
              },
            ),
            sessionGeneration);

        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
        } else {
          AppUtils.errorToast(
              response.data['message'] ?? 'Failed to fetch notifications');
        }
      } catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        AppUtils.errorToast("Something went wrong");
      }

      isLoading = false;
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  void markDriverRated({
    required int shipmentId,
    required int rating,
  }) {
    if (shipmentId <= 0 || shipmentsResponse == null) {
      return;
    }

    final updatedShipments = shipmentsResponse!.shipments
        .map((shipment) => shipment.id == shipmentId
            ? shipment.copyWith(
                isDriverRated: true,
                canRateDriver: false,
                driverRating: rating,
              )
            : shipment)
        .toList(growable: false);

    shipmentsResponse = ShipmentsResponse(
      status: shipmentsResponse!.status,
      message: shipmentsResponse!.message,
      clientId: shipmentsResponse!.clientId,
      count: shipmentsResponse!.count,
      shipments: updatedShipments,
    );

    if (_isSearching && _searchQuery.isNotEmpty) {
      _applySearchResults();
    }

    notifyListeners();
  }
}
