import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:flutter/material.dart';

enum InstantShipmentVisualState { completed, active, pending, exception }

class InstantShipmentStage {
  const InstantShipmentStage({
    required this.key,
    required this.titleEn,
    required this.titleAr,
    required this.messageEn,
    required this.messageAr,
    required this.icon,
    required this.color,
    required this.state,
  });

  final String key;
  final String titleEn;
  final String titleAr;
  final String messageEn;
  final String messageAr;
  final IconData icon;
  final Color color;
  final InstantShipmentVisualState state;

  String title(bool isRtl) => isRtl ? titleAr : titleEn;

  String message(bool isRtl) => isRtl ? messageAr : messageEn;

  InstantShipmentStage copyWith({
    InstantShipmentVisualState? state,
    Color? color,
  }) {
    return InstantShipmentStage(
      key: key,
      titleEn: titleEn,
      titleAr: titleAr,
      messageEn: messageEn,
      messageAr: messageAr,
      icon: icon,
      color: color ?? this.color,
      state: state ?? this.state,
    );
  }
}

class InstantShipmentProgressHelper {
  const InstantShipmentProgressHelper._();

  static const int instantDeliveryTypeId = 1;
  static const Set<int> finalStatusIds = {6, 7, 8, 9, 11};

  static const Color waitingColor = Color(0xffF59E0B);
  static const Color activeColor = AppColors.primary;
  static const Color successColor = Color(0xff16A06D);
  static const Color dangerColor = Color(0xffDC2626);
  static const Color returnedColor = Color(0xffB45309);
  static const Color pendingColor = Color(0xff94A3B8);

  static bool isInstantShipment(Shipment shipment) =>
      isInstantShipmentByType(shipment.deliveryTypeId);

  static bool isInstantShipmentByType(int? deliveryTypeId) =>
      deliveryTypeId == instantDeliveryTypeId;

  static bool isFinalStatus(Shipment shipment) =>
      isFinalStatusId(effectiveStatusId(shipment));

  static bool isFinalStatusId(int? statusId) =>
      statusId != null && finalStatusIds.contains(statusId);

  static int effectiveStatusId(Shipment shipment) {
    return shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;
  }

  static bool hasAssignedDriver(Shipment shipment) {
    return hasAssignedDriverFromValues(
      driverId: shipment.driverId,
      driverName: shipment.driverName,
    );
  }

  static bool hasAssignedDriverFromValues({
    required int? driverId,
    String? driverName,
  }) {
    return (driverId != null && driverId > 0) ||
        (driverName != null && driverName.trim().isNotEmpty);
  }

  static bool isWaitingForDriver(Shipment shipment) {
    return isWaitingForDriverFromValues(
      deliveryTypeId: shipment.deliveryTypeId,
      driverId: shipment.driverId,
      driverName: shipment.driverName,
      statusId: effectiveStatusId(shipment),
    );
  }

  static bool isWaitingForDriverFromValues({
    required int? deliveryTypeId,
    required int? driverId,
    String? driverName,
    required int? statusId,
  }) {
    return isInstantShipmentByType(deliveryTypeId) &&
        !hasAssignedDriverFromValues(
          driverId: driverId,
          driverName: driverName,
        ) &&
        !isFinalStatusId(statusId);
  }

  static InstantShipmentStage currentStage(Shipment shipment) {
    return currentStageFromValues(
      deliveryTypeId: shipment.deliveryTypeId,
      driverId: shipment.driverId,
      driverName: shipment.driverName,
      statusId: effectiveStatusId(shipment),
    );
  }

