import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeTabbar extends StatelessWidget {
  const HomeTabbar({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final hasSubscription = profileProvider.profileInfo?.subscription == 1;
    final activeIndex = homeProvider.selectedTabIndex >= 0
        ? homeProvider.selectedTabIndex
        : tabController.index;

    if (!hasSubscription) {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xffF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: _TabbarItem(
          icon: AppImages.tabl,
          label: AppTranslations.getText('table_all_shipment'),
          isSelected: true,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: false,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        indicatorColor: Colors.transparent,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        onTap: context.read<HomeProvider>().setSelectedTab,
        tabs: [
          _TabbarItem(
            icon: AppImages.tabl,
            label: AppTranslations.getText('table_all_shipment'),
            isSelected: activeIndex == 0,
          ),
          _TabbarItem(
            icon: AppImages.shipment,
            label: AppTranslations.getText('shipment_instant'),
            isSelected: activeIndex == 1,
          ),
        ],
      ),
    );
  }
}

class _TabbarItem extends StatelessWidget {
  const _TabbarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  final String icon;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.white : const Color(0xff475569);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              color: foreground,
              height: 15,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.circle,
                color: foreground,
                size: 10,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
