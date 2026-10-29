import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/models/productsType_model.dart';
import 'package:blockatie/services/shipment_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';

class AddShipmentProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _isLoadingProducts = false;
    _isSubmitting = false;
    _errorMessage = null;
    _isSuccess = false;
    _lastCreatedShipment = null;
    _isRecipientNameValid = false;
    _isRecipientPhoneValid = false;
    _isDeliveryAddressValid = false;
    _isShipmentCostValid = false;
    _isRegionSelected = false;
    _isProductTypeSelected = false;
    _isDeliveryTypeSelected = false;
  }

  ProductsTypeData? productsType;

  bool _isLoadingProducts = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSuccess = false;
  Map<String, dynamic>? _lastCreatedShipment;

  bool _isRecipientNameValid = false;
  bool _isRecipientPhoneValid = false;
  bool _isDeliveryAddressValid = false;
  bool _isShipmentCostValid = false;
  bool _isRegionSelected = false;
  bool _isProductTypeSelected = false;
  bool _isDeliveryTypeSelected = false;

  bool get isLoading => _isLoadingProducts || _isSubmitting;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  Map<String, dynamic>? get lastCreatedShipment => _lastCreatedShipment;

  bool get isFormValid =>
      _isRecipientNameValid &&
      _isRecipientPhoneValid &&
      _isDeliveryAddressValid &&
      _isShipmentCostValid &&
      _isRegionSelected &&
      _isProductTypeSelected &&
      _isDeliveryTypeSelected;

  bool get isRecipientNameValid => _isRecipientNameValid;
  bool get isRecipientPhoneValid => _isRecipientPhoneValid;
  bool get isDeliveryAddressValid => _isDeliveryAddressValid;
  bool get isShipmentCostValid => _isShipmentCostValid;
  bool get isRegionSelected => _isRegionSelected;
  bool get isProductTypeSelected => _isProductTypeSelected;
  bool get isDeliveryTypeSelected => _isDeliveryTypeSelected;

  void validateRecipientName(String name) {
    _isRecipientNameValid = name.trim().length >= 2;
    notifyListeners();
  }

  void validateRecipientPhone(String phone) {
    _isRecipientPhoneValid = RegExp(r'^07[789]\d{7}$').hasMatch(phone.trim());
    notifyListeners();
  }

  void validateDeliveryAddress(String address) {
    _isDeliveryAddressValid = address.trim().length >= 8;
    notifyListeners();
  }

  /// COD needs a value to collect; prepaid has nothing to collect, so only 0 is valid.
  void validateShipmentCost(String cost, {bool prepaid = false}) {
    final parsedCost = double.tryParse(cost.trim());
    _isShipmentCostValid = parsedCost != null &&
        (prepaid ? parsedCost == 0 : parsedCost > 0);
    notifyListeners();
  }

  void setRegionSelected(bool selected) {
    _isRegionSelected = selected;
    notifyListeners();
  }

  void setProductTypeSelected(bool selected) {
    _isProductTypeSelected = selected;
    notifyListeners();
  }

  void setDeliveryTypeSelected(bool selected) {
    _isDeliveryTypeSelected = selected;
    notifyListeners();
  }

  Future<bool> getProductTypes({bool force = false}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoadingProducts) {
        return false;
      }

      if (!force &&
          productsType != null &&
          productsType!.productsTypes.isNotEmpty) {
        return true;
      }

      _isLoadingProducts = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final productsTypes = await guardSession(
            ShipmentService.getProductTypes(), sessionGeneration);
        productsType = productsTypes;
        _isLoadingProducts = false;
        notifyListeners();
        return true;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorMessage = error is ShipmentServiceException
            ? error.localizedMessage(AppLocalizations.isArabic)
            : error.toString();
        _isLoadingProducts = false;
        notifyListeners();
        return false;
      }
    } on SessionChanged {
      return false;
    }
  }

  void resetForm() {
    _isSubmitting = false;
    _errorMessage = null;
    _isSuccess = false;
    _lastCreatedShipment = null;
    _isRecipientNameValid = false;
    _isRecipientPhoneValid = false;
    _isDeliveryAddressValid = false;
    _isShipmentCostValid = false;
    _isRegionSelected = false;
    _isProductTypeSelected = false;
    _isDeliveryTypeSelected = false;
    notifyListeners();
  }

  Future<bool> addShipment({
    required String recipientName,
    required String recipientPhone,
    required int regionId,
    required String deliveryAddress,
    required String shipmentCost,
    required int productTypeId,
    required int deliveryTypeId,
    required DateTime shipmentDate,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? reference,
    int? piecesCount,
    String? note,
    String paymentType = 'cod',
    double? quotedDeliveryCost,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isSubmitting) {
        return false;
      }

      _isSubmitting = true;
      _errorMessage = null;
      _isSuccess = false;
      _lastCreatedShipment = null;
      notifyListeners();

      try {
        final result = await guardSession(
            ShipmentService.addShipment(
              recipientName: recipientName,
              recipientPhone: recipientPhone,
              regionId: regionId,
              deliveryAddress: deliveryAddress,
              shipmentCost: shipmentCost,
              productTypeId: productTypeId,
              deliveryTypeId: deliveryTypeId,
              shipmentDate: shipmentDate,
              deliveryLatitude: deliveryLatitude,
              deliveryLongitude: deliveryLongitude,
              reference: reference,
              piecesCount: piecesCount,
              note: note,
              paymentType: paymentType,
              quotedDeliveryCost: quotedDeliveryCost,
            ),
            sessionGeneration);

        _lastCreatedShipment = result;
        _isSuccess = true;
        _isSubmitting = false;
        notifyListeners();
        return true;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorMessage = error is ShipmentServiceException
            ? error.localizedMessage(AppLocalizations.isArabic)
            : error.toString();
        _isSubmitting = false;
        notifyListeners();
        rethrow;
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAllShipments() async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final shipments = await guardSession(
            ShipmentService.getAllShipments(), sessionGeneration);
        return {
          'success': true,
          'data': shipments,
        };
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return {
          'success': false,
          'error': error.toString(),
        };
      }
    } on SessionChanged {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getInstantShipments() async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final shipments = await guardSession(
            ShipmentService.getInstantShipments(), sessionGeneration);
        return {
          'success': true,
          'data': shipments,
        };
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return {
          'success': false,
          'error': error.toString(),
        };
      }
    } on SessionChanged {
      return null;
    }
  }

  Future<bool> cancelShipment({required int shipmentId}) async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        await guardSession(
            ShipmentService.cancelShipment(shipmentId: shipmentId),
            sessionGeneration);
        return true;
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return false;
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getShipmentStatus({
    required int shipmentId,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        return await guardSession(
            ShipmentService.getShipmentStatus(shipmentId: shipmentId),
            sessionGeneration);
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return {
          'success': false,
          'error': error.toString(),
        };
      }
    } on SessionChanged {
      return null;
    }
  }

  Future<Map<String, dynamic>?> filterShipments({
    int? driverId,
    String? shipmentDate,
    int? shipmentStatus,
    String? location,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final shipments = await guardSession(
            ShipmentService.filterShipments(
              driverId: driverId,
              shipmentDate: shipmentDate,
              shipmentStatus: shipmentStatus,
              location: location,
            ),
            sessionGeneration);
        return {
          'success': true,
          'data': shipments,
        };
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return {
          'success': false,
          'error': error.toString(),
        };
      }
    } on SessionChanged {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _isSuccess = false;
    _lastCreatedShipment = null;
    notifyListeners();
  }
}