  static InstantShipmentStage currentStageFromValues({
    required int? deliveryTypeId,
    required int? driverId,
    String? driverName,
    required int? statusId,
  }) {
    if (!isInstantShipmentByType(deliveryTypeId)) {
      return _regularStage(statusId);
    }

    if (statusId == 7) return _cancelledStage;
    if (statusId == 8) return _returnedStage;
    if (statusId == 9) return _failedStage;
    if (statusId == 6 || statusId == 11) {
      return statusId == 11 ? _deliveredClosedStage : _baseStages[6];
    }

    if (isWaitingForDriverFromValues(
      deliveryTypeId: deliveryTypeId,
      driverId: driverId,
      driverName: driverName,
      statusId: statusId,
    )) {
      return _baseStages[1];
    }

    switch (statusId) {
      case 10:
        return _baseStages[3];
      case 4:
      case 5:
        return _baseStages[5];
      case 2:
      case 3:
      case 1:
      default:
        return _baseStages[2];
    }
  }

  static List<InstantShipmentStage> timeline(Shipment shipment) {
    return timelineFromValues(
      deliveryTypeId: shipment.deliveryTypeId,
      driverId: shipment.driverId,
      driverName: shipment.driverName,
      statusId: effectiveStatusId(shipment),
    );
  }

  static List<InstantShipmentStage> timelineFromValues({
    required int? deliveryTypeId,
    required int? driverId,
    String? driverName,
    required int? statusId,
  }) {
    if (!isInstantShipmentByType(deliveryTypeId)) {
      return const <InstantShipmentStage>[];
    }

    final activeIndex = _activeStageIndex(
      deliveryTypeId: deliveryTypeId,
      driverId: driverId,
      driverName: driverName,
      statusId: statusId,
    );
    final isSuccessFinal = statusId == 6 || statusId == 11;
    final isException = statusId == 7 || statusId == 8 || statusId == 9;

    return List<InstantShipmentStage>.generate(_baseStages.length, (index) {
      final stage = _baseStages[index];
      if (isException) {
        return stage.copyWith(
          state: index == 0
              ? InstantShipmentVisualState.completed
              : InstantShipmentVisualState.pending,
          color: index == 0 ? successColor : pendingColor,
        );
      }
      if (isSuccessFinal && index <= 6) {
        return stage.copyWith(
          state: index == 6
              ? InstantShipmentVisualState.active
              : InstantShipmentVisualState.completed,
          color: index == 6 ? successColor : successColor,
        );
      }
      if (index < activeIndex) {
        return stage.copyWith(
          state: InstantShipmentVisualState.completed,
          color: successColor,
        );
      }
      if (index == activeIndex) {
        return stage.copyWith(state: InstantShipmentVisualState.active);
      }
      return stage.copyWith(
        state: InstantShipmentVisualState.pending,
        color: pendingColor,
      );
    });
  }

  static int _activeStageIndex({
    required int? deliveryTypeId,
    required int? driverId,
    String? driverName,
    required int? statusId,
  }) {
    if (isWaitingForDriverFromValues(
      deliveryTypeId: deliveryTypeId,
      driverId: driverId,
      driverName: driverName,
      statusId: statusId,
    )) {
      return 1;
    }
    switch (statusId) {
      case 10:
        return 3;
      case 4:
      case 5:
        return 5;
      case 6:
      case 11:
        return 6;
      case 2:
      case 3:
      case 1:
      default:
        return 2;
    }
  }

  static InstantShipmentStage _regularStage(int? statusId) {
    if (statusId == 6 || statusId == 11) return _deliveredClosedStage;
    if (statusId == 7) return _cancelledStage;
    if (statusId == 8) return _returnedStage;
    if (statusId == 9) return _failedStage;
    return const InstantShipmentStage(
      key: 'regular_in_progress',
      titleEn: 'In progress',
      titleAr: '\u0642\u064A\u062F \u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629',
      messageEn: 'Shipment is moving through the standard delivery flow.',
      messageAr:
          '\u0627\u0644\u0634\u062D\u0646\u0629 \u062A\u062A\u0642\u062F\u0645 \u0636\u0645\u0646 \u0645\u0633\u0627\u0631 \u0627\u0644\u062A\u0648\u0635\u064A\u0644.',
      icon: Icons.local_shipping_outlined,
      color: activeColor,
      state: InstantShipmentVisualState.active,
    );
  }

