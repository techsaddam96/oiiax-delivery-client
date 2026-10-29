import 'dart:math' as math;

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/models/shipment_financial.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/provider/order_details.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/services/shipment_details_sync.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/instant_shipment_progress.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:blockatie/utils/shipment_chat_navigation.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_bottom_sheet.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_button.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_display.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage(
      {super.key,
      this.orderId,
      this.orderStatus,
      this.detailsLoader,
      this.chatRepository});

  final int? orderId;
  final String? orderStatus;
  final ChatRepository? chatRepository;
  final Future<OrderDetailsResponse?> Function(int)? detailsLoader;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with WidgetsBindingObserver {
  late ShipmentDetailsSync _sync;
  late final OrderDetailsProvider _orderProvider;
  late final ShipmentChatNavigation _chatNavigation;
  bool get _openingShipmentChat => _chatNavigation.isOpening;

  @override
  void initState() {
    super.initState();
    _orderProvider = OrderDetailsProvider(loader: widget.detailsLoader);
    _chatNavigation = ShipmentChatNavigation(repository: widget.chatRepository)
      ..addListener(_chatOpeningChanged);
    WidgetsBinding.instance.addObserver(this);
    _sync = _createSync();
    _fetchCurrentShipment();
  }

  ShipmentDetailsSync _createSync() => ShipmentDetailsSync(
        shipmentId: widget.orderId ?? 0,
        visible: () {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
            return false;
          }
          final overlay = context.read<BottomNavProvider>().overlayPage;
          return overlay == null || identical(overlay, widget);
        },
        refresh: () => _orderProvider.fetchOrderDetails(widget.orderId!,
            force: true, silent: true),
      );

  void _fetchCurrentShipment() {
    final orderId = widget.orderId;
    if (orderId != null && orderId > 0) {
      _orderProvider.fetchOrderDetails(orderId);
    }
  }

  @override
  void didUpdateWidget(covariant OrderDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _sync.dispose();
      _chatNavigation.resetUserState();
      _orderProvider.clearOrderDetails();
      _sync = _createSync();
      _fetchCurrentShipment();
    }
  }

  @override
  void dispose() {
    _sync.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _orderProvider.dispose();
    _chatNavigation.removeListener(_chatOpeningChanged);
    _chatNavigation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sync.foreground = state == AppLifecycleState.resumed;
    if (_sync.foreground) _sync.refreshIfVisible();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppLocalizations.languageNotifier,
        builder: (context, _) => _buildLocalizedPage(context),
      );

  Widget _buildLocalizedPage(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return ChangeNotifierProvider.value(
      value: _orderProvider,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.bgColor,
          body: SafeArea(
            bottom: false,
            child: Consumer<OrderDetailsProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return _DetailsLoadingState(
                    onBack: () => Navigator.maybePop(context),
                  );
                }

                if (orderProvider.error != null) {
                  return _DetailsErrorState(
                    message: _copy(
                      isRtl,
                      'Unable to load shipment details. Please try again.',
                      '\u062A\u0639\u0630\u0631 \u062A\u062D\u0645\u064A\u0644 \u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0634\u062D\u0646\u0629. \u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649.',
                    ),
                    onRetry: _retryFetch,
                  );
                }

                final orderDetails = orderProvider.orderDetails;
                if (orderDetails == null) {
                  return _DetailsErrorState(
                    icon: Icons.inventory_2_outlined,
                    message: _copy(
                      isRtl,
                      'Shipment was not found or you do not have permission to view it.',
                      '\u0644\u0645 \u064A\u062A\u0645 \u0627\u0644\u0639\u062B\u0648\u0631 \u0639\u0644\u0649 \u0627\u0644\u0634\u062D\u0646\u0629 \u0623\u0648 \u0644\u0627 \u062A\u0645\u0644\u0643 \u0635\u0644\u0627\u062D\u064A\u0629 \u0639\u0631\u0636\u0647\u0627.',
                    ),
                    onRetry: _retryFetch,
                  );
                }

                return _ShipmentDetailsContent(
                  orderDetails: orderDetails,
                  provider: orderProvider,
                  onBack: () => Navigator.maybePop(context),
                  onCallCustomer: () =>
                      _callPhone(orderDetails.details.recipientPhone),
                  onCallDriver: orderDetails.driver.id > 0
                      ? () => _callPhone(orderDetails.driver.phone)
                      : null,
                  onTrackDriver: orderDetails.driver.id > 0
                      ? () => _trackOrder(orderDetails.driver)
                      : null,
                  onRateDriver: orderDetails.canRateDriver
                      ? () => _openDriverRatingSheet(orderDetails)
                      : null,
                  onContactSupport: _openShipmentChat,
                  isOpeningShipmentChat: _openingShipmentChat,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _retryFetch() {
    final orderId = widget.orderId;
    if (orderId != null && orderId > 0) {
      _orderProvider.fetchOrderDetails(orderId);
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final phone = phoneNumber.trim();
    if (phone.isEmpty) {
      AppUtils.showWarningDialog(
        _copy(
          AppLocalizations.isRTL,
          'Phone number is not available.',
          '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 \u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631.',
        ),
      );
      return;
    }

    final phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      return;
    }

    AppUtils.showErrorDialog(
      AppTranslations.getText('could_not_launch_phone_app'),
    );
  }

  Future<void> _trackOrder(Driver driver) async {
    final orderDetails = _orderProvider.orderDetails;
    if (orderDetails == null) {
      AppUtils.showWarningDialog(
        AppTranslations.getText('error_tracking_order'),
      );
      return;
    }

    final driverLat = double.tryParse(driver.latitude);
    final driverLng = double.tryParse(driver.longitude);

    if (driver.locationState == 'stale') {
      AppUtils.showWarningDialog(
        _copy(
          AppLocalizations.isRTL,
          'The driver location is temporarily stale. Please try again shortly.',
          'موقع السائق قديم مؤقتاً. يرجى المحاولة بعد قليل.',
        ),
      );
      return;
    }

    if (driver.locationState != 'live' ||
        !_isValidCoordinate(driverLat, driverLng)) {
      AppUtils.showWarningDialog(
        AppTranslations.getText('driver_location_not_available'),
      );
      return;
    }

    final trackingTarget = _resolveTrackingTarget(orderDetails);
    if (trackingTarget == null) {
      AppUtils.showWarningDialog(
        AppTranslations.getText('location_not_available'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderRouteMapPage(
          driverName: _safeValue(
            driver.name,
            fallback: _copy(
              AppLocalizations.isRTL,
              'Driver',
              '\u0627\u0644\u0633\u0627\u0626\u0642',
            ),
          ),
          driverLocation: LatLng(driverLat!, driverLng!),
          targetLocation: trackingTarget.location,
          targetTitle: trackingTarget.title,
          targetSubtitle: trackingTarget.subtitle,
          relationLabel: trackingTarget.relationLabel,
          orderDetails: orderDetails,
        ),
      ),
    );
  }

  Future<void> _openDriverRatingSheet(OrderDetailsData orderDetails) async {
    if (orderDetails.driver.id <= 0) {
      return;
    }

    final result = await showModalBottomSheet<DriverRatingBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DriverRatingBottomSheet(
        driverName: orderDetails.driver.name,
        driverAvatar: orderDetails.driver.avatar,
        onSubmit: (rating, comment) {
          return DriverRatingService.submitDriverRating(
            shipmentId: orderDetails.orderId,
            rating: rating,
            comment: comment,
          );
        },
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final ratedShipmentId = result.shipmentId ?? orderDetails.orderId;
    if (ratedShipmentId > 0) {
      _orderProvider.markDriverRated(result.rating);
      context.read<ShipmentProvider>().markDriverRated(
            shipmentId: ratedShipmentId,
            rating: result.rating,
          );
      context.read<ShipmentInstantprovider>().markDriverRated(
            shipmentId: ratedShipmentId,
            rating: result.rating,
          );
    }

    AppUtils.showSuccessDialog(result.message);
  }

  void _chatOpeningChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openShipmentChat() async {
    final details = _orderProvider.orderDetails;
    if (details == null) return;
    await _chatNavigation.open(
      context,
      shipmentId: details.orderId,
      details: details,
      isCurrent: () =>
          mounted &&
          widget.orderId == details.orderId &&
          _orderProvider.orderDetails?.orderId == details.orderId,
    );
  }

  _TrackingTarget? _resolveTrackingTarget(OrderDetailsData orderDetails) {
    final status = _orderProvider.currentStatusId;
    final isInstantShipment =
        InstantShipmentProgressHelper.isInstantShipmentByType(
      orderDetails.details.deliveryType.id,
    );
    final isAfterPickupForInstant =
        isInstantShipment && !const {1, 2, 3, 10}.contains(status);

    if (isAfterPickupForInstant) {
      final customerLat = orderDetails.details.deliveryLatitude;
      final customerLng = orderDetails.details.deliveryLongitude;
      if (_isValidCoordinate(customerLat, customerLng)) {
        return _TrackingTarget(
          location: LatLng(customerLat!, customerLng!),
          title: _copy(
            AppLocalizations.isRTL,
            'Customer location',
            'موقع العميل',
          ),
          subtitle: _safeValue(
            orderDetails.details.deliveryAddress,
            fallback: _notAvailable(AppLocalizations.isRTL),
          ),
          relationLabel: _copy(
            AppLocalizations.isRTL,
            'Driver to customer',
            'السائق إلى العميل',
          ),
        );
      }
    }

    final storeLat = orderDetails.store.latitude;
    final storeLng = orderDetails.store.longitude;
    if (_isValidCoordinate(storeLat, storeLng)) {
      return _TrackingTarget(
        location: LatLng(storeLat!, storeLng!),
        title: _copy(
          AppLocalizations.isRTL,
          'Store location',
          'موقع المتجر',
        ),
        subtitle: _safeValue(
          orderDetails.store.address,
          fallback: _notAvailable(AppLocalizations.isRTL),
        ),
        relationLabel: _copy(
          AppLocalizations.isRTL,
          'Driver to store',
          isAfterPickupForInstant ? 'السائق إلى العميل' : 'السائق إلى المتجر',
        ),
      );
    }

    final customerLat = orderDetails.details.deliveryLatitude;
    final customerLng = orderDetails.details.deliveryLongitude;
    if (_isValidCoordinate(customerLat, customerLng)) {
      return _TrackingTarget(
        location: LatLng(customerLat!, customerLng!),
        title: _copy(
          AppLocalizations.isRTL,
          'Customer location',
          'موقع العميل',
        ),
        subtitle: _safeValue(
          orderDetails.details.deliveryAddress,
          fallback: _notAvailable(AppLocalizations.isRTL),
        ),
        relationLabel: _copy(
          AppLocalizations.isRTL,
          'Driver to customer',
          'السائق إلى العميل',
        ),
      );
    }

    return null;
  }
}

class _ShipmentDetailsContent extends StatelessWidget {
  const _ShipmentDetailsContent({
    required this.orderDetails,
    required this.provider,
    required this.onBack,
    required this.onCallCustomer,
    required this.onCallDriver,
    required this.onTrackDriver,
    required this.onRateDriver,
    required this.onContactSupport,
    required this.isOpeningShipmentChat,
  });

  final OrderDetailsData orderDetails;
  final OrderDetailsProvider provider;
  final VoidCallback onBack;
  final VoidCallback onCallCustomer;
  final VoidCallback? onCallDriver;
  final VoidCallback? onTrackDriver;
  final VoidCallback? onRateDriver;
  final VoidCallback onContactSupport;
  final bool isOpeningShipmentChat;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final currentStatus = provider.currentStatusSnapshot!;
    final currentStatusId = currentStatus.statusId;
    final isInstantShipment = orderDetails.details.deliveryType.id ==
        InstantShipmentProgressHelper.instantDeliveryTypeId;
    final instantStage = InstantShipmentProgressHelper.currentStageFromValues(
      deliveryTypeId: orderDetails.details.deliveryType.id,
      driverId: orderDetails.driver.id,
      statusId: currentStatusId,
    );
    final statusColor = isInstantShipment
        ? instantStage.color
        : _statusColor(currentStatusId, currentStatus.typeColor);
    final waitingForDriver = _isWaitingForDriver(orderDetails, currentStatusId);
    final hasDriver = orderDetails.driver.id > 0;
    final statusLabel = currentStatus.localizedName(isRtl);
    final canTrackDriver = _canTrackDriverFromStore(
      orderDetails: orderDetails,
      currentStatusId: currentStatusId,
    );
    final isFinalShipment = _isFinalStatus(currentStatusId);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.fetchOrderDetails(
        orderDetails.orderId,
        force: true,
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DriverStyleTopBar(
              title: _copy(isRtl, 'Shipment Details',
                  '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0634\u062D\u0646\u0629'),
              subtitle: _formatDate(orderDetails.placedAt),
              onBack: onBack,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              156 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _DriverStyleHeaderCard(
                    policyNumber: _safeValue(
                      orderDetails.details.policyNumber,
                      fallback: '#${orderDetails.orderId}',
                    ),
                    deliveryType: _deliveryTypeLabel(orderDetails),
                    statusLabel: statusLabel,
                    statusColor: statusColor,
                  ),
                  const SizedBox(height: 14),
                  _DriverStyleStepCard(
                    title: statusLabel,
                    message: currentStatus.localizedMessage(isRtl),
                    icon: isInstantShipment
                        ? instantStage.icon
                        : _stepIcon(
                            waitingForDriver: waitingForDriver,
                            hasDriver: hasDriver,
                            statusId: currentStatusId,
                          ),
                    color: statusColor,
                  ),
                  const SizedBox(height: 14),
                  if (isFinalShipment) ...[
                    _ShipmentSummaryCard(orderDetails: orderDetails),
                    const SizedBox(height: 14),
                    if (orderDetails.financial != null) ...[
                      _ShipmentFinancialCard(
                        financial: orderDetails.financial!,
                        statusId: currentStatusId,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _ShipmentSupportChatButton(
                      isLoading: isOpeningShipmentChat,
                      onPressed: onContactSupport,
                    ),
                  ] else ...[
                    _TopOperationalActions(
                      onTrackDriver: canTrackDriver ? onTrackDriver : null,
                      onContactSupport: onContactSupport,
                      isOpeningShipmentChat: isOpeningShipmentChat,
                    ),
                    const SizedBox(height: 14),
                    _ShipmentTimeline(
                      timeline: orderDetails.statusTimeline,
                      currentStatusId: currentStatusId,
                      currentStatus: currentStatus,
                      timelineAvailable: orderDetails.timelineAvailable,
                      onRetry: () => provider.fetchOrderDetails(
                        orderDetails.orderId,
                        force: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ShipmentSummaryCard(orderDetails: orderDetails),
                    const SizedBox(height: 14),
                    if (orderDetails.financial != null) ...[
                      _ShipmentFinancialCard(
                        financial: orderDetails.financial!,
                        statusId: currentStatusId,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (orderDetails.actionReason != null) ...[
                      _ShipmentActionReasonCard(
                        reason: orderDetails.actionReason!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (waitingForDriver) ...[
                      const _WaitingForDriverCard(),
                      const SizedBox(height: 14),
                    ],
                    _CustomerDetailsCard(
                      details: orderDetails.details,
                      onCallCustomer: onCallCustomer,
                    ),
                    const SizedBox(height: 14),
                    _DriverDetailsCard(
                      driver: orderDetails.driver,
                      onCallDriver: onCallDriver,
                      onTrackDriver: canTrackDriver ? onTrackDriver : null,
                      ratingSection: orderDetails.isDriverRated &&
                              orderDetails.driverRating != null
                          ? DriverRatingDisplay(
                              rating: orderDetails.driverRating!,
                            )
                          : orderDetails.canRateDriver
                              ? DriverRatingButton(
                                  onTap: onRateDriver,
                                )
                              : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStyleTopBar extends StatelessWidget {
  const _DriverStyleTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0F172A).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SupportAssistancePage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: const Color(0xffEEF5FF),
                    side: const BorderSide(color: Color(0xffD8E8FF)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    _copy(
                      isRtl,
                      'Help?',
                      '\u0645\u0633\u0627\u0639\u062F\u0629\u061F',
                    ),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: isRtl
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                  backgroundColor: const Color(0xffF1F5F9),
                  iconColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Color(0xff0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStyleHeaderCard extends StatelessWidget {
  const _DriverStyleHeaderCard({
    required this.policyNumber,
    required this.deliveryType,
    required this.statusLabel,
    required this.statusColor,
  });

  final String policyNumber;
  final String deliveryType;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassPill(
                  label: deliveryType,
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(height: 12),
                Text(
                  policyNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                _GlassPill(
                  key: const ValueKey('shipment-current-status-chip'),
                  label: statusLabel,
                  icon: Icons.fact_check_outlined,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              _headerStatusIcon(statusColor),
              color: Colors.white,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  IconData _headerStatusIcon(Color color) {
    if (color == const Color(0xffDC2626)) return Icons.error_outline_rounded;
    if (color == const Color(0xff16A06D)) return Icons.verified_rounded;
    return Icons.local_shipping_rounded;
  }
}

class _DriverStyleStepCard extends StatelessWidget {
  const _DriverStyleStepCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _driverCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const ValueKey('shipment-current-status-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    key: const ValueKey('shipment-current-status-description'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
        ],
      ),
    );
  }
}

class _DriverStyleStageTimeline extends StatelessWidget {
  const _DriverStyleStageTimeline({
    required this.currentStatusId,
    required this.waitingForDriver,
    required this.instantStages,
    required this.instantCurrentStage,
  });

  final int currentStatusId;
  final bool waitingForDriver;
  final List<InstantShipmentStage> instantStages;
  final InstantShipmentStage? instantCurrentStage;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    if (instantStages.isNotEmpty) {
      return _InstantShipmentStagesCard(
        stages: instantStages,
        currentStage: instantCurrentStage,
      );
    }

    final steps = <_StageStepData>[
      _StageStepData(
        title: _copy(isRtl, 'Accepted', '\u0627\u0644\u0642\u0628\u0648\u0644'),
        icon: Icons.check_circle_outline_rounded,
        state: _stepState(1),
      ),
      _StageStepData(
        title: _copy(
            isRtl, 'Preparing', '\u0627\u0644\u062A\u062C\u0647\u064A\u0632'),
        icon: Icons.inventory_2_outlined,
        state: _stepState(2),
      ),
      _StageStepData(
        title: _copy(isRtl, 'Pickup',
            '\u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645'),
        icon: Icons.storefront_outlined,
        state: _stepState(10),
      ),
      _StageStepData(
        title: _copy(
            isRtl, 'Delivery', '\u0627\u0644\u062A\u0648\u0635\u064A\u0644'),
        icon: Icons.near_me_outlined,
        state: _stepState(4),
      ),
      _StageStepData(
        title:
            _copy(isRtl, 'Done', '\u0627\u0644\u0625\u0646\u0647\u0627\u0621'),
        icon: Icons.verified_rounded,
        state: _stepState(6),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: _driverCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy(isRtl, 'Shipment Stages',
                '\u0645\u0631\u0627\u062D\u0644 \u0627\u0644\u0634\u062D\u0646\u0629'),
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(child: _DriverTimelineNode(data: steps[i])),
                if (i != steps.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: steps[i].state == _StageStepState.completed
                          ? const Color(0xff16A06D)
                          : const Color(0xffCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ],
          ),
          if (waitingForDriver) ...[
            const SizedBox(height: 14),
            _MiniNoticeStrip(
              icon: Icons.person_search_rounded,
              color: const Color(0xffF59E0B),
              text: _copy(
                isRtl,
                'Driver assignment is still pending.',
                '\u0644\u0645 \u064A\u062A\u0645 \u062A\u0639\u064A\u064A\u0646 \u0633\u0627\u0626\u0642 \u0628\u0639\u062F.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StageStepState _stepState(int statusId) {
    if (waitingForDriver) return _StageStepState.pending;
    if (currentStatusId == statusId) return _StageStepState.active;
    if (_isFinalStatus(currentStatusId)) return _StageStepState.completed;
    return _statusRank(statusId) < _statusRank(currentStatusId)
        ? _StageStepState.completed
        : _StageStepState.pending;
  }
}

class _InstantShipmentStagesCard extends StatelessWidget {
  const _InstantShipmentStagesCard({
    required this.stages,
    required this.currentStage,
  });

  final List<InstantShipmentStage> stages;
  final InstantShipmentStage? currentStage;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final exceptionStage =
        currentStage?.state == InstantShipmentVisualState.exception
            ? currentStage
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: _driverCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _copy(
                    isRtl,
                    'Instant Shipment Stages',
                    '\u0645\u0631\u0627\u062D\u0644 \u0627\u0644\u0634\u062D\u0646\u0629 \u0627\u0644\u0641\u0648\u0631\u064A\u0629',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (currentStage != null) _SmallStageBadge(stage: currentStage!),
            ],
          ),
          const SizedBox(height: 14),
          if (exceptionStage != null) ...[
            _MiniNoticeStrip(
              icon: exceptionStage.icon,
              color: exceptionStage.color,
              text: exceptionStage.message(isRtl),
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < stages.length; i++)
            _InstantStageRow(
              stage: stages[i],
              isLast: i == stages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _SmallStageBadge extends StatelessWidget {
  const _SmallStageBadge({required this.stage});

  final InstantShipmentStage stage;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stage.color.withValues(alpha: 0.20)),
      ),
      child: Text(
        stage.title(isRtl),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: stage.color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InstantStageRow extends StatelessWidget {
  const _InstantStageRow({
    required this.stage,
    required this.isLast,
  });

  final InstantShipmentStage stage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final isActive = stage.state == InstantShipmentVisualState.active;
    final isCompleted = stage.state == InstantShipmentVisualState.completed;
    final color = isCompleted
        ? InstantShipmentProgressHelper.successColor
        : isActive
            ? stage.color
            : const Color(0xffCBD5E1);
    final fill = isCompleted
        ? const Color(0xffDCFCE7)
        : isActive
            ? stage.color.withValues(alpha: 0.10)
            : const Color(0xffF8FAFC);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : stage.icon,
                color: color,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                color: color.withValues(alpha: isCompleted ? 0.45 : 0.20),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 0,
                vertical: isActive ? 9 : 0,
              ),
              decoration: isActive
                  ? BoxDecoration(
                      color: stage.color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: stage.color.withValues(alpha: 0.16),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title(isRtl),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? const Color(0xff0F172A)
                          : const Color(0xff64748B),
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 3),
                    Text(
                      stage.message(isRtl),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 11.2,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopOperationalActions extends StatelessWidget {
  const _TopOperationalActions({
    required this.onTrackDriver,
    required this.onContactSupport,
    required this.isOpeningShipmentChat,
  });

  final VoidCallback? onTrackDriver;
  final VoidCallback onContactSupport;
  final bool isOpeningShipmentChat;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: _TopActionButton(
            label: _copy(isRtl, 'Talk to us',
                '\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627'),
            icon: isOpeningShipmentChat
                ? Icons.hourglass_top_rounded
                : Icons.chat_bubble_rounded,
            iconSize: 20,
            onTap: isOpeningShipmentChat ? null : onContactSupport,
            primary: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: _TopActionButton(
            label: _copy(isRtl, 'Track', '\u062A\u062A\u0628\u0639'),
            icon: Icons.near_me_outlined,
            onTap: onTrackDriver,
          ),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.iconSize = 17,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final activeColor = primary ? AppColors.primary : AppColors.primary;
    return SizedBox(
      height: primary ? 52 : 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: activeColor,
          disabledForegroundColor: const Color(0xff94A3B8),
          backgroundColor: primary
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xffF8FAFC),
          disabledBackgroundColor: const Color(0xffF1F5F9),
          side: BorderSide(
            color: onTap == null
                ? const Color(0xffE2E8F0)
                : activeColor.withValues(alpha: 0.22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

enum _StageStepState { completed, active, pending }

class _StageStepData {
  const _StageStepData({
    required this.title,
    required this.icon,
    required this.state,
  });

  final String title;
  final IconData icon;
  final _StageStepState state;
}

class _DriverTimelineNode extends StatelessWidget {
  const _DriverTimelineNode({required this.data});

  final _StageStepData data;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.state) {
      _StageStepState.completed => const Color(0xff16A06D),
      _StageStepState.active => AppColors.primary,
      _StageStepState.pending => const Color(0xff94A3B8),
    };
    final fill = switch (data.state) {
      _StageStepState.completed => const Color(0xffDCFCE7),
      _StageStepState.active => const Color(0xffEAF2FF),
      _StageStepState.pending => const Color(0xffF1F5F9),
    };

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: data.state == _StageStepState.active ? 42 : 38,
          height: data.state == _StageStepState.active ? 42 : 38,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.28)),
            boxShadow: data.state == _StageStepState.active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(data.icon, color: color, size: 19),
        ),
        const SizedBox(height: 7),
        Text(
          data.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: data.state == _StageStepState.pending
                ? const Color(0xff64748B)
                : const Color(0xff0F172A),
            fontSize: 10.5,
            height: 1.15,
            fontWeight: data.state == _StageStepState.active
                ? FontWeight.w900
                : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    super.key,
    required this.label,
    required this.icon,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 11,
        vertical: dense ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: dense ? 13 : 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniNoticeStrip extends StatelessWidget {
  const _MiniNoticeStrip({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({
    required this.orderDetails,
  });

  final OrderDetailsData orderDetails;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final details = orderDetails.details;
    final productName =
        isRtl ? details.productType.nameAr : details.productType.nameEn;
    final isReturned = details.returnedShipment != 0;
    final isAccounted = details.accountingShipment != 0;

    return _DetailsCard(
      title: _copy(isRtl, 'Operational Summary',
          '\u0645\u0644\u062E\u0635 \u0627\u0644\u062A\u0634\u063A\u064A\u0644'),
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          _InfoGrid(
            items: [
              _InfoItem(
                label: _copy(isRtl, 'Total including delivery',
                    '\u0642\u064A\u0645\u0629 \u0627\u0644\u0634\u062D\u0646\u0629 \u0627\u0644\u0643\u0627\u0645\u0644\u0629 \u0634\u0627\u0645\u0644 \u0627\u0644\u062A\u0648\u0635\u064A\u0644'),
                value: _formatMoney(details.totalCost),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
              _InfoItem(
                label: _copy(isRtl, 'Return status',
                    '\u062D\u0627\u0644\u0629 \u0627\u0644\u0627\u0631\u062A\u062C\u0627\u0639'),
                value: _copy(
                  isRtl,
                  isReturned ? 'Returned' : 'Not returned',
                  isReturned
                      ? '\u0645\u0631\u062A\u062C\u0639'
                      : '\u063A\u064A\u0631 \u0645\u0631\u062A\u062C\u0639',
                ),
                icon: isReturned
                    ? Icons.assignment_return_rounded
                    : Icons.assignment_turned_in_outlined,
                color: isReturned
                    ? const Color(0xffB45309)
                    : const Color(0xff16A06D),
              ),
              _InfoItem(
                label: _copy(isRtl, 'Accounting status',
                    '\u062D\u0627\u0644\u0629 \u0627\u0644\u0645\u062D\u0627\u0633\u0628\u0629'),
                value: _copy(
                  isRtl,
                  isAccounted ? 'Accounted' : 'Not accounted',
                  isAccounted
                      ? '\u062A\u0645\u062A \u0627\u0644\u0645\u062D\u0627\u0633\u0628\u0629'
                      : '\u063A\u064A\u0631 \u0645\u062D\u0627\u0633\u0628\u0629',
                ),
                icon: isAccounted
                    ? Icons.verified_user_outlined
                    : Icons.pending_actions_outlined,
                color:
                    isAccounted ? AppColors.primary : const Color(0xff64748B),
              ),
              _InfoItem(
                label: _copy(isRtl, 'Product Type',
                    '\u0646\u0648\u0639 \u0627\u0644\u0637\u0631\u062F'),
                value: _safeValue(productName, fallback: _notAvailable(isRtl)),
                icon: Icons.category_outlined,
                color: const Color(0xff0891B2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The merchant's money on this shipment, exactly as the server computed it.
/// Only figures that apply are shown; legacy shipments show the payment type
/// and the amount to collect only.
class _ShipmentFinancialCard extends StatelessWidget {
  const _ShipmentFinancialCard({
    required this.financial,
    required this.statusId,
  });

  final ShipmentFinancial financial;
  final int statusId;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final feeDue = financial.feeDue ?? 0;
    final items = <_InfoItem>[
      _InfoItem(
        label: _copy(isRtl, 'Payment type', 'نوع الدفع'),
        value: financial.isPrepaid
            ? _copy(isRtl, 'Prepaid', 'مدفوع مسبقاً')
            : _copy(isRtl, 'Cash on delivery', 'الدفع عند الاستلام'),
        icon: financial.isPrepaid
            ? Icons.verified_outlined
            : Icons.payments_outlined,
        color: financial.isPrepaid ? const Color(0xff059669) : AppColors.primary,
      ),
      _InfoItem(
        label: _copy(isRtl, 'Product to collect', 'المبلغ المطلوب تحصيله'),
        value: _formatMoney(financial.productToCollect),
        icon: Icons.local_atm_outlined,
        color: const Color(0xff0891B2),
      ),
      if (feeDue > 0) ...[
        _InfoItem(
          label: _copy(isRtl, 'Delivery fee due', 'أجرة التوصيل المستحقة'),
          value: _formatMoney(feeDue),
          icon: Icons.receipt_long_outlined,
          color: const Color(0xff7C3AED),
        ),
        _InfoItem(
          label: _copy(isRtl, 'Fee collected', 'المحصّل من الأجرة'),
          value: _formatMoney(financial.feeCollected ?? 0),
          icon: Icons.task_alt_rounded,
          color: const Color(0xff16A06D),
        ),
      ],
      if ((financial.feeRemaining ?? 0) > 0)
        _InfoItem(
          label: _copy(isRtl, 'Fee remaining', 'المتبقي من الأجرة'),
          value: _formatMoney(financial.feeRemaining!),
          icon: Icons.hourglass_bottom_rounded,
          color: const Color(0xffB45309),
        ),
      if ((financial.merchantPayable ?? 0) > 0)
        _InfoItem(
          label: _copy(isRtl, 'Payable to you', 'المستحق لك'),
          value: _formatMoney(financial.merchantPayable!),
          icon: Icons.south_west_rounded,
          color: const Color(0xff16A06D),
        ),
      if ((financial.merchantReceivable ?? 0) > 0)
        _InfoItem(
          label: _copy(isRtl, 'You owe', 'المستحق عليك'),
          value: _formatMoney(financial.merchantReceivable!),
          icon: Icons.north_east_rounded,
          color: const Color(0xffDC2626),
        ),
    ];

    String? note;
    if (financial.isPrepaid) {
      note = _copy(
        isRtl,
        'The customer already paid the merchant; the merchant owes the delivery fee.',
        'دفع العميل للتاجر مسبقاً؛ والتاجر مدين بأجرة التوصيل.',
      );
    } else if (statusId == 7 && feeDue > 0) {
      note = _copy(
        isRtl,
        'Cancelled after the driver left, so the delivery fee is due.',
        'أُلغيت الشحنة بعد انطلاق السائق، لذا تستحق أجرة التوصيل.',
      );
    } else if (statusId == 8 && feeDue > 0) {
      note = _copy(
        isRtl,
        'The parcel was returned; the delivery fee is still due.',
        'أُعيدت الشحنة؛ وتبقى أجرة التوصيل مستحقة.',
      );
    }

    return _DetailsCard(
      title: _copy(isRtl, 'Payment & fees', 'الدفع والأجور'),
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _InfoGrid(items: items),
          if (note != null) ...[
            const SizedBox(height: 10),
            _MiniNoticeStrip(
              icon: Icons.info_outline_rounded,
              color: const Color(0xff475569),
              text: note,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShipmentSupportChatButton extends StatelessWidget {
  const _ShipmentSupportChatButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        key: const ValueKey('shipment-details-contact-company'),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.forum_outlined, size: 20),
        label: Text(
          _copy(
            isRtl,
            'Talk to us about this shipment',
            '\u062A\u062D\u062F\u062B \u0645\u0639\u0646\u0627 \u0628\u062E\u0635\u0648\u0635 \u0647\u0630\u0647 \u0627\u0644\u0634\u062D\u0646\u0629',
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ShipmentActionReasonCard extends StatelessWidget {
  const _ShipmentActionReasonCard({required this.reason});

  final ShipmentActionReasonLog reason;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final color = switch (reason.actionType) {
      'cancel' => const Color(0xffDC2626),
      'return' => const Color(0xffB45309),
      'failed_delivery' => const Color(0xffDC2626),
      _ => const Color(0xffF59E0B),
    };
    final title = switch (reason.actionType) {
      'cancel' => _copy(isRtl, 'Cancellation reason', 'سبب الإلغاء'),
      'return' => _copy(isRtl, 'Return reason', 'سبب الإرجاع'),
      'failed_delivery' =>
        _copy(isRtl, 'Failed delivery reason', 'سبب فشل التسليم'),
      _ => _copy(isRtl, 'Shipment action reason', 'سبب إجراء الشحنة'),
    };

    return _DetailsCard(
      title: title,
      icon: Icons.report_problem_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason.title(isRtl),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if ((reason.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason.note!.trim(),
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if ((reason.createdAt ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason.createdAt!.trim(),
                style: const TextStyle(
                  color: Color(0xff94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShipmentTimeline extends StatelessWidget {
  const _ShipmentTimeline({
    required this.timeline,
    required this.currentStatusId,
    required this.currentStatus,
    required this.timelineAvailable,
    required this.onRetry,
  });

  final List<StatusTimeline> timeline;
  final int currentStatusId;
  final StatusTimeline? currentStatus;
  final bool timelineAvailable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final stages = <StatusTimeline>[];
    final seenStatusIds = <int>{};
    for (final status in timeline) {
      if (seenStatusIds.add(status.statusId)) {
        stages.add(status);
      }
    }
    return _DetailsCard(
      title: _copy(isRtl, 'Shipment Timeline',
          '\u0645\u0631\u0627\u062D\u0644 \u0627\u0644\u0634\u062D\u0646\u0629'),
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          if (!timelineAvailable)
            _TimelineUnavailable(onRetry: onRetry)
          else if (stages.isEmpty)
            _CurrentStatusOnly(status: currentStatus)
          else
            _HorizontalShipmentTimeline(
              stages: stages,
              currentStatusId: currentStatusId,
              currentStatusLabel: currentStatus?.localizedName(isRtl),
              isRtl: isRtl,
            ),
        ],
      ),
    );
  }
}

class _CurrentStatusOnly extends StatelessWidget {
  const _CurrentStatusOnly({required this.status});

  final StatusTimeline? status;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final label = status == null
        ? _copy(
            isRtl, 'Current status unavailable', 'الحالة الحالية غير متوفرة')
        : _localizedTimelineLabel(status!, isRtl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xff0B63CE)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _copy(
                isRtl,
                'Current status: $label. No event history is available yet.',
                'الحالة الحالية: $label. لا يتوفر سجل مراحل لهذه الشحنة بعد.',
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                color: Color(0xff334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineUnavailable extends StatelessWidget {
  const _TimelineUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _copy(
            isRtl,
            'The timeline could not be loaded. Try again.',
            'تعذر تحميل سجل مراحل الشحنة. حاول مرة أخرى.',
          ),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: Text(_copy(isRtl, 'Retry', 'إعادة المحاولة')),
        ),
      ],
    );
  }
}

class _HorizontalShipmentTimeline extends StatelessWidget {
  const _HorizontalShipmentTimeline({
    required this.stages,
    required this.currentStatusId,
    required this.currentStatusLabel,
    required this.isRtl,
  });

  final List<StatusTimeline> stages;
  final int currentStatusId;
  final String? currentStatusLabel;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          physics: const BouncingScrollPhysics(),
          itemCount: stages.length,
          separatorBuilder: (_, index) => _TimelineConnector(
            isCompleted: stages[index].statusId <= currentStatusId,
          ),
          itemBuilder: (context, index) => _HorizontalTimelineStage(
            key: ValueKey(stages[index].statusId == currentStatusId
                ? 'shipment-current-timeline-step'
                : 'shipment-history-status-${stages[index].statusId}'),
            status: stages[index],
            isCurrent: stages[index].statusId == currentStatusId,
            currentStatusLabel: currentStatusLabel,
          ),
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Center(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color:
                isCompleted ? const Color(0xff16A06D) : const Color(0xffCBD5E1),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _HorizontalTimelineStage extends StatelessWidget {
  const _HorizontalTimelineStage({
    super.key,
    required this.status,
    required this.isCurrent,
    required this.currentStatusLabel,
  });

  final StatusTimeline status;
  final bool isCurrent;
  final String? currentStatusLabel;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final finalStatus = _isFinalStatus(status.statusId);
    final color = isCurrent
        ? _statusColor(status.statusId, status.typeColor)
        : const Color(0xff16A06D);

    return SizedBox(
      width: 94,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? color.withValues(alpha: .10)
              : const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? color.withValues(alpha: .45)
                : const Color(0xffE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isCurrent ? 1 : 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.4),
              ),
              child: Icon(
                finalStatus
                    ? Icons.flag_rounded
                    : isCurrent
                        ? Icons.radio_button_checked_rounded
                        : Icons.check_rounded,
                color: isCurrent ? Colors.white : color,
                size: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isCurrent
                  ? (currentStatusLabel ?? status.localizedName(isRtl))
                  : _localizedTimelineLabel(status, isRtl),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrent ? color : const Color(0xff0F172A),
                fontSize: 10.5,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              (status.timestamp ?? '').trim().isEmpty
                  ? '-'
                  : _formatDate(status.timestamp!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 8.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _localizedTimelineLabel(StatusTimeline status, bool isRtl) {
  return _safeValue(
    isRtl ? status.nameAr : status.nameEn,
    fallback: _copy(isRtl, 'Status updated', 'تم تحديث الحالة'),
  );
}

class _WaitingForDriverCard extends StatefulWidget {
  const _WaitingForDriverCard();

  @override
  State<_WaitingForDriverCard> createState() => _WaitingForDriverCardState();
}

class _WaitingForDriverCardState extends State<_WaitingForDriverCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffFFF7ED),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffFDBA74)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffF97316)
                    .withValues(alpha: 0.08 + (_controller.value * 0.08)),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          const _PulseIcon(
            icon: Icons.person_search_rounded,
            color: Color(0xffEA580C),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(isRtl, 'Waiting for driver',
                      '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0633\u0627\u0626\u0642'),
                  style: const TextStyle(
                    color: Color(0xff9A3412),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _copy(
                    isRtl,
                    'No driver has been assigned to this shipment yet.',
                    '\u0644\u0645 \u064A\u062A\u0645 \u062A\u0639\u064A\u064A\u0646 \u0633\u0627\u0626\u0642 \u0644\u0647\u0630\u0647 \u0627\u0644\u0634\u062D\u0646\u0629 \u0628\u0639\u062F.',
                  ),
                  style: const TextStyle(
                    color: Color(0xffB45309),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDetailsCard extends StatelessWidget {
  const _CustomerDetailsCard({
    required this.details,
    required this.onCallCustomer,
  });

  final OrderDetails details;
  final VoidCallback onCallCustomer;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return _DetailsCard(
      title: _copy(isRtl, 'Customer Details',
          '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0639\u0645\u064A\u0644'),
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _ContactIdentityHeader(
            icon: Icons.person_rounded,
            label: _copy(isRtl, 'Receiver',
                '\u0627\u0644\u0645\u0633\u062A\u0644\u0645'),
            name: _safeValue(details.recipientName,
                fallback: _notAvailable(isRtl)),
            action: _RoundActionButton(
              icon: Icons.call_rounded,
              onTap:
                  details.recipientPhone.trim().isEmpty ? null : onCallCustomer,
            ),
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem(
                label: _copy(
                    isRtl, 'Phone', '\u0627\u0644\u0647\u0627\u062A\u0641'),
                value: _safeValue(details.recipientPhone,
                    fallback: _notAvailable(isRtl)),
                icon: Icons.call_outlined,
                color: const Color(0xff1677D2),
                isFullWidth: true,
              ),
              _InfoItem(
                label: _copy(isRtl, 'Destination',
                    '\u0627\u0644\u0648\u062C\u0647\u0629'),
                value: _safeValue(details.deliveryAddress,
                    fallback: _notAvailable(isRtl)),
                icon: Icons.location_on_outlined,
                color: const Color(0xff16A06D),
                isFullWidth: true,
                maxLines: 2,
              ),
              if (details.notes.trim().isNotEmpty)
                _InfoItem(
                  label: _copy(isRtl, 'Notes',
                      '\u0645\u0644\u0627\u062D\u0638\u0627\u062A'),
                  value: details.notes,
                  icon: Icons.sticky_note_2_outlined,
                  color: const Color(0xff8B5CF6),
                  isFullWidth: true,
                  maxLines: 2,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverDetailsCard extends StatelessWidget {
  const _DriverDetailsCard({
    required this.driver,
    required this.onCallDriver,
    required this.onTrackDriver,
    this.ratingSection,
  });

  final Driver driver;
  final VoidCallback? onCallDriver;
  final VoidCallback? onTrackDriver;
  final Widget? ratingSection;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    if (driver.id <= 0) {
      return _DetailsCard(
        title: _copy(isRtl, 'Driver Details',
            '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0633\u0627\u0626\u0642'),
        icon: Icons.local_shipping_outlined,
        child: _EmptyDriverState(
          message: _copy(
            isRtl,
            'Driver details will appear after assignment.',
            '\u0633\u062A\u0638\u0647\u0631 \u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0633\u0627\u0626\u0642 \u0628\u0639\u062F \u0627\u0644\u062A\u0639\u064A\u064A\u0646.',
          ),
        ),
      );
    }

    return _DetailsCard(
      title: _copy(isRtl, 'Driver Details',
          '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0633\u0627\u0626\u0642'),
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _ContactIdentityHeader(
            icon: Icons.local_shipping_rounded,
            label:
                _copy(isRtl, 'Driver', '\u0627\u0644\u0633\u0627\u0626\u0642'),
            name: _safeValue(driver.name, fallback: _notAvailable(isRtl)),
            action: _RoundActionButton(
              icon: Icons.call_rounded,
              onTap: driver.phone.trim().isEmpty ? null : onCallDriver,
            ),
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem(
                label: _copy(
                    isRtl, 'Phone', '\u0627\u0644\u0647\u0627\u062A\u0641'),
                value: _safeValue(driver.phone, fallback: _notAvailable(isRtl)),
                icon: Icons.call_outlined,
                color: const Color(0xff1677D2),
              ),
              _InfoItem(
                label: _copy(
                    isRtl, 'Tracking', '\u0627\u0644\u062A\u062A\u0628\u0639'),
                value: onTrackDriver == null
                    ? _copy(isRtl, 'Location is not available',
                        '\u0627\u0644\u0645\u0648\u0642\u0639 \u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631')
                    : _copy(isRtl, 'Location is available',
                        '\u0627\u0644\u0645\u0648\u0642\u0639 \u0645\u062A\u0648\u0641\u0631'),
                icon: Icons.near_me_outlined,
                color: const Color(0xff16A06D),
              ),
            ],
          ),
          if (onTrackDriver != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTrackDriver,
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: Text(_copy(isRtl, 'Track driver',
                    '\u062A\u062A\u0628\u0639 \u0627\u0644\u0633\u0627\u0626\u0642')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: .3)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
          if (ratingSection != null) ...[
            const SizedBox(height: 12),
            ratingSection!,
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0F172A).withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xffEEF2F6)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailsInfoRow extends StatelessWidget {
  const _DetailsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff64748B), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ContactIdentityHeader extends StatelessWidget {
  const _ContactIdentityHeader({
    required this.icon,
    required this.label,
    required this.name,
    required this.action,
  });

  final IconData icon;
  final String label;
  final String name;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: isNarrow || item.isFullWidth
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2,
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: item.maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;
  final int maxLines;
}

class _DetailsLoadingState extends StatelessWidget {
  const _DetailsLoadingState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _DriverStyleTopBar(
            title: _copy(
              AppLocalizations.isRTL,
              'Shipment Details',
              'تفاصيل الشحنة',
            ),
            subtitle: _copy(
              AppLocalizations.isRTL,
              'Loading the latest shipment information',
              'جاري تحميل آخر معلومات الشحنة',
            ),
            onBack: onBack,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 168,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _copy(
                      AppLocalizations.isRTL,
                      'Loading shipment details...',
                      'جاري تحميل تفاصيل الشحنة...',
                    ),
                    style: const TextStyle(
                      color: Color(0xff334155),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState({
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xffDC2626)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff334155),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_copy(isRtl, 'Retry',
                  '\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _EmptyDriverState extends StatelessWidget {
  const _EmptyDriverState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_rounded, color: Color(0xff64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xff475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Order Route Map Page
class OrderRouteMapPage extends StatefulWidget {
  final String driverName;
  final LatLng driverLocation;
  final LatLng targetLocation;
  final String targetTitle;
  final String targetSubtitle;
  final String relationLabel;
  final OrderDetailsData? orderDetails;

  const OrderRouteMapPage({
    super.key,
    required this.driverName,
    required this.driverLocation,
    required this.targetLocation,
    required this.targetTitle,
    required this.targetSubtitle,
    required this.relationLabel,
    this.orderDetails,
  });

  @override
  State<OrderRouteMapPage> createState() => _OrderRouteMapPageState();
}

class _OrderRouteMapPageState extends State<OrderRouteMapPage> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String _distance = '';

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  void _getRoute() {
    final distance = _calculateDistance(
      widget.targetLocation.latitude,
      widget.targetLocation.longitude,
      widget.driverLocation.latitude,
      widget.driverLocation.longitude,
    );
    _setFallbackRoute(distance);
  }

  void _setFallbackRoute(double distance) {
    if (!mounted) return;
    setState(() {
      _routePoints = [widget.targetLocation, widget.driverLocation];
      _distance = '${distance.toStringAsFixed(1)} km';
      _isLoadingRoute = false;
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(lat1Rad) *
            math.sin(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Column(
          children: [
            _DriverStyleTopBar(
              title: AppTranslations.getText('track_order'),
              subtitle: widget.relationLabel,
              onBack: () => Navigator.maybePop(context),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.route_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isLoadingRoute
                          ? AppTranslations.getText('calculating')
                          : isRtl
                              ? 'المسافة المباشرة: $_distance • المسار الفعلي ووقت الوصول غير متاحين'
                              : 'Direct distance: $_distance • Road route and ETA are unavailable',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff334155),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _MapMetricChip(
                      icon: Icons.place_rounded,
                      label: widget.targetTitle,
                      value: widget.relationLabel,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MapMetricChip(
                      icon: Icons.social_distance_rounded,
                      label: AppTranslations.getText('distance'),
                      value: _isLoadingRoute
                          ? AppTranslations.getText('calculating')
                          : _distance,
                      color: const Color(0xff8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _getMapCenter(),
                      zoom: 12,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('target'),
                        position: widget.targetLocation,
                        infoWindow: InfoWindow(
                          title: widget.targetTitle,
                          snippet: widget.targetSubtitle,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: widget.driverLocation,
                        infoWindow: InfoWindow(title: widget.driverName),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    polylines: {
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          color: AppColors.primary,
                          width: 5,
                          points: _routePoints,
                        ),
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _MapDriverBar(
                driverName: widget.driverName,
                phone: widget.orderDetails?.driver.phone ?? '',
                relationLabel: widget.relationLabel,
                targetTitle: widget.targetTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalMaps() async {
    final url = 'https://www.google.com/maps/dir/'
        '${widget.targetLocation.latitude},${widget.targetLocation.longitude}/'
        '${widget.driverLocation.latitude},${widget.driverLocation.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  LatLng _getMapCenter() {
    return LatLng(
      (widget.targetLocation.latitude + widget.driverLocation.latitude) / 2,
      (widget.targetLocation.longitude + widget.driverLocation.longitude) / 2,
    );
  }
}

class _MapDriverBar extends StatelessWidget {
  const _MapDriverBar({
    required this.driverName,
    required this.phone,
    required this.relationLabel,
    required this.targetTitle,
  });

  final String driverName;
  final String phone;
  final String relationLabel;
  final String targetTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _driverCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            relationLabel,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xffBFDBFE),
                  ),
                ),
                child: Text(
                  targetTitle,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: phone.trim().isEmpty
                    ? null
                    : () async {
                        await launchUrl(
                          Uri(
                            scheme: 'tel',
                            path: phone.trim(),
                          ),
                        );
                      },
                icon: Icon(
                  Icons.call_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapMetricChip extends StatelessWidget {
  const _MapMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingTarget {
  const _TrackingTarget({
    required this.location,
    required this.title,
    required this.subtitle,
    required this.relationLabel,
  });

  final LatLng location;
  final String title;
  final String subtitle;
  final String relationLabel;
}

bool _isWaitingForDriver(OrderDetailsData orderDetails, int currentStatusId) {
  return InstantShipmentProgressHelper.isWaitingForDriverFromValues(
    deliveryTypeId: orderDetails.details.deliveryType.id,
    driverId: orderDetails.driver.id,
    statusId: currentStatusId,
  );
}

bool _canTrackDriverFromStore({
  required OrderDetailsData orderDetails,
  required int currentStatusId,
}) {
  final driver = orderDetails.driver;
  if (driver.id <= 0) return false;
  if (_isFinalStatus(currentStatusId)) return false;
  if (driver.locationState != 'live') return false;
  if (!_isValidCoordinate(
    double.tryParse(driver.latitude),
    double.tryParse(driver.longitude),
  )) {
    return false;
  }

  final isInstant = InstantShipmentProgressHelper.isInstantShipmentByType(
    orderDetails.details.deliveryType.id,
  );
  if (!isInstant) return true;

  // For instant shipments the tracking target changes by stage:
  // before pickup -> store, after pickup -> customer.
  // The action should stay available while the shipment is active.
  return const {1, 2, 3, 4, 5, 10}.contains(currentStatusId);
}

bool _isFinalStatus(int statusId) => const {6, 7, 8, 9, 11}.contains(statusId);

int _statusRank(int statusId) {
  const order = [1, 2, 3, 10, 4, 5, 6, 11, 7, 8, 9];
  final index = order.indexOf(statusId);
  return index == -1 ? 999 : index;
}

Color _statusColor(int statusId, String? typeColor) {
  if (statusId == 6 || statusId == 11 || typeColor == 'success') {
    return const Color(0xff16A06D);
  }
  if (statusId == 7 ||
      statusId == 8 ||
      statusId == 9 ||
      typeColor == 'danger') {
    return const Color(0xffDC2626);
  }
  if (typeColor == 'warning') return const Color(0xffF59E0B);
  return AppColors.primary;
}

String _deliveryTypeLabel(OrderDetailsData orderDetails) {
  final isRtl = AppLocalizations.isRTL;
  final type = orderDetails.details.deliveryType;
  return _safeValue(
    isRtl ? type.nameAr : type.nameEn,
    fallback: type.id == 1
        ? _copy(isRtl, 'Instant', '\u0641\u0648\u0631\u064A')
        : _notAvailable(isRtl),
  );
}

IconData _stepIcon({
  required bool waitingForDriver,
  required bool hasDriver,
  required int statusId,
}) {
  if (waitingForDriver) return Icons.person_search_rounded;
  if (!hasDriver) return Icons.inventory_2_outlined;
  if (statusId == 6 || statusId == 11) return Icons.verified_rounded;
  if (statusId == 7 || statusId == 8 || statusId == 9) {
    return Icons.error_outline_rounded;
  }
  if (statusId == 4 || statusId == 5) return Icons.near_me_rounded;
  if (statusId == 10) return Icons.storefront_rounded;
  return Icons.local_shipping_rounded;
}

BoxDecoration _driverCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xffE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xff0F172A).withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

bool _isValidCoordinate(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (lat == 0 && lng == 0) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

String _safeValue(String? value, {required String fallback}) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? fallback : trimmed;
}

String _notAvailable(bool isRtl) {
  return _copy(isRtl, 'Not available',
      '\u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631');
}

String _formatMoney(double value) {
  final formatted =
      value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return '$formatted JOD';
}

String _formatDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return _notAvailable(AppLocalizations.isRTL);
  }
  final parsed = JordanTime.parse(value);
  if (parsed == null) return value;
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} $hour:$minute';
}

String _copy(bool isRtl, String en, String ar) => isRtl ? ar : en;
