import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_urls.dart';
import '../models/drivers_model.dart';
import '../models/shipment.dart';
import '../models/status_shipment_model.dart';
import '../services/auth_services.dart';

class FilterProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    idDriver = null;
    shipmentStatus = 0;
    drivers = null;
    shipments = [];
    isLoading = false;
    isLoadingFilter = false;
    _errorMessage = null;
    dateController.clear();
    washington.clear();
    nameCustomer.clear();
    _selectedDate = DateTime.now();
    _selectedHour = 11;
    _selectedMinute = 0;
    _isAM = false;
  }

  static final Dio _dio = sessionDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  final TextEditingController dateController = TextEditingController();
  final TextEditingController washington = TextEditingController();
  final TextEditingController nameCustomer = TextEditingController();

  int? idDriver;
  int shipmentStatus = 0;
  DriverData? drivers;
  List<Shipment> shipments = [];
  StatusShipmentData? statusShipmentData;
  bool isLoading = false;
  bool isLoadingFilter = false;
  String? _errorMessage;

  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 11;
  int _selectedMinute = 0;
  bool _isAM = false;

  @override
  void dispose() {
    dateController.dispose();
    washington.dispose();
    nameCustomer.dispose();
    super.dispose();
  }

  String? get errorMessage => _errorMessage;
  bool get hasError =>
      _errorMessage != null && _errorMessage!.trim().isNotEmpty;
  DateTime get selectedDate => _selectedDate;
  int get selectedHour => _selectedHour;
  int get selectedMinute => _selectedMinute;
  bool get isAM => _isAM;

  String get formattedDate {
    final day = _selectedDate.day;
    final year = _selectedDate.year;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[_selectedDate.month - 1];
    return '$day $month, $year';
  }

  String get formattedTime =>
      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}';

  void restart() {
    idDriver = null;
    shipmentStatus = 0;
    _errorMessage = null;
    dateController.clear();
    washington.clear();
    nameCustomer.clear();
    _selectedDate = DateTime.now();
    _selectedHour = 11;
    _selectedMinute = 0;
    _isAM = false;
    shipments = [];
    notifyListeners();
  }

  void selectDate(int day) {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, day);
    dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    notifyListeners();
  }

  void selectStatusId(int id) {
    shipmentStatus = id;
    notifyListeners();
  }

  void previousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    notifyListeners();
  }

  void setHour(int hour) {
    _selectedHour = hour;
    notifyListeners();
  }

  void selectDriver(int? id) {
    idDriver = id;
    notifyListeners();
  }

  void setMinute(int minute) {
    _selectedMinute = minute;
    notifyListeners();
  }

  void toggleAMPM(bool isAM) {
    _isAM = isAM;
    notifyListeners();
  }

  void saveChanges() {
    // Filters are applied explicitly from the UI.
  }

  void discardChanges() {
    _selectedDate = DateTime.now();
    _selectedHour = 11;
    _selectedMinute = 0;
    _isAM = false;
    notifyListeners();
  }

  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  List<List<int?>> getCalendarDays() {
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final days = <int?>[];

    for (var i = 0; i < startWeekday; i++) {
      days.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      days.add(day);
    }

    final weeks = <List<int?>>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = <int?>[];
      for (var j = 0; j < 7; j++) {
        week.add(i + j < days.length ? days[i + j] : null);
      }
      weeks.add(week);
    }

    return weeks;
  }

  Future<DriverData> _getDrivers() async {
    final sessionGeneration = stateGeneration;
    try {
      final clientId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);

      if (clientId == null ||
          clientId.trim().isEmpty ||
          apiKey == null ||
          apiKey.trim().isEmpty) {
        throw Exception('Missing user ID or API key');
      }

      final response = await guardSession(
          _dio.get(
            AppUrls.getDrivers,
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-API-KEY': apiKey,
              },
            ),
            queryParameters: {
              'clientId': clientId,
            },
          ),
          sessionGeneration);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverData.fromJson(response.data);
      }

      throw Exception('Failed to fetch drivers');
    } on SessionChanged {
      throw const SessionChanged();
    }
  }

  Future<ShipmentsResponse> _filter({
    int? driverId,
    String? shipmentDate,
    int? shipmentStatus,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      final clientId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);

      if (clientId == null ||
          clientId.trim().isEmpty ||
          apiKey == null ||
          apiKey.trim().isEmpty) {
        throw Exception('Missing user ID or API key');
      }

      final response = await guardSession(
          _dio.post(
            AppUrls.shipmentFilter,
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-API-KEY': apiKey,
              },
            ),
            data: {
              if (driverId != null) 'driver_id': '$driverId',
              if (shipmentDate != null && shipmentDate.isNotEmpty)
                'shipment_date': shipmentDate,
              if (shipmentStatus != null) 'shipment_status': '$shipmentStatus',
            },
          ),
          sessionGeneration);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ShipmentsResponse.fromJson(response.data);
      }

      throw Exception('Failed to fetch shipments');
    } on SessionChanged {
      throw const SessionChanged();
    }
  }

  Future<StatusShipmentData> _getStatusShipment() async {
    final sessionGeneration = stateGeneration;
    try {
      final clientId =
          await guardSession(AuthService.getUserId(), sessionGeneration);
      final apiKey =
          await guardSession(AuthService.getApiKey(), sessionGeneration);

      if (clientId == null ||
          clientId.trim().isEmpty ||
          apiKey == null ||
          apiKey.trim().isEmpty) {
        throw Exception('Missing user ID or API key');
      }

      final response = await guardSession(
          _dio.get(
            AppUrls.getStatusShipment,
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-API-KEY': apiKey,
              },
            ),
          ),
          sessionGeneration);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return StatusShipmentData.fromJson(response.data);
      }

      throw Exception('Failed to fetch statuses');
    } on SessionChanged {
      throw const SessionChanged();
    }
  }

  Future<bool> getDrivers() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading) {
        return false;
      }

      isLoading = true;
      drivers = null;
      notifyListeners();

      try {
        drivers = await guardSession(_getDrivers(), sessionGeneration);
        return true;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<bool> getResultFilter() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoadingFilter) {
        return false;
      }

      shipments = [];
      _errorMessage = null;
      isLoadingFilter = true;
      notifyListeners();

      try {
        final result = await guardSession(
            _filter(
              driverId: idDriver,
              shipmentDate: dateController.text.trim(),
              shipmentStatus: shipmentStatus == 0 ? null : shipmentStatus,
            ),
            sessionGeneration);
        shipments = result.shipments;
        return true;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorMessage = 'Unable to load shipments';
        shipments = [];
        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoadingFilter = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<bool> getStatusShipment() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading) {
        return false;
      }

      isLoading = true;
      notifyListeners();

      try {
        statusShipmentData =
            await guardSession(_getStatusShipment(), sessionGeneration);
        return true;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return false;
    }
  }
}
