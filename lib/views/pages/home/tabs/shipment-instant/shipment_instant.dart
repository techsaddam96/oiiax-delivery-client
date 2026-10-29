import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/constants/logic.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/models/shipment_action_reason.dart';
import 'package:blockatie/models/shipment_financial.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/services/shipment_action_reason_service.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/home/tabs/shipment-instant/components/order_instant_tile.dart';
import 'package:blockatie/views/pages/orders/components/store_delivery_details.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_bottom_sheet.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_button.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_display.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ShipmentInstant extends StatefulWidget {
  const ShipmentInstant({super.key});

  @override
  State<ShipmentInstant> createState() => _ShipmentInstantState();
}

class _ShipmentInstantState extends State<ShipmentInstant>
    with AutomaticKeepAliveClientMixin<ShipmentInstant> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted || _isInitialized) {
      return;
    }

    _isInitialized = true;
    await context.read<ShipmentInstantprovider>().getShipmentsInstant();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      context.read<ShipmentInstantprovider>().setSearchQuery(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    context.read<ShipmentInstantprovider>().clearSearch();
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCancelShipment(
    Shipment shipment, {
    required int reasonId,
    String? note,
  }) async {
    final provider = context.read<ShipmentInstantprovider>();
    final result = await provider.cancelShipment(
      shipment.id,
      reasonId: reasonId,
      note: note,
    );
    if (!mounted) {
      return;
    }

    if (result.success) {
      final message = _safeMessage(
        result.message,
        fallback: _copy(
          context,
          'The shipment has been cancelled successfully.',
          'تم إلغاء الشحنة بنجاح.',
        ),
      );
      AppUtils.showSuccessDialog(
        result.driverCustodyHeld
            ? '$message\n\n${_copy(context, 'The shipment is cancelled, but the driver remains responsible for it until it is returned and received at the warehouse.', 'تم إلغاء الشحنة، لكن عهدة السائق تبقى قائمة حتى إعادة الشحنة واستلامها في المستودع.')}'
            : message,
      );
      return;
    }

    AppUtils.showErrorDialog(
      _safeMessage(
        result.message,
        fallback: _copy(
          context,
          'Unable to cancel this shipment right now.',
          'تعذر إلغاء هذه الشحنة حالياً.',
        ),
      ),
    );
  }

  Future<void> _confirmCancelShipment(Shipment shipment) async {
    final cancellationCheck = await context
        .read<ShipmentInstantprovider>()
        .revalidateCancellation(shipment.id);
    if (!mounted) {
      return;
    }
    if (!cancellationCheck.eligible) {
      AppUtils.showErrorDialog(
        _copy(
          context,
          'This shipment was updated and can no longer be cancelled.',
          'تم تحديث هذه الشحنة ولم يعد بالإمكان إلغاؤها.',
        ),
      );
      return;
    }

    // The preview was obtained from the same fresh server response that
    // authorised opening this sheet. Submission performs the check again.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShipmentCancelReasonSheet(
        preview: Future<CancellationPreview?>.value(cancellationCheck.preview),
        onSubmit: (reasonId, note) {
          _handleCancelShipment(
            shipment,
            reasonId: reasonId,
            note: note,
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    final provider = context.read<ShipmentInstantprovider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider<ShipmentInstantprovider>.value(
          value: provider,
          child: const _InstantFilterSheet(),
        );
      },
    );
  }

  void _openShipmentDetails(Shipment shipment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          orderId: shipment.id,
          orderStatus: shipment.statusNameEn,
        ),
      ),
    );
  }

  Future<void> _openDriverRatingSheet(Shipment shipment) async {
    final result = await showModalBottomSheet<DriverRatingBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DriverRatingBottomSheet(
        driverName: shipment.driverName ?? '',
        driverAvatar: shipment.driverImg,
        onSubmit: (rating, comment) {
          return DriverRatingService.submitDriverRating(
            shipmentId: shipment.id,
            rating: rating,
            comment: comment,
          );
        },
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final ratedShipmentId = result.shipmentId ?? shipment.id;
    if (ratedShipmentId > 0) {
      context.read<ShipmentInstantprovider>().markDriverRated(
            shipmentId: ratedShipmentId,
            rating: result.rating,
          );
      context.read<ShipmentProvider>().markDriverRated(
            shipmentId: ratedShipmentId,
            rating: result.rating,
          );
    }

    AppUtils.showSuccessDialog(result.message);
  }

  Widget? _buildDriverRatingSection(Shipment shipment) {
    if (shipment.isDriverRated && shipment.driverRating != null) {
      return DriverRatingDisplay(rating: shipment.driverRating!, compact: true);
    }

    if (shipment.canRateDriver) {
      return DriverRatingButton(
        onTap: () => _openDriverRatingSheet(shipment),
      );
    }

    return null;
  }

  void _openTracking(Shipment shipment) {
    final driverAvailable = _hasValidCoordinates(
      shipment.driverLatitude,
      shipment.driverLongitude,
    );
    final storeAvailable = _hasValidCoordinates(
      shipment.storeLatitude,
      shipment.storeLongitude,
    );

    if (driverAvailable && storeAvailable && shipment.shipmentStatusId == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderRouteMapPage(
            driverName:
                shipment.driverName ?? _copy(context, 'Driver', 'السائق'),
            driverLocation: LatLng(
              shipment.driverLatitude!,
              shipment.driverLongitude!,
            ),
            targetLocation: LatLng(
              shipment.storeLatitude!,
              shipment.storeLongitude!,
            ),
            targetTitle: _copy(context, 'Store location', 'موقع المتجر'),
            targetSubtitle: shipment.deliveryAddress.isNotEmpty
                ? shipment.deliveryAddress
                : _copy(
                    context,
                    'Store pickup point',
                    'نقطة استلام المتجر',
                  ),
            relationLabel: _copy(
              context,
              'Driver to store',
              'السائق إلى المتجر',
            ),
          ),
        ),
      );
      return;
    }

    if (driverAvailable) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DriverLocationMapPage(
            driverName:
                shipment.driverName ?? _copy(context, 'Driver', 'السائق'),
            latitude: shipment.driverLatitude!,
            longitude: shipment.driverLongitude!,
          ),
        ),
      );
      return;
    }

    AppUtils.showErrorDialog(
      _copy(
        context,
        'Driver location is not available yet.',
        'موقع السائق غير متوفر حالياً.',
      ),
    );
  }

  Future<void> _openMap(Shipment shipment) async {
    double? latitude;
    double? longitude;

    if (_hasValidCoordinates(
        shipment.driverLatitude, shipment.driverLongitude)) {
      latitude = shipment.driverLatitude;
      longitude = shipment.driverLongitude;
    } else if (_hasValidCoordinates(
      shipment.storeLatitude,
      shipment.storeLongitude,
    )) {
      latitude = shipment.storeLatitude;
      longitude = shipment.storeLongitude;
    }

    if (latitude == null || longitude == null) {
      AppUtils.showErrorDialog(
        _copy(
          context,
          'Map location is not available for this shipment.',
          'موقع الشحنة على الخريطة غير متوفر.',
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      AppUtils.showErrorDialog(
        _copy(
          context,
          'Unable to open the map right now.',
          'تعذر فتح الخريطة حالياً.',
        ),
      );
    }
  }

  Future<void> _callRecipient(Shipment shipment) async {
    final phone = shipment.recipientPhone.trim();
    if (phone.isEmpty) {
      AppUtils.showErrorDialog(
        _copy(
          context,
          'Receiver phone number is not available.',
          'رقم هاتف المستلم غير متوفر.',
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      AppUtils.showErrorDialog(
        _copy(
          context,
          'Unable to open the dialer right now.',
          'تعذر فتح شاشة الاتصال حالياً.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final provider = context.watch<ShipmentInstantprovider>();
    final shipments = provider.paginatedShipments;
    final hasFilters = provider.searchQuery.isNotEmpty ||
        provider.selectedFilter != InstantShipmentFilter.all;

    return Directionality(
      textDirection:
          AppLocalizations.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: provider.refresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _InstantShipmentsHeader(
                      totalCount: provider.totalCount,
                      waitingCount: provider.waitingDriverCount,
                      activeCount: provider.inDeliveryCount,
                      isLoading: provider.isLoading && !provider.hasLoaded,
                    ),
                    const SizedBox(height: 16),
                    _InstantSearchFilterBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                      hasText: _searchController.text.trim().isNotEmpty,
                      onFilterTap: _showFilterSheet,
                      hasActiveFilter:
                          provider.selectedFilter != InstantShipmentFilter.all,
                    ),
                    const SizedBox(height: 12),
                    _InstantStatusChips(
                      selectedFilter: provider.selectedFilter,
                      onSelected: provider.setStatusFilter,
                    ),
                    const SizedBox(height: 12),
                    _InstantListMeta(
                      visibleCount: provider.filteredCount,
                      totalCount: provider.totalCount,
                      currentPage: provider.currentPage,
                      totalPages: provider.totalPages,
                    ),
                    const SizedBox(height: 16),
                    if (provider.hasError && provider.displayShipments.isEmpty)
                      _InstantErrorState(
                        message: _errorMessage(provider),
                        onRetry: () {
                          provider.getShipmentsInstant(force: true);
                        },
                      )
                    else if (provider.isLoading && !provider.hasLoaded)
                      const _InstantLoadingState()
                    else if (provider.displayShipments.isEmpty)
                      _InstantEmptyState(
                        title: hasFilters
                            ? _copy(
                                context,
                                'No matching instant shipments.',
                                'لا توجد شحنات فورية مطابقة.',
                              )
                            : _copy(
                                context,
                                'No instant shipments yet.',
                                'لا توجد شحنات فورية حالياً.',
                              ),
                        message: hasFilters
                            ? _copy(
                                context,
                                'Try changing the search or selected filters.',
                                'جرّب تعديل البحث أو الفلاتر المحددة.',
                              )
                            : _copy(
                                context,
                                'Instant delivery shipments will appear here once they are created.',
                                'ستظهر شحنات التوصيل الفوري هنا عند إنشائها.',
                              ),
                      )
                    else ...[
                      if (provider.hasError) ...[
                        _InstantInlineError(
                          message: _errorMessage(provider),
                          onRetry: () {
                            provider.getShipmentsInstant(force: true);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (provider.totalPages > 1) ...[
                        _InstantPaginationControls(
                          currentPage: provider.currentPage,
                          totalPages: provider.totalPages,
                          onPageChanged: provider.setCurrentPage,
                        ),
                        const SizedBox(height: 14),
                      ],
                      ...shipments.map(
                        (shipment) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: OrderInstantTile(
                            shipment: shipment,
                            typeLabel: _deliveryTypeLabel(shipment),
                            statusLabel: _statusLabel(shipment),
                            stageLabel: _stageLabel(shipment),
                            createdLabel: _createdLabel(shipment),
                            canCancel: provider.canCancelShipment(shipment),
                            isBusy: provider.isShipmentBusy(shipment.id),
                            onViewDetails: () => _openShipmentDetails(shipment),
                            onTrackShipment: shipment.driverId != null
                                ? () => _openTracking(shipment)
                                : null,
                            onCancelShipment:
                                provider.canCancelShipment(shipment)
                                    ? () => _confirmCancelShipment(shipment)
                                    : null,
                            onCallReceiver:
                                shipment.recipientPhone.trim().isNotEmpty
                                    ? () => _callRecipient(shipment)
                                    : null,
                            onOpenMap: (_hasValidCoordinates(
                                      shipment.driverLatitude,
                                      shipment.driverLongitude,
                                    ) ||
                                    _hasValidCoordinates(
                                      shipment.storeLatitude,
                                      shipment.storeLongitude,
                                    ))
                                ? () => _openMap(shipment)
                                : null,
                            driverRatingSection:
                                _buildDriverRatingSection(shipment),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(ShipmentInstantprovider provider) {
    switch (provider.errorType) {
      case InstantShipmentErrorType.unauthorized:
        return _copy(
          context,
          'Your session has expired or is no longer valid. Please log in again.',
          'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
        );
      case InstantShipmentErrorType.network:
        return _copy(
          context,
          'Unable to connect to the server. Check your internet and try again.',
          'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
        );
      case InstantShipmentErrorType.generic:
      case InstantShipmentErrorType.none:
        return _safeMessage(
          provider.errorMessage,
          fallback: _copy(
            context,
            'Unable to load instant shipments. Please try again.',
            'تعذر تحميل الشحنات الفورية. حاول مرة أخرى.',
          ),
        );
    }
  }

  String _deliveryTypeLabel(Shipment shipment) {
    return _localizedValue(
      english: shipment.typeNameEn,
      arabic: shipment.typeNameAr,
      fallbackEnglish: 'Instant delivery',
      fallbackArabic: 'توصيل فوري',
    );
  }

  String _statusLabel(Shipment shipment) {
    return _localizedValue(
      english: shipment.statusNameEn,
      arabic: shipment.statusNameAr,
      fallbackEnglish: _statusFallback(shipment.shipmentStatusId).$1,
      fallbackArabic: _statusFallback(shipment.shipmentStatusId).$2,
    );
  }

  String _stageLabel(Shipment shipment) {
    if (_isCompletedStatus(shipment.shipmentStatusId)) {
      return _copy(context, 'Completed', 'مكتملة');
    }
    if (_isCancelledStatus(shipment.shipmentStatusId)) {
      return _copy(context, 'Cancelled', 'ملغاة');
    }
    if (shipment.driverId == null) {
      return _copy(context, 'Waiting for driver', 'بانتظار سائق');
    }
    if (shipment.shipmentStatusId == 4 || shipment.shipmentStatusId == 5) {
      return _copy(context, 'In delivery', 'قيد التوصيل');
    }
    return _copy(context, 'In progress', 'قيد المعالجة');
  }

  String _createdLabel(Shipment shipment) {
    final createdSource = shipment.createdAt.isNotEmpty
        ? shipment.createdAt
        : shipment.shipmentDate;
    final dateLabel = shipment.formattedShipmentDate;

    if (createdSource.isEmpty) {
      return _copy(context, 'Date not available', 'التاريخ غير متوفر');
    }

    try {
      final relative = Logic.getCreatedFrom(createdSource);
      return '$dateLabel • $relative';
    } catch (_) {
      return dateLabel;
    }
  }

  String _localizedValue({
    required String? english,
    required String? arabic,
    required String fallbackEnglish,
    required String fallbackArabic,
  }) {
    if (AppLocalizations.isRTL && arabic != null && arabic.trim().isNotEmpty) {
      return arabic.trim();
    }
    if (!AppLocalizations.isRTL &&
        english != null &&
        english.trim().isNotEmpty) {
      return english.trim();
    }
    return _copy(context, fallbackEnglish, fallbackArabic);
  }

  (String, String) _statusFallback(int statusId) {
    switch (statusId) {
      case 1:
        return ('Pending', 'قيد الانتظار');
      case 2:
        return ('Processing', 'قيد التجهيز');
      case 3:
        return ('Dispatched', 'تم الشحن');
      case 4:
        return ('In transit', 'في الطريق');
      case 5:
        return ('Out for delivery', 'في انتظار التسليم');
      case 6:
        return ('Delivered', 'تم التسليم');
      case 7:
        return ('Cancelled', 'تم الإلغاء');
      case 8:
        return ('Returned', 'تم الإرجاع');
      case 9:
        return ('Failed delivery', 'فشل التسليم');
      case 10:
        return ('Awaiting pickup', 'في انتظار الاستلام');
      case 11:
        return ('Completed', 'مكتمل');
      default:
        return ('Unknown status', 'حالة غير معروفة');
    }
  }

  bool _isCompletedStatus(int statusId) {
    return statusId == 6 || statusId == 11;
  }

  bool _isCancelledStatus(int statusId) {
    return statusId == 7 || statusId == 8 || statusId == 9;
  }

  bool _hasValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return false;
    }
    if (latitude == 0 || longitude == 0) {
      return false;
    }
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String _copy(BuildContext context, String english, String arabic) {
    return AppLocalizations.isRTL ? arabic : english;
  }

  String _safeMessage(String? message, {required String fallback}) {
    if (message == null || message.trim().isEmpty) {
      return fallback;
    }
    return message.trim();
  }
}

class _InstantShipmentsHeader extends StatelessWidget {
  const _InstantShipmentsHeader({
    required this.totalCount,
    required this.waitingCount,
    required this.activeCount,
    required this.isLoading,
  });

  final int totalCount;
  final int waitingCount;
  final int activeCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'شحنات فورية' : 'Instant Shipments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isRtl
                          ? 'تابع شحنات التوصيل الفوري لمتجرك'
                          : 'Track your instant delivery shipments',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      Text(
                        '$totalCount',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      isRtl ? 'شحنات' : 'Jobs',
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderMetric(
                icon: Icons.hourglass_bottom_rounded,
                label: isRtl ? 'بانتظار سائق' : 'Waiting Driver',
                value: waitingCount.toString(),
              ),
              _HeaderMetric(
                icon: Icons.local_shipping_outlined,
                label: isRtl ? 'قيد التوصيل' : 'In Delivery',
                value: activeCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
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

class _InstantSearchFilterBar extends StatelessWidget {
  const _InstantSearchFilterBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
    required this.onFilterTap,
    required this.hasActiveFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: isRtl
                  ? '\u0627\u0628\u062D\u062B \u0628\u0631\u0642\u0645 \u0627\u0644\u0634\u062D\u0646\u0629 \u0623\u0648 \u0627\u0644\u062D\u0627\u0644\u0629'
                  : 'Search by shipment number or status',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: hasText
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xff64748B),
                      tooltip: isRtl
                          ? '\u0645\u0633\u062D \u0627\u0644\u0628\u062D\u062B'
                          : 'Clear search',
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: hasActiveFilter ? AppColors.primary : const Color(0xffEFF6FF),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onFilterTap,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilter ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstantListMeta extends StatelessWidget {
  const _InstantListMeta({
    required this.visibleCount,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  final int visibleCount;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final pageText = totalPages > 1
        ? (isRtl
            ? 'الصفحة $currentPage من $totalPages'
            : 'Page $currentPage of $totalPages')
        : (isRtl ? 'صفحة واحدة' : 'Single page');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_agenda_outlined, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRtl
                  ? '$visibleCount نتيجة من أصل $totalCount شحنة فورية'
                  : '$visibleCount of $totalCount instant shipments',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff334155),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pageText,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantStatusChips extends StatelessWidget {
  const _InstantStatusChips({
    required this.selectedFilter,
    required this.onSelected,
  });

  final InstantShipmentFilter selectedFilter;
  final ValueChanged<InstantShipmentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final items = <(InstantShipmentFilter, String)>[
      (InstantShipmentFilter.all, isRtl ? 'الكل' : 'All'),
      (InstantShipmentFilter.waiting, isRtl ? 'قيد الانتظار' : 'Waiting'),
      (
        InstantShipmentFilter.waitingDriver,
        isRtl ? 'بانتظار سائق' : 'Waiting Driver',
      ),
      (InstantShipmentFilter.inDelivery, isRtl ? 'قيد التوصيل' : 'In Delivery'),
      (InstantShipmentFilter.completed, isRtl ? 'مكتملة' : 'Completed'),
      (InstantShipmentFilter.cancelled, isRtl ? 'ملغاة' : 'Cancelled'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedFilter == item.$1;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onSelected(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xffD7E2F3),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              item.$2,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff47607E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InstantPaginationControls extends StatelessWidget {
  const _InstantPaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final pages = _visiblePages(currentPage, totalPages);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _PageArrowButton(
            icon: isRtl
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            isEnabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: isRtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final page in pages) ...[
                    if (page == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '...',
                          style: TextStyle(
                            color: Color(0xff94A3B8),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _PageNumberButton(
                          page: page,
                          isSelected: page == currentPage,
                          onTap: () => onPageChanged(page),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _PageArrowButton(
            icon: isRtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            isEnabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _visiblePages(int currentPage, int totalPages) {
    if (totalPages <= 7) {
      return List<int>.generate(totalPages, (index) => index + 1);
    }

    final pages = <int?>[1];
    final start = (currentPage - 1).clamp(2, totalPages - 3);
    final end = (currentPage + 1).clamp(4, totalPages - 1);

    if (start > 2) {
      pages.add(null);
    }

    for (var page = start; page <= end; page++) {
      pages.add(page);
    }

    if (end < totalPages - 1) {
      pages.add(null);
    }

    pages.add(totalPages);
    return pages;
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? const Color(0xffEFF6FF) : const Color(0xffF1F5F9),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 19,
            color: isEnabled ? AppColors.primary : const Color(0xffCBD5E1),
          ),
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : const Color(0xffF8FAFC),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelected ? null : onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff334155),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstantFilterSheet extends StatelessWidget {
  const _InstantFilterSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShipmentInstantprovider>();
    final isRtl = AppLocalizations.isRTL;
    final filters = <_FilterSheetItem>[
      _FilterSheetItem(InstantShipmentFilter.all,
          isRtl ? '\u0627\u0644\u0643\u0644' : 'All', Icons.apps_rounded),
      _FilterSheetItem(
          InstantShipmentFilter.waiting,
          isRtl
              ? '\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631'
              : 'Waiting',
          Icons.hourglass_top_rounded),
      _FilterSheetItem(
          InstantShipmentFilter.waitingDriver,
          isRtl
              ? '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0633\u0627\u0626\u0642'
              : 'Waiting Driver',
          Icons.person_search_rounded),
      _FilterSheetItem(
          InstantShipmentFilter.inDelivery,
          isRtl
              ? '\u0642\u064A\u062F \u0627\u0644\u062A\u0648\u0635\u064A\u0644'
              : 'In Delivery',
          Icons.local_shipping_outlined),
      _FilterSheetItem(
          InstantShipmentFilter.completed,
          isRtl ? '\u0645\u0643\u062A\u0645\u0644\u0629' : 'Completed',
          Icons.verified_rounded),
      _FilterSheetItem(
          InstantShipmentFilter.cancelled,
          isRtl ? '\u0645\u0644\u063A\u0627\u0629' : 'Cancelled',
          Icons.cancel_outlined),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isRtl
                  ? '\u0641\u0644\u062A\u0631\u0629 \u0627\u0644\u0634\u062D\u0646\u0627\u062A \u0627\u0644\u0641\u0648\u0631\u064A\u0629'
                  : 'Filter instant shipments',
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRtl
                  ? '\u0627\u062E\u062A\u0631 \u0627\u0644\u062D\u0627\u0644\u0629 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0644\u0639\u0631\u0636 \u0627\u0644\u0634\u062D\u0646\u0627\u062A \u0628\u0633\u0631\u0639\u0629.'
                  : 'Choose a status to narrow the list quickly.',
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...filters.map((item) {
              final selected = provider.selectedFilter == item.filter;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected ? const Color(0xffEFF6FF) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xffE2E8F0),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      provider.setStatusFilter(item.filter);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xff64748B),
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xff334155),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetItem {
  const _FilterSheetItem(this.filter, this.label, this.icon);

  final InstantShipmentFilter filter;
  final String label;
  final IconData icon;
}

class _InstantInlineError extends StatelessWidget {
  const _InstantInlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffFDBA74)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xffC2410C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xff9A3412),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              AppLocalizations.isRTL ? 'إعادة المحاولة' : 'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantErrorState extends StatelessWidget {
  const _InstantErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xffFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xffDC2626),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.isRTL
                ? 'تعذر تحميل الشحنات الفورية'
                : 'Unable to load instant shipments',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppLocalizations.isRTL ? 'إعادة المحاولة' : 'Retry',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantEmptyState extends StatelessWidget {
  const _InstantEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCancelReasonSheet extends StatefulWidget {
  const _ShipmentCancelReasonSheet({required this.onSubmit, this.preview});

  final void Function(int reasonId, String? note) onSubmit;
  final Future<CancellationPreview?>? preview;

  @override
  State<_ShipmentCancelReasonSheet> createState() =>
      _ShipmentCancelReasonSheetState();
}

class _ShipmentCancelReasonSheetState
    extends State<_ShipmentCancelReasonSheet> {
  final _service = ShipmentActionReasonService();
  final _noteController = TextEditingController();
  late Future<List<ShipmentActionReason>> _future;
  ShipmentActionReason? _selectedReason;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchReasons(actionType: 'cancel');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: FutureBuilder<List<ShipmentActionReason>>(
                future: _future,
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final reasons = snapshot.data ?? const [];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xffCBD5E1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xffFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cancel_outlined,
                              color: Color(0xffDC2626),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl
                                      ? 'سبب إلغاء الشحنة'
                                      : 'Cancellation reason',
                                  style: const TextStyle(
                                    color: Color(0xff0F172A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isRtl
                                      ? 'اختر سبباً من القائمة لإكمال الإلغاء.'
                                      : 'Select a reason to complete cancellation.',
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
                      const SizedBox(height: 16),
                      if (loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (snapshot.hasError)
                        _ReasonSheetMessage(
                          icon: Icons.wifi_off_rounded,
                          color: const Color(0xffDC2626),
                          text: isRtl
                              ? 'تعذر تحميل أسباب الإلغاء. حاول مرة أخرى.'
                              : 'Unable to load cancellation reasons. Please try again.',
                          actionText: isRtl ? 'إعادة المحاولة' : 'Retry',
                          onAction: () {
                            setState(() {
                              _future = _service.fetchReasons(
                                actionType: 'cancel',
                              );
                            });
                          },
                        )
                      else if (reasons.isEmpty)
                        _ReasonSheetMessage(
                          icon: Icons.info_outline_rounded,
                          color: const Color(0xffF59E0B),
                          text: isRtl
                              ? 'لا توجد أسباب متاحة حالياً. يرجى التواصل مع الدعم.'
                              : 'No reasons are available right now. Please contact support.',
                        )
                      else ...[
                        if (widget.preview != null)
                          FutureBuilder<CancellationPreview?>(
                            future: widget.preview,
                            builder: (context, previewSnapshot) {
                              final preview = previewSnapshot.data;
                              if (preview == null || !preview.allowed) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CancelFeeNotice(
                                  preview: preview,
                                  isRtl: isRtl,
                                ),
                              );
                            },
                          ),
                        DropdownButtonFormField<ShipmentActionReason>(
                          initialValue: _selectedReason,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: isRtl ? 'اختر السبب' : 'Select reason',
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xffE2E8F0),
                              ),
                            ),
                          ),
                          items: reasons
                              .map(
                                (reason) => DropdownMenuItem(
                                  value: reason,
                                  child: Text(
                                    reason.title(isRtl),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedReason = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            labelText:
                                isRtl ? 'ملاحظة اختيارية' : 'Optional note',
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(isRtl ? 'رجوع' : 'Back'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _submitted
                                    ? null
                                    : () {
                                        if (_selectedReason == null) {
                                          AppUtils.showErrorDialog(
                                            isRtl
                                                ? 'يرجى اختيار سبب الإلغاء'
                                                : 'Please select a cancellation reason.',
                                          );
                                          return;
                                        }
                                        setState(() => _submitted = true);
                                        Navigator.pop(context);
                                        widget.onSubmit(
                                          _selectedReason!.id,
                                          _noteController.text.trim(),
                                        );
                                      },
                                child: Text(
                                  isRtl ? 'تأكيد الإلغاء' : 'Confirm cancel',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Financial consequence of cancelling now, as previewed by the server.
class _CancelFeeNotice extends StatelessWidget {
  const _CancelFeeNotice({required this.preview, required this.isRtl});

  final CancellationPreview preview;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final charged = preview.feeIfCancelled > 0;
    final amount = preview.feeIfCancelled.toStringAsFixed(2);
    final color = charged ? const Color(0xffB45309) : const Color(0xff047857);
    final text = charged
        ? (isRtl
            ? 'قد يترتب على الإلغاء الآن أجرة توصيل تصل إلى $amount د.أ لأن السائق قد انطلق. يتم تأكيد المبلغ النهائي بعد الإلغاء.'
            : 'Cancelling now may incur a delivery fee of up to $amount JOD because the driver has already left. The final amount is confirmed after cancellation.')
        : (isRtl
            ? 'لن تُستحق أجرة توصيل عند الإلغاء الآن.'
            : 'No delivery fee is due if you cancel now.');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            charged ? Icons.receipt_long_rounded : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonSheetMessage extends StatelessWidget {
  const _ReasonSheetMessage({
    required this.icon,
    required this.color,
    required this.text,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class _InstantLoadingState extends StatelessWidget {
  const _InstantLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => const _LoadingCard()),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 82, height: 26, radius: 999),
              Spacer(),
              _SkeletonBox(width: 42, height: 42, radius: 14),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonBox(width: 148, height: 18),
          SizedBox(height: 10),
          _SkeletonBox(width: 210, height: 12),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SkeletonBox(width: 110, height: 58, radius: 16),
              _SkeletonBox(width: 110, height: 58, radius: 16),
              _SkeletonBox(width: 110, height: 58, radius: 16),
            ],
          ),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 76, radius: 18),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 46, radius: 14),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
