import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/home/components/tabbar.dart';
import 'package:blockatie/views/pages/home/filter/filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    this.tabController,
    this.showSearchFiled = false,
    this.notificationCount = 0,
    this.title,
    this.subtitle,
    this.showNotificationShortcut = true,
    this.showProfileShortcut = true,
    this.showHelpButton = false,
    this.onHelpTap,
  });

  final TabController? tabController;
  final int notificationCount;
  final bool? showSearchFiled;
  final String? title;
  final String? subtitle;
  final bool showNotificationShortcut;
  final bool showProfileShortcut;
  final bool showHelpButton;
  final VoidCallback? onHelpTap;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      context.read<ShipmentProvider>().searchShipments(_searchController.text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ShipmentProvider>().clearSearch();
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSearchVisible = oldWidget.showSearchFiled ?? false;
    final isSearchVisible = widget.showSearchFiled ?? false;
    if (wasSearchVisible && !isSearchVisible && _searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.showSearchFiled ?? false;
    final hasTabs = widget.tabController != null;
    final title = widget.title ?? 'OIIAX MERCHANT';
    final subtitle = widget.subtitle ??
        AppTranslations.getText('hub_everything_in_one_place');

    return Container(
      color: const Color(0xffF6F8FC),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0F172A).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showHelpButton)
                          _HeaderTextButton(
                            label: AppTranslations.getText('help'),
                            onTap: widget.onHelpTap,
                          ),
                        if (widget.showHelpButton &&
                            (widget.showProfileShortcut ||
                                widget.showNotificationShortcut))
                          const SizedBox(width: 8),
                        if (widget.showProfileShortcut)
                          _HeaderIconButton(
                            icon: Icons.person_outline_rounded,
                            tooltip: AppTranslations.getText('profile'),
                            onTap: () {
                              context.read<HomeProvider>().resetToHome();
                              context.read<BottomNavProvider>().setIndex(4);
                            },
                          ),
                        if (widget.showProfileShortcut &&
                            widget.showNotificationShortcut)
                          const SizedBox(width: 8),
                        if (widget.showNotificationShortcut)
                          Consumer<NotificationProvider>(
                            builder: (context, provider, _) {
                              return _HeaderIconButton(
                                icon: Icons.notifications_none_rounded,
                                tooltip:
                                    AppTranslations.getText('notifications'),
                                badgeCount: provider.unreadCount,
                                onTap: () {
                                  context.read<HomeProvider>().resetToHome();
                                  context.read<BottomNavProvider>().setIndex(3);
                                },
                              );
                            },
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
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
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
                  ],
                ),
                if (showSearch || hasTabs) ...[
                  const SizedBox(height: 16),
                  if (showSearch)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchFocusNode.unfocus(),
                            decoration: InputDecoration(
                              hintText: AppTranslations.getText(
                                'search_by_policy_status_type_or_product_type',
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xff64748B),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      color: const Color(0xff64748B),
                                      tooltip: AppTranslations.getText(
                                        'clear_search',
                                      ),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xffF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _HeaderIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: AppTranslations.getText('filter'),
                          isBright: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FilterPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (showSearch && hasTabs) const SizedBox(height: 12),
                  if (hasTabs) HomeTabbar(tabController: widget.tabController!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffEEF5FF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
    this.isBright = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;
  final bool isBright;

  @override
  Widget build(BuildContext context) {
    final background = isBright
        ? const Color(0xffEEF5FF)
        : const Color(0xffF1F5F9);
    final border = isBright
        ? const Color(0xffD8E8FF)
        : const Color(0xffE2E8F0);
    final foreground = AppColors.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: foreground,
                ),
              ),
              if (badgeCount > 0)
                PositionedDirectional(
                  top: 7,
                  end: 7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xffEF4444),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
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
