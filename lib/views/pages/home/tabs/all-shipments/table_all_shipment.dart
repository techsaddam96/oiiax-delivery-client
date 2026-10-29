import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/services/shipment_export_service.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/home/tabs/all-shipments/components/client_shipment_list_widgets.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/models/order_details.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/utils/shipment_chat_navigation.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/pagination_widget.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_bottom_sheet.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_button.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TableAllShipment extends StatefulWidget {
  const TableAllShipment({super.key, this.chatRepository, this.detailsLoader});
  final ChatRepository? chatRepository;
  final Future<OrderDetailsResponse?> Function(int)? detailsLoader;

  @override
  State<TableAllShipment> createState() => _TableAllShipmentState();
}

class _TableAllShipmentState extends State<TableAllShipment> {
  bool _didBootstrap = false;
  bool _isExporting = false;
  late final ShipmentChatNavigation _chatNavigation;
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _chatNavigation = ShipmentChatNavigation(
      repository: widget.chatRepository,
      detailsLoader: widget.detailsLoader,
    )..addListener(_chatOpeningChanged);
    final initialQuery = context.read<ShipmentProvider>().searchQuery;
    _searchController = TextEditingController(text: initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _chatNavigation.removeListener(_chatOpeningChanged);
    _chatNavigation.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted || _didBootstrap) {
      return;
    }
    _didBootstrap = true;

