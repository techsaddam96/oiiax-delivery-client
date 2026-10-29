import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientShipmentCategory {
  static const String all = 'all';
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String issues = 'issues';
}

class ClientShipmentsOverviewCard extends StatelessWidget {
  const ClientShipmentsOverviewCard({
    super.key,
    required this.totalCount,
    required this.visibleCount,
    required this.hasScopedView,
    required this.isLoading,
  });

  final int totalCount;
  final int visibleCount;
  final bool hasScopedView;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.4,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$totalCount',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _copy(context, 'Shipments', 'شحنة'),
                        style: const TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(context, 'Shipments', 'الشحنات'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _copy(
                    context,
                    'Track all store shipments in one place.',
                    'تابع جميع شحنات متجرك من مكان واحد.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OverviewPill(
                      label: _copy(
                        context,
                        'Scheduled & active shipments',
                        'الشحنات المجدولة والنشطة',
                      ),
                    ),
                    if (hasScopedView)
                      _OverviewPill(
                        label: _copy(
                          context,
                          'Showing $visibleCount',
                          'المعروض $visibleCount',
                        ),
                        filled: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 23,
                ),
                const SizedBox(height: 4),
                Text(
                  _copy(context, 'Live', 'مباشر'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class ClientShipmentsSearchFilterBar extends StatelessWidget {
  const ClientShipmentsSearchFilterBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onOpenFilters,
    required this.activeFilterCount,
    this.onClearSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback onOpenFilters;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: _copy(
                context,
                'Search by shipment number or receiver',
                'ابحث برقم الشحنة أو اسم المستلم',
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xff64748B),
              ),
              suffixIcon: controller.text.trim().isNotEmpty
                  ? IconButton(
                      onPressed: onClearSearch,
                      tooltip: _copy(context, 'Clear search', 'مسح البحث'),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xff64748B),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
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
                borderSide: BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onOpenFilters,
            child: Ink(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0F172A).withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  if (activeFilterCount > 0)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

class ClientShipmentsActiveFilters extends StatelessWidget {
  const ClientShipmentsActiveFilters({
    super.key,
    required this.items,
    required this.onClearAll,
  });

  final List<ClientActiveFilterChipData> items;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _copy(context, 'Active filters', 'الفلاتر المفعلة'),
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearAll,
              child: Text(_copy(context, 'Clear all', 'مسح الكل')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Material(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: item.onRemove,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 14, color: item.color),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: item.color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.close_rounded,
                              size: 15, color: item.color),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class ClientShipmentSearchNotice extends StatelessWidget {
  const ClientShipmentSearchNotice({
    super.key,
    required this.query,
    required this.count,
    required this.onClear,
  });

  final String query;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _copy(
                context,
                'Results for "$query": $count shipments',
                'نتائج البحث عن "$query": $count شحنة',
              ),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(_copy(context, 'Clear', 'مسح')),
          ),
        ],
      ),
    );
  }
}

