import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class OrdersHeader extends StatefulWidget {
  const OrdersHeader({super.key, this.hrpadding, this.totalOrders});

  final double? hrpadding;
  final int? totalOrders;

  @override
  State<OrdersHeader> createState() => _OrdersHeaderState();
}

class _OrdersHeaderState extends State<OrdersHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final shipmentProvider =
          Provider.of<ShipmentProvider>(context, listen: false);
      shipmentProvider.searchShipments(_searchController.text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final shipmentProvider =
        Provider.of<ShipmentProvider>(context, listen: false);
    shipmentProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRTL = AppLocalizations.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Consumer<ShipmentProvider>(
        builder: (context, shipmentProvider, child) {
          // Get the total count from the provider, fallback to widget.totalOrders or 0
          final totalCount = shipmentProvider.shipmentsResponse?.count ??
              widget.totalOrders ??
              shipmentProvider.paginatedShipments.length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        widget.hrpadding ?? SizeConfig.widthMultiplier * 5),
                child: Text(
                  "$totalCount ${AppTranslations.getText('order')}",
                  style: textTheme.headlineSmall,
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
              ),
              const Spacer(),
              //SEARCH
              Container(
                height: SizeConfig.heightMultiplier * 3,
                width: SizeConfig.widthMultiplier * 55,
                decoration: BoxDecoration(
                  color: AppColors.searchBarColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.widthMultiplier * 2),
                child: Row(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Expanded(
                        child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: textTheme.bodySmall!.copyWith(
                          fontSize: SizeConfig.textMultiplier * 1.2,
                          fontWeight: FontWeight.w400),
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                          hintText: AppTranslations.getText('search_here'),
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: textTheme.bodySmall!.copyWith(
                              color: Colors.black38,
                              fontSize: SizeConfig.textMultiplier * 1.2,
                              fontWeight: FontWeight.w400),
                          border: InputBorder.none),
                      onChanged: (value) {
                        // Search is handled by the listener
                      },
                      onSubmitted: (value) {
                        // Hide keyboard when search is submitted
                        _searchFocusNode.unfocus();
                      },
                    )),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.grey,
                        ),
                      )
                    else
                      Image.asset(
                        AppImages.search,
                        height: 12,
                      ),
                  ],
                ),
              ),
              Spacing.x(2),
              //FILTER
            ],
          );
        },
      ),
    );
  }
}