    final provider = context.read<ShipmentProvider>();
    if (!provider.hasLoaded && !provider.isLoading) {
      await provider.getClientShipments();
    }
  }

  Future<void> _refresh(ShipmentProvider provider) {
    return provider.getClientShipments(force: true);
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

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      context.read<ShipmentProvider>().searchShipments(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    context.read<ShipmentProvider>().clearSearch();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openFilterSheet(ShipmentProvider provider) async {
    final result = await showModalBottomSheet<_ShipmentsFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShipmentsFilterSheet(
        initialDeliveryTypeId: provider.selectedDeliveryTypeId,
        initialStatusId: provider.selectedShipmentStatusId,
        initialDate: provider.selectedShipmentDate,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.shouldReset) {
      provider.clearViewFilters();
      return;
    }

    provider.applyViewFilters(
      deliveryTypeId: result.deliveryTypeId,
      shipmentStatusId: result.shipmentStatusId,
      shipmentDate: result.shipmentDate,
    );
  }

  int _activeFilterCount(ShipmentProvider provider) {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) {
      count++;
    }
    if (provider.selectedDeliveryTypeId != null) {
      count++;
    }
    if (provider.selectedShipmentStatusId != null) {
      count++;
    }
    if (provider.selectedShipmentDate != null) {
      count++;
    }
    return count;
  }

  List<ClientActiveFilterChipData> _activeFilterChips(
    BuildContext context,
    ShipmentProvider provider,
  ) {
    final chips = <ClientActiveFilterChipData>[];

    if (_searchController.text.trim().isNotEmpty) {
      chips.add(
        ClientActiveFilterChipData(
          label: _copy(
            context,
            'Search: ${_searchController.text.trim()}',
            'بحث: ${_searchController.text.trim()}',
          ),
          icon: Icons.search_rounded,
          color: AppColors.primary,
          onRemove: _clearSearch,
        ),
      );
    }

    if (provider.selectedDeliveryTypeId != null) {
      chips.add(
        ClientActiveFilterChipData(
          label: _copy(
            context,
            'Type: ${deliveryTypeLabelFromId(context, provider.selectedDeliveryTypeId!)}',
            'النوع: ${deliveryTypeLabelFromId(context, provider.selectedDeliveryTypeId!)}',
          ),
          icon: Icons.local_shipping_outlined,
          color: AppColors.primary,
          onRemove: () {
            provider.applyViewFilters(
              deliveryTypeId: null,
              shipmentStatusId: provider.selectedShipmentStatusId,
              shipmentDate: provider.selectedShipmentDate,
            );
          },
        ),
      );
    }

    if (provider.selectedShipmentStatusId != null) {
      chips.add(
        ClientActiveFilterChipData(
          label: _copy(
            context,
            'Status: ${_statusLabelForId(context, provider.selectedShipmentStatusId!)}',
            'الحالة: ${_statusLabelForId(context, provider.selectedShipmentStatusId!)}',
          ),
          icon: Icons.fact_check_outlined,
          color: const Color(0xff7755D6),
          onRemove: () {
            provider.applyViewFilters(
              deliveryTypeId: provider.selectedDeliveryTypeId,
              shipmentStatusId: null,
              shipmentDate: provider.selectedShipmentDate,
            );
          },
        ),
      );
    }

    if (provider.selectedShipmentDate != null) {
      chips.add(
        ClientActiveFilterChipData(
          label: _copy(
            context,
            'Date: ${MaterialLocalizations.of(context).formatMediumDate(provider.selectedShipmentDate!)}',
            'التاريخ: ${MaterialLocalizations.of(context).formatMediumDate(provider.selectedShipmentDate!)}',
          ),
          icon: Icons.calendar_today_outlined,
          color: const Color(0xff16A06D),
          onRemove: () {
            provider.applyViewFilters(
              deliveryTypeId: provider.selectedDeliveryTypeId,
              shipmentStatusId: provider.selectedShipmentStatusId,
              shipmentDate: null,
            );
          },
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ShipmentProvider>(
        builder: (context, provider, _) {
          final shipments = provider.paginatedShipments;
          final hasScopedView = provider.isSearching || provider.hasViewFilters;
          final activeFilterChips = _activeFilterChips(context, provider);
          final counts = <String, int>{
            ShipmentProvider.categoryAll:
                provider.countForCategory(ShipmentProvider.categoryAll),
            ShipmentProvider.categoryPending:
                provider.countForCategory(ShipmentProvider.categoryPending),
            ShipmentProvider.categoryInProgress:
                provider.countForCategory(ShipmentProvider.categoryInProgress),
            ShipmentProvider.categoryCompleted:
                provider.countForCategory(ShipmentProvider.categoryCompleted),
            ShipmentProvider.categoryIssues:
                provider.countForCategory(ShipmentProvider.categoryIssues),
          };

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(provider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        ClientShipmentsOverviewCard(
                          totalCount: provider.totalCount,
                          visibleCount: provider.visibleCount,
                          hasScopedView: hasScopedView,
                          isLoading: provider.isLoading,
                        ),
                        const SizedBox(height: 12),
                        _ShipmentExportButton(
                          isExporting: _isExporting,
                          isEnabled: provider.allShipments.isNotEmpty,
                          shipmentCount: provider.allShipments.length,
                          onPressed: () => _exportShipments(provider),
                        ),
                        const SizedBox(height: 16),
                        ClientShipmentsSearchFilterBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          onClearSearch: _searchController.text.trim().isEmpty
                              ? null
                              : _clearSearch,
                          onOpenFilters: () => _openFilterSheet(provider),
                          activeFilterCount: _activeFilterCount(provider),
                        ),
                        if (activeFilterChips.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClientShipmentsActiveFilters(
                            items: activeFilterChips,
                            onClearAll: () {
                              _clearSearch();
                              provider.clearViewFilters();
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        ClientShipmentCategoryBar(
                          selectedCategory: provider.selectedCategory,
                          counts: counts,
                          onSelected: provider.setSelectedCategory,
                        ),
                        const SizedBox(height: 12),
                        _VisibleResultsStrip(
                          count: provider.visibleCount,
                          hasScopedView: hasScopedView,
                        ),
                        const SizedBox(height: 14),
                        if (provider.totalPages > 1 &&
                            provider.displayShipments.isNotEmpty) ...[
                          PaginationWidget(
                            currentPage: provider.currentPage,
                            totalPages: provider.totalPages,
                            onPageChanged: provider.setPage,
                            hasNextPage:
                                provider.currentPage < provider.totalPages,
                            hasPreviousPage: provider.currentPage > 1,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (provider.hasError &&
                            provider.hasLoaded &&
                            provider.displayShipments.isNotEmpty) ...[
                          ClientShipmentsStateCard(
                            icon: Icons.wifi_off_rounded,
                            accentColor: const Color(0xffEA580C),
                            backgroundColor: const Color(0xffFFF7ED),
                            borderColor: const Color(0xffFDBA74),
                            title: _errorTitle(context, provider.errorCode),
                            message: _errorMessage(context, provider.errorCode),
                            actionLabel: AppTranslations.getText('retry'),
                            onAction: () =>
                                provider.getClientShipments(force: true),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (provider.isLoading && !provider.hasLoaded)
                          const ClientShipmentsLoadingList()
                        else if (provider.hasError && !provider.hasLoaded)
                          ClientShipmentsStateCard(
                            icon: provider.errorCode == 'unauthorized'
                                ? Icons.lock_outline_rounded
                                : Icons.wifi_off_rounded,
                            accentColor: provider.errorCode == 'unauthorized'
                                ? const Color(0xffB45309)
                                : const Color(0xffEA580C),
                            backgroundColor:
                                provider.errorCode == 'unauthorized'
                                    ? const Color(0xffFFF7ED)
                                    : const Color(0xffFEF2F2),
                            borderColor: provider.errorCode == 'unauthorized'
                                ? const Color(0xffFCD34D)
                                : const Color(0xffFECACA),
                            title: _errorTitle(context, provider.errorCode),
                            message: _errorMessage(context, provider.errorCode),
                            actionLabel: AppTranslations.getText('retry'),
                            onAction: () =>
                                provider.getClientShipments(force: true),
                          )
                        else if (shipments.isEmpty)
                          ClientShipmentsStateCard(
                            icon: Icons.inventory_2_outlined,
                            accentColor: AppColors.primary,
                            backgroundColor: const Color(0xffF8FAFC),
                            borderColor: const Color(0xffE2E8F0),
                            title: hasScopedView ||
                                    provider.selectedCategory !=
                                        ShipmentProvider.categoryAll
                                ? _copy(
                                    context,
                                    'No matching shipments',
                                    'لا توجد شحنات مطابقة',
                                  )
                                : _copy(
                                    context,
                                    'No shipments',
                                    'لا توجد شحنات',
                                  ),
                            message: hasScopedView ||
                                    provider.selectedCategory !=
                                        ShipmentProvider.categoryAll
                                ? _copy(
                                    context,
                                    'Try adjusting the search text or selected filters.',
                                    'جرّب تعديل نص البحث أو الفلاتر المحددة.',
                                  )
                                : _copy(
                                    context,
                                    'Your store shipments will appear here as soon as they are created.',
                                    'ستظهر شحنات متجرك هنا بمجرد إنشائها.',
                                  ),
                          )
                        else
                          ...shipments.map(
                            (shipment) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: ClientShipmentListCard(
                                shipment: shipment,
                                onTap: () => _openShipmentDetails(shipment),
                                onCall: shipment.recipientPhone.trim().isEmpty
                                    ? null
                                    : () => _callPhone(shipment.recipientPhone),
                                onMap: shipment.deliveryAddress.trim().isEmpty
                                    ? null
                                    : () => _openMap(shipment.deliveryAddress),
                                onContactCompany: _chatNavigation.isOpening
                                    ? null
                                    : () => _openShipmentChat(shipment),
                                isOpeningChat:
                                    _chatNavigation.openingShipmentId ==
                                        shipment.id,
                                driverRatingSection:
                                    _buildDriverRatingSection(shipment),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabelForId(BuildContext context, int statusId) {
    final provider = context.read<ShipmentProvider>();
    final match = provider.allShipments.cast<Shipment?>().firstWhere(
      (shipment) {
        if (shipment == null) {
          return false;
        }
        final effectiveStatusId = shipment.shipmentStatusId != 0
            ? shipment.shipmentStatusId
            : shipment.shipmentStatus;
        return effectiveStatusId == statusId;
      },
      orElse: () => null,
    );

    if (match == null) {
      return shipmentStatusFallbackLabel(context, statusId);
    }

    return shipmentStatusLabel(context, match);
  }

  void _openShipmentDetails(Shipment shipment) {
    Nav.to(
      OrderDetailPage(
        orderId: shipment.id,
        orderStatus: shipment.statusNameEn,
      ),
      withNav: true,
      navIndex: 1,
    );
  }

  void _chatOpeningChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openShipmentChat(Shipment shipment) => _chatNavigation.open(
        context,
        shipmentId: shipment.id,
        isCurrent: () =>
            mounted &&
            context.read<BottomNavProvider>().selectedIndex == 1 &&
            context.read<BottomNavProvider>().overlayPage == null &&
            context
                .read<ShipmentProvider>()
                .allShipments
                .any((current) => current.id == shipment.id),
      );

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.trim()}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || launched) {
      return;
    }
    _showSnack(_copy(context, 'Unable to start call.', 'تعذر بدء الاتصال.'));
  }

  Future<void> _openMap(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      _showSnack(
        _copy(context, 'Location is not available.', 'الموقع غير متوفر.'),
      );
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || launched) {
      return;
    }
    _showSnack(_copy(context, 'Unable to open map.', 'تعذر فتح الخريطة.'));
  }

  Future<void> _exportShipments(ShipmentProvider provider) async {
    if (_isExporting) {
      return;
    }

    final shipments = provider.allShipments;
    if (shipments.isEmpty) {
      _showSnack(_copy(
        context,
        'There are no shipments to export.',
        'لا توجد شحنات لتصديرها.',
      ));
      return;
    }

    setState(() => _isExporting = true);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final result = await ShipmentExportService.exportAndOpen(
        shipments: shipments,
        isArabic: isArabic,
      );
      if (!mounted) {
        return;
      }
      _showSnack(
        result.wasOpened
            ? _copy(
                context,
                'Shipments Excel file is ready.',
                'ملف Excel للشحنات أصبح جاهزًا.',
              )
            : _copy(
                context,
                'The Excel file was saved. Install a compatible app to open it.',
                'تم حفظ ملف Excel. ثبّت تطبيقًا متوافقًا لفتحه.',
              ),
      );
    } on ShipmentExportException catch (error) {
      if (mounted) {
        _showSnack(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnack(
          _copy(
            context,
            'Unable to export shipments right now. Please try again.',
            'تعذر تصدير الشحنات حاليًا. حاول مرة أخرى.',
          ),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xffB42318) : null,
      ),
    );
  }
}

class _ShipmentExportButton extends StatelessWidget {
  const _ShipmentExportButton({
    required this.isExporting,
    required this.isEnabled,
    required this.shipmentCount,
    required this.onPressed,
  });

  final bool isExporting;
  final bool isEnabled;
  final int shipmentCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final label = isArabic ? 'تصدير كل الشحنات' : 'Export all shipments';
    final subtitle = isArabic
        ? '$shipmentCount شحنة - بيانات تشغيلية فقط'
        : '$shipmentCount shipments - operational data only';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isEnabled && !isExporting ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isExporting
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.file_download_outlined,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExporting
                          ? (isArabic
                              ? 'جارٍ تجهيز الملف...'
                              : 'Preparing file...')
                          : label,
                      style: const TextStyle(
                        color: Color(0xff102A43),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: isEnabled ? AppColors.primary : const Color(0xff94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibleResultsStrip extends StatelessWidget {
  const _VisibleResultsStrip({
    required this.count,
    required this.hasScopedView,
  });

  final int count;
  final bool hasScopedView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasScopedView
                  ? Icons.filter_alt_rounded
                  : Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasScopedView
                      ? _copy(context, 'Filtered shipments', 'الشحنات المطابقة')
                      : _copy(context, 'All shipments', 'جميع الشحنات'),
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasScopedView
                      ? _copy(
                          context,
                          '$count shipments match your current search and filters.',
                          '$count شحنة مطابقة للبحث والفلاتر الحالية.',
                        )
                      : _copy(
                          context,
                          '$count shipments are currently visible in this page.',
                          '$count شحنة ظاهرة حالياً في هذه الصفحة.',
                        ),
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class _ShipmentsFilterSheet extends StatefulWidget {
  const _ShipmentsFilterSheet({
    required this.initialDeliveryTypeId,
    required this.initialStatusId,
    required this.initialDate,
  });

  final int? initialDeliveryTypeId;
  final int? initialStatusId;
  final DateTime? initialDate;

  @override
  State<_ShipmentsFilterSheet> createState() => _ShipmentsFilterSheetState();
}

class _ShipmentsFilterSheetState extends State<_ShipmentsFilterSheet> {
  int? _selectedDeliveryTypeId;
  int? _selectedStatusId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryTypeId = widget.initialDeliveryTypeId;
    _selectedStatusId = widget.initialStatusId;
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xffF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _copy(context, 'Filters', 'الفلاتر'),
                            style: const TextStyle(
                              color: Color(0xff0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _copy(
                              context,
                              'Refine the shipment list using supported quick filters.',
                              'خصص قائمة الشحنات باستخدام الفلاتر السريعة المدعومة.',
                            ),
                            style: const TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FilterSectionCard(
                  title: _copy(context, 'Delivery type', 'نوع الشحنة'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _deliveryTypeOptions(context)
                        .map(
                          (option) => _FilterChoiceChip(
                            label: option.label,
                            selected: _selectedDeliveryTypeId == option.id,
                            onTap: () {
                              setState(() {
                                _selectedDeliveryTypeId =
                                    _selectedDeliveryTypeId == option.id
                                        ? null
                                        : option.id;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _FilterSectionCard(
                  title: _copy(context, 'Shipment status', 'حالة الشحنة'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOptions(context)
                        .map(
                          (option) => _FilterChoiceChip(
                            label: option.label,
                            selected: _selectedStatusId == option.id,
                            onTap: () {
                              setState(() {
                                _selectedStatusId =
                                    _selectedStatusId == option.id
                                        ? null
                                        : option.id;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _FilterSectionCard(
                  title: _copy(context, 'Shipment date', 'تاريخ الشحنة'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(
                          _selectedDate == null
                              ? _copy(
                                  context,
                                  'Choose a date',
                                  'اختر تاريخاً',
                                )
                              : MaterialLocalizations.of(context)
                                  .formatMediumDate(_selectedDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xffD7E5F4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _copy(context, 'Clear date', 'مسح التاريخ'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            const _ShipmentsFilterResult(shouldReset: true),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_copy(context, 'Reset', 'إعادة ضبط')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _ShipmentsFilterResult(
                              deliveryTypeId: _selectedDeliveryTypeId,
                              shipmentStatusId: _selectedStatusId,
                              shipmentDate: _selectedDate,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _copy(context, 'Apply filters', 'تطبيق الفلاتر'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSectionCard extends StatelessWidget {
  const _FilterSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xffF8FAFC),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff334155),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShipmentsFilterResult {
  const _ShipmentsFilterResult({
    this.deliveryTypeId,
    this.shipmentStatusId,
    this.shipmentDate,
    this.shouldReset = false,
  });

  final int? deliveryTypeId;
  final int? shipmentStatusId;
  final DateTime? shipmentDate;
  final bool shouldReset;
}

class _SimpleFilterOption {
  const _SimpleFilterOption({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;
}

List<_SimpleFilterOption> _deliveryTypeOptions(BuildContext context) {
  return List.generate(
    7,
    (index) => _SimpleFilterOption(
      id: index + 1,
      label: deliveryTypeLabelFromId(context, index + 1),
    ),
  );
}

List<_SimpleFilterOption> _statusOptions(BuildContext context) {
  return List.generate(
    11,
    (index) => _SimpleFilterOption(
      id: index + 1,
      label: shipmentStatusFallbackLabel(context, index + 1),
    ),
  );
}

String _errorTitle(BuildContext context, String? errorCode) {
  switch (errorCode) {
    case 'unauthorized':
      return _copy(context, 'Session expired', 'انتهت الجلسة');
    case 'network':
      return _copy(context, 'Network issue', 'مشكلة في الاتصال');
    default:
      return _copy(context, 'Unable to load shipments', 'تعذر تحميل الشحنات');
  }
}

String _errorMessage(BuildContext context, String? errorCode) {
  switch (errorCode) {
    case 'unauthorized':
      return _copy(
        context,
        'Please sign in again to continue.',
        'يرجى تسجيل الدخول مرة أخرى للمتابعة.',
      );
    case 'network':
      return _copy(
        context,
        'Unable to reach the server. Check your internet connection and try again.',
        'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
      );
    default:
      return _copy(
        context,
        'Please try again in a moment.',
        'حاول مرة أخرى بعد قليل.',
      );
  }
}

String _copy(BuildContext context, String en, String ar) {
  return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}
