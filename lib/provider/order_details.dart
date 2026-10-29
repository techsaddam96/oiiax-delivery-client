import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/session_refresh_queue.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/services/order_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class OrderDetailsProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _orderDetails = null;
    _isLoading = false;
    _error = null;
    _currentOrderId = null;
  }

  OrderDetailsData? _orderDetails;
  bool _isLoading = false;
  String? _error;
  int? _currentOrderId;

  OrderDetailsData? get orderDetails => _orderDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentOrderId => _currentOrderId;

  String get currentStatus => _orderDetails?.currentStatus ?? '';

  int get currentStatusId => _orderDetails?.currentStatusId ?? 0;

  StatusTimeline? get currentStatusSnapshot =>
      _orderDetails?.currentStatusSnapshot;

  List<StatusTimeline> get statusTimeline =>
      _orderDetails?.statusTimeline ?? const <StatusTimeline>[];

  OrderDetailsProvider({Future<OrderDetailsResponse?> Function(int)? loader})
      : _loader =
            loader ?? ((id) => OrderServices.getOrderDetails(orderId: id));
  final Future<OrderDetailsResponse?> Function(int) _loader;
  late final _refreshQueue =
      SessionRefreshQueue(() => stateGeneration * 1000000 + _clearedEpoch);
  int _clearedEpoch = 0;

  Future<void> fetchOrderDetails(int orderId,
      {bool force = false, bool silent = false}) {
    final changed = _currentOrderId != orderId;
    if (!force && !changed && _orderDetails != null) return Future.value();
    if (changed) _orderDetails = null;
    _currentOrderId = orderId;
    return _refreshQueue.run(() => _fetchCurrent(silent: silent),
        trailing: force || changed);
  }

  Future<void> _fetchCurrent({required bool silent}) async {
    final epoch = stateGeneration;
    final clearEpoch = _clearedEpoch;
    final id = _currentOrderId;
    if (id == null) return;
    bool current() =>
        acceptsState(epoch) &&
        _currentOrderId == id &&
        _clearedEpoch == clearEpoch;
    _isLoading = !silent || _orderDetails == null;
    _error = null;
    notifyListeners();
    try {
      final response = await _loader(id);
      if (!current()) return;
      if (response?.success == true && response?.data.orderId == id) {
        // Replace the snapshot, including timeline; never append FCM status steps.
        _orderDetails = response!.data;
        _error = null;
      } else {
        _orderDetails = null;
        _error = 'LOAD_FAILED';
      }
    } catch (_) {
      if (!current()) return;
      _orderDetails = null;
      _error = 'LOAD_FAILED';
    } finally {
      if (current()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clearOrderDetails() {
    _clearedEpoch++;
    clearUserState();
    notifyListeners();
  }

  String getStatusMessage() {
    return currentStatusSnapshot?.localizedMessage(AppLocalizations.isRTL) ??
        '';
  }

  String getStatusSubMessage() {
    final totalCount = statusTimeline.length;
    return AppLocalizations.isRTL
        ? '$totalCount تحديثات مسجلة'
        : '$totalCount recorded updates';
  }

  Color getStatusColor() {
    return getStatusColorByType(currentStatusSnapshot?.typeColor ?? 'info');
  }

  String getTopImageByStatus(String? status) {
    switch ((status ?? currentStatus).toLowerCase()) {
      case 'completed':
      case 'delivered':
        return 'assets/images/order_delivered.png';
      case 'cancelled':
      case 'returned':
      case 'failed delivery':
        return 'assets/images/cancelled.png';
      case 'in transit':
      case 'out for delivery':
      case 'awaiting pickup':
        return 'assets/images/order_inprogress.png';
      default:
        return 'assets/images/order_pending.png';
    }
  }

  String getStatusCardIcon() {
    switch (currentStatus.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return 'assets/images/delivered.png';
      case 'cancelled':
      case 'returned':
      case 'failed delivery':
        return 'assets/images/cancelled.png';
      case 'in transit':
      case 'out for delivery':
      case 'awaiting pickup':
        return 'assets/images/inprogress.png';
      default:
        return 'assets/images/pending.png';
    }
  }

  Color getStatusColorByType(String typeColor) {
    switch (typeColor) {
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String getStatusIcon(String statusName) {
    switch (statusName) {
      case 'Processing':
        return 'assets/images/order_accep.png';
      case 'Dispatched':
      case 'Out for Delivery':
        return 'assets/images/delivery_partner.png';
      case 'In Transit':
        return 'assets/images/inprogress.png';
      case 'Delivered':
      case 'Completed':
        return 'assets/images/delivered.png';
      case 'Cancelled':
        return 'assets/images/cancelled.png';
      case 'Returned':
        return 'assets/images/return.png';
      case 'Failed Delivery':
        return 'assets/images/failed_del.png';
      case 'Pending':
      case 'Awaiting Pickup':
      default:
        return 'assets/images/pending.png';
    }
  }

  void markDriverRated(int rating) {
    final details = _orderDetails;
    if (details == null) {
      return;
    }

    _orderDetails = details.copyWith(
      isDriverRated: true,
      canRateDriver: false,
      driverRating: rating,
    );
    notifyListeners();
  }
}
