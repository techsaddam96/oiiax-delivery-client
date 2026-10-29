import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:blockatie/views/widgets/pagination_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LatestShipmentsSection extends StatefulWidget {
  const LatestShipmentsSection({
    super.key,
    required this.onViewAll,
    required this.onOpenShipment,
  });

  final VoidCallback onViewAll;
  final ValueChanged<Shipment> onOpenShipment;

  @override
  State<LatestShipmentsSection> createState() => _LatestShipmentsSectionState();
}

class _LatestShipmentsSectionState extends State<LatestShipmentsSection> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _didSyncInitialValue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSyncInitialValue) {
      return;
    }

    final query = context.read<ShipmentProvider>().searchQuery;
    if (query.isNotEmpty) {
      _searchController.text = query;
    }
    _didSyncInitialValue = true;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      context.read<ShipmentProvider>().searchShipments(value);
    });
  }

  void _clearSearch() {
    setState(() {});
    _debounce?.cancel();
    _searchController.clear();
    context.read<ShipmentProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShipmentProvider>(
      builder: (context, provider, _) {
        final shipments = provider.paginatedShipments;
        final resultCount = provider.isSearching
            ? provider.filteredShipments.length
            : provider.totalCount;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LatestSectionHeader(
                title: AppTranslations.getText('recent_orders'),
                subtitle: _copy(
                  context,
                  'Track the newest shipment activity from one professional view.',
                  'تابع أحدث حركة للشحنات من واجهة واضحة واحترافية.',
                ),
                onViewAll: widget.onViewAll,
              ),
              const SizedBox(height: 14),
              _LatestShipmentsSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                count: resultCount,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
              if (provider.hasError &&
                  provider.displayShipments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InlineErrorBanner(
                  message: _copy(
                    context,
                    'Unable to refresh the latest shipments right now.',
                    'تعذر تحديث أحدث الشحنات حالياً.',
                  ),
                  onRetry: () {
                    provider.getClientShipments(force: true);
                  },
                ),
              ],
              const SizedBox(height: 14),
              if (provider.totalPages > 1 && shipments.isNotEmpty) ...[
                PaginationWidget(
                  currentPage: provider.currentPage,
                  totalPages: provider.totalPages,
                  onPageChanged: provider.setPage,
                  hasNextPage: provider.currentPage < provider.totalPages,
                  hasPreviousPage: provider.currentPage > 1,
                ),
                const SizedBox(height: 14),
              ],
              if (provider.isLoading && !provider.hasLoaded)
                const _LatestShipmentsLoadingState()
              else if (provider.hasError && !provider.hasLoaded)
                _SectionStateCard(
                  icon: Icons.wifi_off_rounded,
                  accentColor: const Color(0xffEA580C),
                  backgroundColor: const Color(0xffFFF7ED),
                  borderColor: const Color(0xffFDBA74),
                  title: _copy(
                    context,
                    'Unable to load the latest shipments.',
                    'تعذر تحميل أحدث الشحنات.',
                  ),
                  message: _copy(
                    context,
                    'Please try again in a moment.',
                    'حاول مرة أخرى بعد قليل.',
                  ),
                  actionLabel: AppTranslations.getText('retry'),
                  onAction: () {
                    provider.getClientShipments(force: true);
                  },
                )
              else if (shipments.isEmpty)
                _SectionStateCard(
                  icon: Icons.inventory_2_outlined,
                  accentColor: AppColors.primary,
                  backgroundColor: const Color(0xffF8FAFC),
                  borderColor: const Color(0xffE2E8F0),
                  title: _copy(
                    context,
                    'No latest shipments yet',
                    'لا توجد شحنات حديثة',
                  ),
                  message: _copy(
                    context,
                    'Your newest shipments will appear here once they are created.',
                    'ستظهر آخر شحناتك هنا عند إنشائها.',
                  ),
                )
              else
                Column(
                  children: [
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                      ),
                    ListView.separated(
                      itemCount: shipments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final shipment = shipments[index];
                        return _LatestShipmentCard(
                          shipment: shipment,
                          onTap: () => widget.onOpenShipment(shipment),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LatestSectionHeader extends StatelessWidget {
  const _LatestSectionHeader({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
  });

  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_outward_rounded, size: 16),
          label: Text(_copy(context, 'View all', 'عرض الكل')),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestShipmentsSearchBar extends StatelessWidget {
  const _LatestShipmentsSearchBar({
    required this.controller,
    required this.focusNode,
    required this.count,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int count;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final countChip = _ResultCountChip(count: count);
        final searchField = Material(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _copy(
                context,
                'Search by shipment number or recipient',
                'ابحث برقم الشحنة أو اسم المستلم',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.60),
                  width: 1.2,
                ),
              ),
            ),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: countChip,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            countChip,
          ],
        );
      },
    );
  }
}

class _ResultCountChip extends StatelessWidget {
  const _ResultCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count ${_copy(context, 'Orders', 'شحنات')}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestShipmentCard extends StatelessWidget {
  const _LatestShipmentCard({
    required this.shipment,
    required this.onTap,
  });

  final Shipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _shipmentStatusLabel(context, shipment);
    final statusColor = _statusColor(shipment);
    final typeLabel = _deliveryTypeLabel(context, shipment);
    final recipient = shipment.recipientName.trim().isEmpty
        ? _copy(context, 'Not available', 'غير متوفر')
        : shipment.recipientName.trim();
    final address = shipment.deliveryAddress.trim().isEmpty
        ? _copy(context, 'Not available', 'غير متوفر')
        : shipment.deliveryAddress.trim();
    final latestUpdate = _formatDateLabel(shipment.updatedAt);
    final createdAt = _formatDateLabel(shipment.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ShipmentStatusChip(
                    label: statusLabel,
                    color: statusColor,
                    icon: Icons.fact_check_outlined,
                  ),
                  _ShipmentStatusChip(
                    label: typeLabel,
                    color: AppColors.primary,
                    icon: Icons.category_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _copy(context, 'Shipment number', 'رقم الشحنة'),
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shipment.policyNum.trim().isEmpty
                              ? '-'
                              : shipment.policyNum.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          createdAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ShipmentInfoTile(
                icon: Icons.person_outline_rounded,
                label: _copy(context, 'Receiver', 'المستلم'),
                value: recipient,
              ),
              const SizedBox(height: 10),
              _ShipmentInfoTile(
                icon: Icons.location_on_outlined,
                label: _copy(context, 'Area', 'المنطقة'),
                value: address,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  const columnCount = 2;
                  const spacing = 10.0;
                  final itemWidth =
                      (constraints.maxWidth - (spacing * (columnCount - 1))) /
                          columnCount;
                  final metrics = [
                    _ShipmentMetricData(
                      label: _copy(context, 'Delivery time', 'وقت التسليم'),
                      value: shipment.formattedShipmentDate.trim().isEmpty
                          ? '-'
                          : shipment.formattedShipmentDate,
                      icon: Icons.schedule_rounded,
                      color: AppColors.primary,
                    ),
                    _ShipmentMetricData(
                      label: _copy(context, 'Total including delivery', 'إجمالي الشحنة شامل التوصيل'),
                      value: '${_money(shipment.totalCost.toString())} JOD',
                      icon: Icons.payments_outlined,
                      color: const Color(0xff16A06D),
                    ),
                    _ShipmentMetricData(
                      label: _copy(context, 'Latest update', 'آخر تحديث'),
                      value: latestUpdate,
                      icon: Icons.update_rounded,
                      color: const Color(0xff7755D6),
                    ),
                    _ShipmentMetricData(
                      label: _copy(context, 'Tracking type', 'نوع التوصيل'),
                      value: typeLabel,
                      icon: Icons.route_outlined,
                      color: AppColors.primary,
                    ),
                  ];

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics
                        .map(
                          (metric) => SizedBox(
                            width: itemWidth,
                            child: _ShipmentMetricCard(metric: metric),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    _copy(
                        context, 'Open shipment details', 'عرض تفاصيل الشحنة'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentInfoTile extends StatelessWidget {
  const _ShipmentInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xff64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShipmentMetricCard extends StatelessWidget {
  const _ShipmentMetricCard({required this.metric});

  final _ShipmentMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
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

class _ShipmentStatusChip extends StatelessWidget {
  const _ShipmentStatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFDBA74)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xffEA580C)),
          const SizedBox(width: 10),
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
            child: Text(AppTranslations.getText('retry')),
          ),
        ],
      ),
    );
  }
}

class _SectionStateCard extends StatelessWidget {
  const _SectionStateCard({
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestShipmentsLoadingState extends StatelessWidget {
  const _LatestShipmentsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _LoadingLine(width: 120),
              SizedBox(height: 12),
              _LoadingLine(width: 210, height: 18),
              SizedBox(height: 16),
              _LoadingLine(width: double.infinity),
              SizedBox(height: 10),
              _LoadingLine(width: 190),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _LoadingBox()),
                  SizedBox(width: 10),
                  Expanded(child: _LoadingBox()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({
    required this.width,
    this.height = 11,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ShipmentMetricData {
  const _ShipmentMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xffE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xff0F172A).withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

String _shipmentStatusLabel(BuildContext context, Shipment shipment) {
  final statusAr = shipment.statusNameAr?.trim() ?? '';
  final statusEn = shipment.statusNameEn?.trim() ?? '';
  final messageAr = shipment.messageAr?.trim() ?? '';
  final messageEn = shipment.messageEn?.trim() ?? '';

  if (Localizations.localeOf(context).languageCode == 'ar') {
    if (statusAr.isNotEmpty) {
      return statusAr;
    }
    if (messageAr.isNotEmpty) {
      return messageAr;
    }
  }

  if (statusEn.isNotEmpty) {
    return statusEn;
  }
  if (messageEn.isNotEmpty) {
    return messageEn;
  }
  if (statusAr.isNotEmpty) {
    return statusAr;
  }

  return _copy(context, 'Not available', 'غير متوفر');
}

String _deliveryTypeLabel(BuildContext context, Shipment shipment) {
  final typeAr = shipment.typeNameAr?.trim() ?? '';
  final typeEn = shipment.typeNameEn?.trim() ?? '';
  final legacyType = shipment.deliveryTypeNameEn.trim();
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  if (isArabic) {
    if (typeAr.isNotEmpty) {
      return typeAr;
    }
    if (shipment.deliveryTypeId >= 1 && shipment.deliveryTypeId <= 7) {
      return _deliveryTypeLabelFromId(context, shipment.deliveryTypeId);
    }
  }
  if (typeEn.isNotEmpty) {
    return typeEn;
  }
  if (typeAr.isNotEmpty) {
    return typeAr;
  }
  if (legacyType.isNotEmpty) {
    return legacyType;
  }

  return _deliveryTypeLabelFromId(context, shipment.deliveryTypeId);
}

String _deliveryTypeLabelFromId(
  BuildContext context,
  int deliveryTypeId,
) {
  return switch (deliveryTypeId) {
    1 => _copy(context, 'Instant', 'فوري'),
    2 => _copy(context, 'Scheduled', 'مجدول'),
    3 => _copy(context, 'Same-Day', 'نفس اليوم'),
    4 => _copy(context, 'Next-Day', 'اليوم التالي'),
    5 => _copy(context, 'Economy', 'اقتصادي'),
    6 => _copy(context, 'Express', 'سريع'),
    7 => _copy(context, 'Contactless', 'بدون تلامس'),
    _ => _copy(context, 'Not available', 'غير متوفر'),
  };
}

Color _statusColor(Shipment shipment) {
  final status =
      (shipment.statusNameEn ?? shipment.messageEn ?? '').toLowerCase();

  if (status.contains('deliver') || status.contains('complete')) {
    return const Color(0xff16A06D);
  }
  if (status.contains('cancel') ||
      status.contains('return') ||
      status.contains('fail')) {
    return const Color(0xffEF4444);
  }
  if (status.contains('progress') ||
      status.contains('transit') ||
      status.contains('dispatch') ||
      status.contains('out for')) {
    return AppColors.primary;
  }
  if (status.contains('pending') || status.contains('await')) {
    return const Color(0xffF59E0B);
  }

  return AppColors.primary;
}

String _formatDateLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '-';
  }

  try {
    final parsed = JordanTime.parse(
      trimmed,
    );
    if (parsed == null) {
      return trimmed;
    }
    return DateFormat('yyyy-MM-dd • HH:mm').format(parsed);
  } catch (_) {
    return trimmed;
  }
}

String _money(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null) {
    return raw.trim().isEmpty ? '-' : raw.trim();
  }
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? value.toStringAsFixed(0) : fixed;
}

String _copy(BuildContext context, String en, String ar) {
  return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}