class ClientActiveFilterChipData {
  const ClientActiveFilterChipData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.label,
    this.filled = false,
  });

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: filled ? 0 : 0.14),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? AppColors.primary : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ClientShipmentCategoryBar extends StatelessWidget {
  const ClientShipmentCategoryBar({
    super.key,
    required this.selectedCategory,
    required this.counts,
    required this.onSelected,
  });

  final String selectedCategory;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        key: ClientShipmentCategory.all,
        label: _copy(context, 'All', '\u0627\u0644\u0643\u0644'),
        icon: Icons.apps_rounded,
      ),
      (
        key: ClientShipmentCategory.pending,
        label: _copy(context, 'Waiting',
            '\u0628\u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631'),
        icon: Icons.hourglass_top_rounded,
      ),
      (
        key: ClientShipmentCategory.inProgress,
        label: _copy(context, 'In progress',
            '\u0642\u064A\u062F \u0627\u0644\u062A\u0646\u0641\u064A\u0630'),
        icon: Icons.local_shipping_outlined,
      ),
      (
        key: ClientShipmentCategory.completed,
        label: _copy(context, 'Delivered', '\u0645\u0633\u0644\u0645\u0629'),
        icon: Icons.verified_rounded,
      ),
      (
        key: ClientShipmentCategory.issues,
        label: _copy(context, 'Issues', '\u0645\u0634\u0627\u0643\u0644'),
        icon: Icons.report_problem_outlined,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in items) ...[
            _CategoryChip(
              label: item.label,
              icon: item.icon,
              count: counts[item.key] ?? 0,
              isSelected: selectedCategory == item.key,
              onTap: () => onSelected(item.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class ClientShipmentListCard extends StatelessWidget {
  const ClientShipmentListCard({
    super.key,
    required this.shipment,
    required this.onTap,
    this.onCall,
    this.onMap,
    this.onContactCompany,
    this.isOpeningChat = false,
    this.driverRatingSection,
  });

  static const Set<int> _finalStatuses = {6, 7, 8, 9, 11};

  final Shipment shipment;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMap;
  final VoidCallback? onContactCompany;
  final bool isOpeningChat;
  final Widget? driverRatingSection;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _effectiveStatusLabel(context, shipment);
    final typeLabel = deliveryTypeLabel(context, shipment);
    final statusColor = _effectiveStatusColor(shipment);
    final waitingDriver = _isWaitingForDriver(shipment);
    final finalStatus = _isFinalStatus(shipment);
    final assignedDriver = _hasAssignedDriver(shipment);
    final policyNumber = _safeValue(
      shipment.policyNum,
      _copy(context, 'No shipment number',
          '\u0644\u0627 \u064A\u0648\u062C\u062F \u0631\u0642\u0645 \u0634\u062D\u0646\u0629'),
    );
    final recipient = _safeValue(
      shipment.recipientName,
      _copy(context, 'Not available',
          '\u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631'),
    );
    final phone = _safeValue(
      shipment.recipientPhone,
      _copy(context, 'Not available',
          '\u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631'),
    );
    final address = _safeValue(
      shipment.deliveryAddress,
      _copy(context, 'Not available',
          '\u063A\u064A\u0631 \u0645\u062A\u0648\u0641\u0631'),
    );
    final createdAt = formatShipmentDateTime(context, shipment.createdAt);
    final shipmentValue = '${moneyLabel(shipment.totalCost.toString())} JOD';
    final driverLabel = assignedDriver
        ? _safeValue(
            shipment.driverName ?? '',
            _copy(context, 'Driver assigned',
                '\u062A\u0645 \u062A\u0639\u064A\u064A\u0646 \u0633\u0627\u0626\u0642'),
          )
        : _copy(context, 'No driver yet',
            '\u0644\u0627 \u064A\u0648\u062C\u062F \u0633\u0627\u0626\u0642 \u0628\u0639\u062F');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: finalStatus ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: waitingDriver
                  ? const Color(0xffFDBA74)
                  : const Color(0xffE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _ShipmentChip(
                              label: statusLabel,
                              color: statusColor,
                              icon: waitingDriver
                                  ? Icons.person_search_rounded
                                  : _statusIcon(shipment),
                              isProminent: waitingDriver,
                            ),
                            _ShipmentChip(
                              label: typeLabel,
                              color: AppColors.primary,
                              icon: Icons.local_shipping_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          policyNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipient,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff334155),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusIconBox(
                      color: statusColor, icon: _statusIcon(shipment)),
                ],
              ),
              if (waitingDriver) ...[
                const SizedBox(height: 12),
                _WaitingDriverStrip(
                  message: _copy(
                    context,
                    'Waiting for a driver to accept this shipment',
                    '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0642\u0628\u0648\u0644 \u0623\u062D\u062F \u0627\u0644\u0633\u0627\u0626\u0642\u064A\u0646 \u0644\u0647\u0630\u0647 \u0627\u0644\u0634\u062D\u0646\u0629',
                  ),
                ),
              ],
              if (finalStatus) ...[
                const SizedBox(height: 12),
                _FinalShipmentStrip(statusLabel: statusLabel),
              ],
              const SizedBox(height: 12),
              _RouteSummary(
                pickupLabel: _copy(context, 'Pickup',
                    '\u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645'),
                pickupValue: typeLabel,
                deliveryLabel: _copy(context, 'Delivery',
                    '\u0627\u0644\u062A\u0633\u0644\u064A\u0645'),
                deliveryValue: address,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final itemWidth = (constraints.maxWidth - gap) / 2;
                  final facts = [
                    _MiniFact(
                      icon: Icons.schedule_rounded,
                      label: _copy(
                          context, 'Time', '\u0627\u0644\u0648\u0642\u062A'),
                      value: createdAt,
                      color: AppColors.primary,
                    ),
                    _MiniFact(
                      icon: Icons.payments_outlined,
                      label: _copy(context, 'Total including delivery',
                          '\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0634\u062D\u0646\u0629 \u0634\u0627\u0645\u0644 \u0627\u0644\u062A\u0648\u0635\u064A\u0644'),
                      value: shipmentValue,
                      color: const Color(0xff16A06D),
                    ),
                    _MiniFact(
                      icon: assignedDriver
                          ? Icons.verified_user_outlined
                          : Icons.person_search_rounded,
                      label: _copy(context, 'Driver',
                          '\u0627\u0644\u0633\u0627\u0626\u0642'),
                      value: driverLabel,
                      color: assignedDriver
                          ? const Color(0xff0F766E)
                          : const Color(0xffF59E0B),
                    ),
                    if (phone.trim().isNotEmpty)
                      _MiniFact(
                        icon: Icons.phone_outlined,
                        label: _copy(context, 'Phone',
                            '\u0627\u0644\u0647\u0627\u062A\u0641'),
                        value: phone,
                        color: const Color(0xff7755D6),
                      ),
                  ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final fact in facts)
                        SizedBox(width: itemWidth, child: fact),
                    ],
                  );
                },
              ),
              if (driverRatingSection != null) ...[
                const SizedBox(height: 12),
                driverRatingSection!,
              ],
              const SizedBox(height: 12),
              if (finalStatus)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey('shipment-contact-company-${shipment.id}'),
                    onPressed: isOpeningChat ? null : onContactCompany,
                    icon: isOpeningChat
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.forum_outlined, size: 19),
                    label: Text(
                      _copy(
                        context,
                        'Contact the company',
                        '\u062a\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0634\u0631\u0643\u0629',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: Text(
                          _copy(context, 'Details',
                              '\u0627\u0644\u062A\u0641\u0627\u0635\u064A\u0644'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SquareActionButton(
                      tooltip: _copy(
                          context, 'Call', '\u0627\u062A\u0635\u0627\u0644'),
                      icon: Icons.call_outlined,
                      onTap: shipment.recipientPhone.trim().isEmpty
                          ? null
                          : onCall,
                    ),
                    const SizedBox(width: 8),
                    _SquareActionButton(
                      tooltip: _copy(context, 'Map',
                          '\u0627\u0644\u062E\u0631\u064A\u0637\u0629'),
                      icon: Icons.map_outlined,
                      onTap: shipment.deliveryAddress.trim().isEmpty
                          ? null
                          : onMap,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasAssignedDriver(Shipment shipment) {
    return (shipment.driverId != null && shipment.driverId! > 0) ||
        (shipment.driverName != null && shipment.driverName!.trim().isNotEmpty);
  }

  static bool _isWaitingForDriver(Shipment shipment) {
    final statusId = shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;
    return shipment.deliveryTypeId == 1 &&
        !_hasAssignedDriver(shipment) &&
        !_finalStatuses.contains(statusId);
  }

  static bool _isFinalStatus(Shipment shipment) {
    final statusId = shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;
    return _finalStatuses.contains(statusId);
  }

  static String _effectiveStatusLabel(BuildContext context, Shipment shipment) {
    if (_isWaitingForDriver(shipment)) {
      return _copy(context, 'Waiting for driver',
          '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0633\u0627\u0626\u0642');
    }
    return shipmentStatusLabel(context, shipment);
  }

  static Color _effectiveStatusColor(Shipment shipment) {
    if (_isWaitingForDriver(shipment)) {
      return const Color(0xffF59E0B);
    }
    return shipmentStatusColor(shipment);
  }

  static IconData _statusIcon(Shipment shipment) {
    if (_isWaitingForDriver(shipment)) {
      return Icons.person_search_rounded;
    }
    final statusId = shipment.shipmentStatusId != 0
        ? shipment.shipmentStatusId
        : shipment.shipmentStatus;
    if (statusId == 6 || statusId == 11) return Icons.verified_rounded;
    if (statusId == 7 || statusId == 8 || statusId == 9) {
      return Icons.report_problem_outlined;
    }
    if (statusId == 3 || statusId == 4 || statusId == 5) {
      return Icons.route_rounded;
    }
    return Icons.hourglass_top_rounded;
  }
}

class ClientShipmentsStateCard extends StatelessWidget {
  const ClientShipmentsStateCard({
    super.key,
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

class ClientShipmentsLoadingList extends StatelessWidget {
  const ClientShipmentsLoadingList({super.key});

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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

bool matchesShipmentCategory(Shipment shipment, String category) {
  final statusId = shipment.shipmentStatusId != 0
      ? shipment.shipmentStatusId
      : shipment.shipmentStatus;

  switch (category) {
    case ClientShipmentCategory.pending:
      return statusId == 1 || statusId == 2 || statusId == 10;
    case ClientShipmentCategory.inProgress:
      return statusId == 3 || statusId == 4 || statusId == 5;
    case ClientShipmentCategory.completed:
      return statusId == 6 || statusId == 11;
    case ClientShipmentCategory.issues:
      return statusId == 7 || statusId == 8 || statusId == 9;
    default:
      return true;
  }
}

String shipmentStatusLabel(BuildContext context, Shipment shipment) {
  final statusAr = shipment.statusNameAr?.trim() ?? '';
  final statusEn = shipment.statusNameEn?.trim() ?? '';
  final messageAr = shipment.messageAr?.trim() ?? '';
  final messageEn = shipment.messageEn?.trim() ?? '';

  if (_isArabic(context)) {
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

String deliveryTypeLabel(BuildContext context, Shipment shipment) {
  final typeAr = shipment.typeNameAr?.trim() ?? '';
  final typeEn = shipment.typeNameEn?.trim() ?? '';
  final legacyType = shipment.deliveryTypeNameEn.trim();
  final isArabic = _isArabic(context);

  if (isArabic) {
    if (typeAr.isNotEmpty) {
      return typeAr;
    }
    if (shipment.deliveryTypeId >= 1 && shipment.deliveryTypeId <= 7) {
      return deliveryTypeLabelFromId(context, shipment.deliveryTypeId);
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

  return deliveryTypeLabelFromId(context, shipment.deliveryTypeId);
}

Color shipmentStatusColor(Shipment shipment) {
  final statusId = shipment.shipmentStatusId != 0
      ? shipment.shipmentStatusId
      : shipment.shipmentStatus;

  if (statusId == 6 || statusId == 11) {
    return const Color(0xff16A06D);
  }
  if (statusId == 7 || statusId == 8 || statusId == 9) {
    return const Color(0xffEF4444);
  }
  if (statusId == 3 || statusId == 4 || statusId == 5) {
    return AppColors.primary;
  }
  if (statusId == 1 || statusId == 2 || statusId == 10) {
    return const Color(0xffF59E0B);
  }

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

String deliveryTypeLabelFromId(BuildContext context, int deliveryTypeId) {
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

String shipmentStatusFallbackLabel(BuildContext context, int statusId) {
  return switch (statusId) {
    1 => _copy(context, 'Pending', 'قيد الانتظار'),
    2 => _copy(context, 'Processing', 'قيد التجهيز'),
    3 => _copy(context, 'Dispatched', 'تم الشحن'),
    4 => _copy(context, 'In transit', 'في الطريق'),
    5 => _copy(context, 'Out for delivery', 'في انتظار التسليم'),
    6 => _copy(context, 'Delivered', 'تم التسليم'),
    7 => _copy(context, 'Cancelled', 'تم الإلغاء'),
    8 => _copy(context, 'Returned', 'تم الإرجاع'),
    9 => _copy(context, 'Failed delivery', 'فشل التسليم'),
    10 => _copy(context, 'Awaiting pickup', 'في انتظار الاستلام'),
    11 => _copy(context, 'Completed', 'مكتمل'),
    _ => _copy(context, 'Not available', 'غير متوفر'),
  };
}

String formatShipmentDateTime(BuildContext context, String raw) {
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

    final now = JordanTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final valueDay = DateTime(parsed.year, parsed.month, parsed.day);
    final timeLabel = DateFormat('h:mm a')
        .format(parsed)
        .replaceAll('AM', _copy(context, 'AM', 'ص'))
        .replaceAll('PM', _copy(context, 'PM', 'م'));

    if (valueDay == today) {
      return '${_copy(context, 'Today', 'اليوم')} $timeLabel';
    }

    if (valueDay == today.subtract(const Duration(days: 1))) {
      return '${_copy(context, 'Yesterday', 'أمس')} $timeLabel';
    }

    return '${DateFormat('dd/MM/yyyy').format(parsed)} • $timeLabel';
  } catch (_) {
    return trimmed;
  }
}

String moneyLabel(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null) {
    return raw.trim().isEmpty ? '-' : raw.trim();
  }
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? value.toStringAsFixed(0) : fixed;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.white : const Color(0xff334155);
    final background = isSelected ? AppColors.primary : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xffE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
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

class _ShipmentChip extends StatelessWidget {
  const _ShipmentChip({
    required this.label,
    required this.color,
    required this.icon,
    this.isProminent = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isProminent ? 12 : 10,
        vertical: isProminent ? 8 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isProminent ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: color.withValues(alpha: isProminent ? 0.28 : 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isProminent ? 15 : 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: isProminent ? 12 : 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  const _StatusIconBox({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _WaitingDriverStrip extends StatelessWidget {
  const _WaitingDriverStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffFDBA74)),
      ),
      child: Row(
        children: [
          const Icon(Icons.manage_search_rounded,
              color: Color(0xffC2410C), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff9A3412),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalShipmentStrip extends StatelessWidget {
  const _FinalShipmentStrip({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffCBD5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: Color(0xff475569),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(
                    context,
                    'This shipment is finished',
                    '\u062d\u0627\u0644\u0629 \u0627\u0644\u0634\u062d\u0646\u0629 \u0645\u0646\u062a\u0647\u064a\u0629',
                  ),
                  style: const TextStyle(
                    color: Color(0xff334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _copy(
                    context,
                    'Final status: $statusLabel. Contact the company for more information.',
                    '\u0627\u0644\u062d\u0627\u0644\u0629 \u0627\u0644\u0646\u0647\u0627\u0626\u064a\u0629: $statusLabel. \u062a\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0634\u0631\u0643\u0629 \u0644\u0645\u0639\u0631\u0641\u0629 \u0627\u0644\u0645\u0632\u064a\u062f.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 11,
                    height: 1.4,
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

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.pickupLabel,
    required this.pickupValue,
    required this.deliveryLabel,
    required this.deliveryValue,
  });

  final String pickupLabel;
  final String pickupValue;
  final String deliveryLabel;
  final String deliveryValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          _ShipmentInfoRow(
            icon: Icons.storefront_outlined,
            label: pickupLabel,
            value: pickupValue,
          ),
          const SizedBox(height: 9),
          _ShipmentInfoRow(
            icon: Icons.location_on_outlined,
            label: deliveryLabel,
            value: deliveryValue,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 11.5,
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

class _ShipmentInfoRow extends StatelessWidget {
  const _ShipmentInfoRow({
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

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.tooltip,
    required this.icon,
    this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.08)
                : const Color(0xffE2E8F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : const Color(0xffE2E8F0),
            ),
          ),
          child: Icon(
            icon,
            color: isEnabled ? AppColors.primary : const Color(0xff94A3B8),
            size: 20,
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

String _safeValue(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

bool _isArabic(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ar';
}

String _copy(BuildContext context, String en, String ar) {
  return _isArabic(context) ? ar : en;
}