  static const List<InstantShipmentStage> _baseStages = [
    InstantShipmentStage(
      key: 'created',
      titleEn: 'Shipment created',
      titleAr: '\u062A\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0634\u062D\u0646\u0629',
      messageEn: 'Your instant shipment request was created successfully.',
      messageAr:
          '\u062A\u0645 \u0625\u0646\u0634\u0627\u0621 \u0637\u0644\u0628 \u0627\u0644\u0634\u062D\u0646\u0629 \u0627\u0644\u0641\u0648\u0631\u064A\u0629 \u0628\u0646\u062C\u0627\u062D.',
      icon: Icons.add_task_rounded,
      color: successColor,
      state: InstantShipmentVisualState.completed,
    ),
    InstantShipmentStage(
      key: 'waiting_driver',
      titleEn: 'Waiting for driver',
      titleAr: '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0633\u0627\u0626\u0642',
      messageEn: 'We are assigning the nearest eligible driver.',
      messageAr:
          '\u0646\u0642\u0648\u0645 \u0628\u062A\u0639\u064A\u064A\u0646 \u0623\u0642\u0631\u0628 \u0633\u0627\u0626\u0642 \u0645\u0646\u0627\u0633\u0628.',
      icon: Icons.person_search_rounded,
      color: waitingColor,
      state: InstantShipmentVisualState.active,
    ),
    InstantShipmentStage(
      key: 'heading_store',
      titleEn: 'Driver heading to store',
      titleAr:
          '\u0627\u0644\u0633\u0627\u0626\u0642 \u0645\u062A\u062C\u0647 \u0625\u0644\u0649 \u0627\u0644\u0645\u062A\u062C\u0631',
      messageEn: 'The driver is on the way to your store for pickup.',
      messageAr:
          '\u0627\u0644\u0633\u0627\u0626\u0642 \u0641\u064A \u0627\u0644\u0637\u0631\u064A\u0642 \u0625\u0644\u0649 \u0645\u062A\u062C\u0631\u0643 \u0644\u0627\u0633\u062A\u0644\u0627\u0645 \u0627\u0644\u0634\u062D\u0646\u0629.',
      icon: Icons.near_me_outlined,
      color: activeColor,
      state: InstantShipmentVisualState.active,
    ),
    InstantShipmentStage(
      key: 'arrived_store',
      titleEn: 'Driver arrived at store',
      titleAr:
          '\u0648\u0635\u0644 \u0627\u0644\u0633\u0627\u0626\u0642 \u0625\u0644\u0649 \u0627\u0644\u0645\u062A\u062C\u0631',
      messageEn: 'The driver has reached the store and is ready for pickup.',
      messageAr:
          '\u0648\u0635\u0644 \u0627\u0644\u0633\u0627\u0626\u0642 \u0625\u0644\u0649 \u0627\u0644\u0645\u062A\u062C\u0631 \u0648\u064A\u0646\u062A\u0638\u0631 \u0627\u0633\u062A\u0644\u0627\u0645 \u0627\u0644\u0634\u062D\u0646\u0629.',
      icon: Icons.storefront_outlined,
      color: activeColor,
      state: InstantShipmentVisualState.active,
    ),
    InstantShipmentStage(
      key: 'picked_up',
      titleEn: 'Shipment picked up',
      titleAr: '\u062A\u0645 \u0627\u0633\u062A\u0644\u0627\u0645 \u0627\u0644\u0634\u062D\u0646\u0629',
      messageEn: 'The shipment has been picked up from the store.',
      messageAr:
          '\u062A\u0645 \u0627\u0633\u062A\u0644\u0627\u0645 \u0627\u0644\u0634\u062D\u0646\u0629 \u0645\u0646 \u0627\u0644\u0645\u062A\u062C\u0631.',
      icon: Icons.inventory_2_outlined,
      color: activeColor,
      state: InstantShipmentVisualState.active,
    ),
    InstantShipmentStage(
      key: 'out_for_delivery',
      titleEn: 'Out for delivery',
      titleAr: '\u0642\u064A\u062F \u0627\u0644\u062A\u0648\u0635\u064A\u0644',
      messageEn: 'The driver is heading to the recipient.',
      messageAr:
          '\u0627\u0644\u0633\u0627\u0626\u0642 \u0645\u062A\u062C\u0647 \u0625\u0644\u0649 \u0627\u0644\u0645\u0633\u062A\u0644\u0645.',
      icon: Icons.local_shipping_outlined,
      color: activeColor,
      state: InstantShipmentVisualState.active,
    ),
    InstantShipmentStage(
      key: 'delivered',
      titleEn: 'Delivered',
      titleAr: '\u062A\u0645 \u0627\u0644\u062A\u0633\u0644\u064A\u0645',
      messageEn: 'Shipment was delivered successfully.',
      messageAr:
          '\u062A\u0645 \u062A\u0633\u0644\u064A\u0645 \u0627\u0644\u0634\u062D\u0646\u0629 \u0628\u0646\u062C\u0627\u062D.',
      icon: Icons.verified_rounded,
      color: successColor,
      state: InstantShipmentVisualState.active,
    ),
  ];

