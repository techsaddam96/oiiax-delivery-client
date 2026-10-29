import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/status_shipment_model.dart';
import 'package:blockatie/provider/filter.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/bottmsheets/calander_sheet.dart';
import 'package:blockatie/views/pages/home/tabs/all-shipments/components/client_shipment_list_widgets.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:blockatie/views/widgets/custom_dropdown_field.dart';
import 'package:blockatie/views/widgets/textfiled_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final provider = context.read<FilterProvider>();
      if (provider.statusShipmentData == null) {
        await provider.getStatusShipment();
      }
      if (!mounted) {
        return;
      }
      if (provider.drivers == null) {
        await provider.getDrivers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
        textDirection:
            AppLocalizations.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.bgColor,
          appBar: CustomAppBar(
            title: AppTranslations.getText('filter'),
            subtitleFont: 12,
            subtitle: _copy(
              context,
              'Refine shipments by date, driver, and shipment status.',
              'خصص نتائج الشحنات حسب التاريخ والسائق والحالة.',
            ),
          ),
          body: Consumer<FilterProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FilterPanel(provider: provider),
                    const SizedBox(height: 18),
                    _FilteredResultsHeader(
                      count: provider.shipments.length,
                      isLoading: provider.isLoadingFilter,
                    ),
                    const SizedBox(height: 14),
                    if (provider.isLoadingFilter)
                      const ClientShipmentsLoadingList()
                    else if (provider.hasError)
                      ClientShipmentsStateCard(
                        icon: Icons.wifi_off_rounded,
                        accentColor: const Color(0xffEA580C),
                        backgroundColor: const Color(0xffFFF7ED),
                        borderColor: const Color(0xffFDBA74),
                        title: _copy(
                          context,
                          'Unable to load shipments',
                          'تعذر تحميل الشحنات',
                        ),
                        message: _copy(
                          context,
                          'Please try changing the filters or try again in a moment.',
                          'جرّب تغيير الفلاتر أو أعد المحاولة بعد قليل.',
                        ),
                        actionLabel: AppTranslations.getText('retry'),
                        onAction: provider.getResultFilter,
                      )
                    else if (provider.shipments.isEmpty)
                      ClientShipmentsStateCard(
                        icon: Icons.filter_alt_off_rounded,
                        accentColor: AppColors.primary,
                        backgroundColor: const Color(0xffF8FAFC),
                        borderColor: const Color(0xffE2E8F0),
                        title: _copy(
                          context,
                          'No matching shipments',
                          'لا توجد شحنات مطابقة',
                        ),
                        message: _copy(
                          context,
                          'Try a different date, driver, or shipment status.',
                          'جرّب تاريخًا أو سائقًا أو حالة شحنة مختلفة.',
                        ),
                      )
                    else
                      ListView.separated(
                        itemCount: provider.shipments.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) {
                          final shipment = provider.shipments[index];
                          return ClientShipmentListCard(
                            shipment: shipment,
                            onTap: () {
                              Nav.to(
                                OrderDetailPage(
                                  orderId: shipment.id,
                                  orderStatus: shipment.statusNameEn,
                                ),
                                withNav: false,
                                navIndex: 1,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.provider});

  final FilterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            _copy(context, 'Search filters', 'فلاتر الشحنات'),
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _copy(
              context,
              'Use the available filters, then run one clean request.',
              'استخدم الفلاتر المتاحة ثم نفّذ طلب بحث واحد وواضح.',
            ),
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          TextFiledWidget(
            keyboardType: TextInputType.none,
            onTap: () => CalendarSheet.show(context),
            controller: provider.dateController,
            hint: _copy(context, 'Shipment date', 'تاريخ الشحنة'),
            isEnabled: true,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 14),
          _StatusDropdown(provider: provider),
          const SizedBox(height: 4),
          _DriverDropdown(provider: provider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.restart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_copy(context, 'Reset', 'إعادة ضبط')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: provider.isLoadingFilter
                      ? null
                      : provider.getResultFilter,
                  icon: provider.isLoadingFilter
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(
                    provider.isLoadingFilter
                        ? _copy(context, 'Searching...', 'جارٍ البحث...')
                        : _copy(context, 'Search', 'بحث'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.provider});

  final FilterProvider provider;

  @override
  Widget build(BuildContext context) {
    final statuses = provider.statusShipmentData?.status ?? <Status>[];

    if (provider.isLoading && statuses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomDropdownField<int>(
      value: provider.shipmentStatus == 0 ? null : provider.shipmentStatus,
      labelText: _copy(context, 'Shipment status', 'حالة الشحنة'),
      hintText: _copy(context, 'Select a shipment status', 'اختر حالة الشحنة'),
      items: statuses
          .map(
            (status) => DropdownMenuItem<int>(
              value: status.id,
              child: Text(
                AppLocalizations.isRTL && status.statusNameAr.trim().isNotEmpty
                    ? status.statusNameAr
                    : status.statusNameEn,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          provider.selectStatusId(value);
        }
      },
      enabled: statuses.isNotEmpty,
    );
  }
}

class _DriverDropdown extends StatelessWidget {
  const _DriverDropdown({required this.provider});

  final FilterProvider provider;

  @override
  Widget build(BuildContext context) {
    final drivers = provider.drivers?.drivers ?? [];

    if (provider.isLoading && drivers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomDropdownField<int>(
      value: provider.idDriver,
      labelText: _copy(context, 'Driver', 'السائق'),
      hintText: _copy(context, 'Select a driver', 'اختر سائقًا'),
      items: drivers
          .map(
            (driver) => DropdownMenuItem<int>(
              value: int.tryParse(driver.id) ?? 0,
              child: Text(driver.dname),
            ),
          )
          .toList(),
      onChanged: provider.selectDriver,
      enabled: drivers.isNotEmpty,
    );
  }
}

class _FilteredResultsHeader extends StatelessWidget {
  const _FilteredResultsHeader({
    required this.count,
    required this.isLoading,
  });

  final int count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _copy(context, 'Filtered shipments', 'نتائج الفلترة'),
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _copy(
                  context,
                  'Professional results based on your selected criteria.',
                  'نتائج واضحة واحترافية حسب الفلاتر التي اخترتها.',
                ),
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Text(
                  '$count ${_copy(context, 'Shipments', 'شحنات')}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ],
    );
  }
}

String _copy(BuildContext context, String en, String ar) {
  return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}
