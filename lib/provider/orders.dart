import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:blockatie/services/user_session_state.dart';

class OrderStatusProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _currentStatus = 'Order Placed';
    _currentStatusIndex = 0;
    _inProgressSubState = 0;
  }

  String _currentStatus = 'Order Placed';
  int _currentStatusIndex = 0;
  int _inProgressSubState = 0; // 0: partner assigned, 1: out for delivery

  final List<String> _statuses = [
    'Pending',
    'Processing',
    'Dispatched',
    'In Transit',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
    'Returned',
    'Failed Delivery',
    'Awaiting Pickup',
    'Completed'
  ];

  String get currentStatus => _currentStatus;
  int get currentStatusIndex => _currentStatusIndex;
  int get inProgressSubState => _inProgressSubState;
  List<String> get statuses => _statuses;

  void updateStatus(String status) {
    int index = _statuses.indexOf(status);
    if (index != -1) {
      _currentStatus = status;
      _currentStatusIndex = index;
      notifyListeners();
    }
  }

  void updateStatusByIndex(int index) {
    if (index >= 0 && index < _statuses.length) {
      _currentStatus = _statuses[index];
      _currentStatusIndex = index;
      notifyListeners();
    }
  }

  void updateInProgressSubState(int subState) {
    if (_currentStatus == 'In Progress' && subState >= 0 && subState <= 1) {
      _inProgressSubState = subState;
      notifyListeners();
    }
  }

  bool isStatusActive(int index) {
    return index == _currentStatusIndex;
  }

  bool isStatusCompleted(int index) {
    return index < _currentStatusIndex;
  }

  bool isStatusClickable(int index) {
    // Allow clicking on current status, completed statuses, and next status
    return index <= _currentStatusIndex + 1 && index >= 0;
  }

  String getTopImageByStatus(String? orderstatus) {
    switch (orderstatus) {
      case 'Pending':
        return 'assets/images/order_pending.png';
      case 'Processing':
        return 'assets/images/order_processing.png';
      case 'Dispatched':
        return 'assets/images/order_dispatched.png';
      case 'In Transit':
        return 'assets/images/in_transit.png';
      case 'Out for Delivery':
        return 'assets/images/order_out_for_del.png';
      case 'Delivered':
        return 'assets/images/order_delivered.png';
      case 'Cancelled':
        return 'assets/images/cancelled.png';
      case 'Returned':
        return 'assets/images/returned.png';
      case 'Failed Delivery':
        return 'assets/images/failed_del.png';
      case 'Awaiting Pickup':
        return 'assets/images/awaiting_pickup.png';
      case 'Completed':
        return 'assets/images/order_completed.png';
      default:
        return 'assets/images/orderplaced.png';
    }
  }

  String getStatusMessage() {
    switch (_currentStatus) {
      case 'Pending':
        return 'Your Order is Pending';
      case 'Processing':
        return 'Order Order Is Processing';
      case 'Dispatched':
        return 'Your Order Is Dispatched';
      case 'In Transit':
        return 'Your Order Is In Transit';
      case 'Out for Delivery':
        return 'Your Order Is Out for Delivery';
      case 'Delivered':
        return 'Your order Is Delivered';
      case 'Cancelled':
        return 'Your Order Is Cancelled';
      case 'Returned':
        return 'Your Order Is Returned';
      case 'Failed Delivery':
        return 'Your Order Is Failed Delivery';
      case 'Awaiting Pickup':
        return 'Your order Is Awaiting Pickup';
      case 'Completed':
        return 'Your Order Is Completed';
      default:
        return 'Your Order has been Placed';
    }
  }

  String getStatusSubMessage() {
    switch (_currentStatus) {
      case 'Order Placed':
        return 'Waiting for store to accept the order';
      case 'Accepted':
        return 'Store will start preparing your order soon';
      case 'In Progress':
        return _inProgressSubState == 0
            ? 'Mr Saad will pick up your order from the store'
            : 'Mr Saad will reach your location soon!';
      case 'Delivered':
        return 'Mr Saad has delivered your order by 4:42PM';
      default:
        return 'Waiting for store to accept the order';
    }
  }

  // New method to get the appropriate icon for status card
  String getStatusCardIcon() {
    switch (_currentStatus) {
      case 'Order Placed':
        return 'assets/images/orderplace.png';
      case 'Accepted':
        return 'assets/images/order_accep.png';
      // case 'In Progress':
      //   return _inProgressSubState == 0
      //       ? 'assets/images/delivery_partner.png' // Icon for partner assigned
      //       : 'assets/images/insprogress.png'; // Icon for out for delivery
      // case 'Delivered':
      //   return 'assets/images/delivered.png';
      default:
        return 'assets/images/orderplace.png';
    }
  }

  // Method to handle call delivery partner and transition to next state
  void callDeliveryPartner() {
    if (_currentStatus == 'In Progress' && _inProgressSubState == 0) {
      _inProgressSubState = 1;
      notifyListeners();
    }
  }

  // // Method to get action buttons based on current state
  Widget? getActionButtons(BuildContext context) {
    if (_currentStatus == 'In Progress') {
      if (_inProgressSubState == 0) {
        // Partner assigned state - Single button
        return SizedBox(
          width: SizeConfig.widthMultiplier * 60,
          child: ElevatedButton.icon(
            onPressed: () {
              callDeliveryPartner();
            },
            icon: Image.asset(
              'assets/images/phone.png',
              width: 20,
              height: 20,
            ),
            label: const Text('Call Delivery Partner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      } else {
        // Out for delivery state - Two buttons
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Handle call partner
                  print('Calling partner...');
                },
                icon: Image.asset(
                  'assets/images/phone.png',
                  width: 20,
                  height: 20,
                  color: AppColors.primary,
                ),
                label: const Text('Call Partner'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle track order
                  print('Tracking order...');
                },
                icon: Image.asset(
                  'assets/images/track_order.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text('Track order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }
    return null;
  }
}
