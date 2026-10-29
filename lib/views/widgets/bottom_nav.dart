import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/home/home.dart';
import 'package:blockatie/views/pages/hub/hub.dart';
import 'package:blockatie/views/pages/notifications/notifications.dart';
import 'package:blockatie/views/pages/wallet/wallet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({
    super.key,
    this.overlayPage,
    this.initialIndex = 0,
  });

  final Widget? overlayPage;
  final int initialIndex;

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final Set<int> _builtPageSlots = {0};
  late final ChatLauncherProvider _chatLauncherProvider;

  late final List<Widget Function()> _pageBuilders = [
    () => const HomePage(),
    () => const WalletPage(),
    () => const NotificationsPage(),
    () => const HubPage(),
  ];

  @override
  void initState() {
    super.initState();
    _chatLauncherProvider = context.read<ChatLauncherProvider>();
    final navProvider = context.read<BottomNavProvider>();
    if (navProvider.selectedIndex != widget.initialIndex) {
      navProvider.setIndex(widget.initialIndex);
    }
    if (widget.overlayPage != null) {
      navProvider.showOverlay(widget.overlayPage!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatLauncherProvider.setAuthenticatedShellVisible(true);
      }
    });
  }

  @override
  void dispose() {
    _chatLauncherProvider.setAuthenticatedShellVisible(false);
    super.dispose();
  }

  int _pageSlotForNavIndex(int navIndex) {
    switch (navIndex) {
      case 0:
      case 1:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  void _handleNavTap(int index) {
    final navProvider = context.read<BottomNavProvider>();
    final homeProvider = context.read<HomeProvider>();

    if (index == 0) {
      homeProvider.resetToHome();
    } else if (index == 1) {
      homeProvider.setSelectedTab(0);
    }

    navProvider.setIndex(index);
    if (index == 0 || index == 1 || index == 2) {
      unawaited(context.read<ProfileProvider>().fetchClientStatistics());
    }
    if (index == 2) {
      unawaited(context.read<RequestsProvider>().fetchRequests());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, navProvider, _) {
        final selectedIndex = navProvider.selectedIndex.clamp(0, 4).toInt();
        final pageSlot = _pageSlotForNavIndex(selectedIndex);
        // `extendBody` adds the navigation bar height to MediaQuery.padding for
        // every page in this shell.  Once the IME is visible that padding would
        // survive above the keyboard, even though the bar itself is covered,
        // leaving a blank strip on nested form pages.  Remove the bar from the
        // Scaffold while text is being edited so the inherited bottom padding
        // accurately represents only the system inset.
        final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
        _builtPageSlots.add(pageSlot);

        return PopScope(
          canPop: selectedIndex == 0 && navProvider.overlayPage == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              return;
            }

            if (navProvider.overlayPage != null) {
              navProvider.clearOverlay();
              return;
            }

            if (selectedIndex != 0) {
              context.read<HomeProvider>().resetToHome();
              navProvider.setIndex(0);
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            extendBody: !keyboardVisible,
            backgroundColor: const Color(0xffF4F7FB),
            body: Stack(
              children: [
                IndexedStack(
                  index: pageSlot,
                  children: List.generate(_pageBuilders.length, (index) {
                    if (!_builtPageSlots.contains(index)) {
                      return const SizedBox.shrink();
                    }
                    return _pageBuilders[index]();
                  }),
                ),
                if (widget.overlayPage != null) widget.overlayPage!,
                if (navProvider.overlayPage != null) navProvider.overlayPage!,
              ],
            ),
            bottomNavigationBar: keyboardVisible
                ? null
                : SafeArea(
                    top: false,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xff0F172A).withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _BottomNavBrandStrip(),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _NavItem(
                                icon: Icons.home_rounded,
                                label: AppTranslations.getText('home'),
                                index: 0,
                                selectedIndex: selectedIndex,
                                onTap: () => _handleNavTap(0),
                              ),
                              _NavItem(
                                icon: Icons.local_shipping_outlined,
                                activeIcon: Icons.local_shipping_rounded,
                                label: AppTranslations.getText('shipments'),
                                index: 1,
                                selectedIndex: selectedIndex,
                                onTap: () => _handleNavTap(1),
                              ),
                              _NavItem(
                                icon: Icons.account_balance_wallet_outlined,
                                activeIcon:
                                    Icons.account_balance_wallet_rounded,
                                label: AppTranslations.getText('wallet'),
                                index: 2,
                                selectedIndex: selectedIndex,
                                onTap: () => _handleNavTap(2),
                              ),
                              Consumer<NotificationProvider>(
                                builder: (context, provider, _) {
                                  return _NavItem(
                                    icon: Icons.notifications_none_rounded,
                                    activeIcon: Icons.notifications_rounded,
                                    label: AppTranslations.getText(
                                        'notifications'),
                                    index: 3,
                                    selectedIndex: selectedIndex,
                                    badgeCount: provider.unreadCount,
                                    onTap: () => _handleNavTap(3),
                                  );
                                },
                              ),
                              _NavItem(
                                icon: Icons.widgets_outlined,
                                activeIcon: Icons.widgets_rounded,
                                label: AppTranslations.getText('hub'),
                                index: 4,
                                selectedIndex: selectedIndex,
                                onTap: () => _handleNavTap(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _BottomNavBrandStrip extends StatelessWidget {
  const _BottomNavBrandStrip();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        children: [
          const Expanded(child: _BrandDivider()),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xffF8FBFF),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xffD7E5F4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.iconImage,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'OIIAX MERCHANT',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: _BrandDivider()),
        ],
      ),
    );
  }
}

class _BrandDivider extends StatelessWidget {
  const _BrandDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xffE2E8F0),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.activeIcon,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 53,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? activeIcon ?? icon : icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xff94A3B8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xff64748B),
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (badgeCount > 0)
                  PositionedDirectional(
                    top: 6,
                    end: 12,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
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
      ),
    );
  }
}