  static const InstantShipmentStage _deliveredClosedStage =
      InstantShipmentStage(
    key: 'completed',
    titleEn: 'Delivered and closed',
    titleAr:
        '\u062A\u0645 \u0627\u0644\u062A\u0633\u0644\u064A\u0645 \u0648\u0625\u063A\u0644\u0627\u0642 \u0627\u0644\u0634\u062D\u0646\u0629',
    messageEn: 'Shipment was delivered and closed.',
    messageAr:
        '\u062A\u0645 \u062A\u0633\u0644\u064A\u0645 \u0627\u0644\u0634\u062D\u0646\u0629 \u0648\u0625\u063A\u0644\u0627\u0642\u0647\u0627.',
    icon: Icons.verified_rounded,
    color: successColor,
    state: InstantShipmentVisualState.active,
  );

  static const InstantShipmentStage _cancelledStage = InstantShipmentStage(
    key: 'cancelled',
    titleEn: 'Cancelled',
    titleAr: '\u0645\u0644\u063A\u0627\u0629',
    messageEn: 'Shipment was cancelled.',
    messageAr: '\u062A\u0645 \u0625\u0644\u063A\u0627\u0621 \u0627\u0644\u0634\u062D\u0646\u0629.',
    icon: Icons.cancel_outlined,
    color: dangerColor,
    state: InstantShipmentVisualState.exception,
  );

  static const InstantShipmentStage _returnedStage = InstantShipmentStage(
    key: 'returned',
    titleEn: 'Returned',
    titleAr: '\u0631\u0627\u062C\u0639\u0629',
    messageEn: 'Shipment was returned.',
    messageAr: '\u062A\u0645 \u0625\u0631\u062C\u0627\u0639 \u0627\u0644\u0634\u062D\u0646\u0629.',
    icon: Icons.assignment_return_outlined,
    color: returnedColor,
    state: InstantShipmentVisualState.exception,
  );

  static const InstantShipmentStage _failedStage = InstantShipmentStage(
    key: 'failed',
    titleEn: 'Failed delivery',
    titleAr: '\u0641\u0634\u0644 \u0627\u0644\u062A\u0633\u0644\u064A\u0645',
    messageEn: 'Delivery could not be completed.',
    messageAr:
        '\u0644\u0645 \u064A\u062A\u0645 \u0625\u0643\u0645\u0627\u0644 \u062A\u0633\u0644\u064A\u0645 \u0627\u0644\u0634\u062D\u0646\u0629.',
    icon: Icons.error_outline_rounded,
    color: dangerColor,
    state: InstantShipmentVisualState.exception,
  );
}
