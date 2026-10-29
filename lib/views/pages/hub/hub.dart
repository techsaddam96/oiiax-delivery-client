import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/bottmsheets/logout_sheet.dart';
import 'package:blockatie/views/pages/add_shipment/add_shipment.dart';
import 'package:blockatie/views/pages/blockatie_pro/blockatie_pro_page.dart';
import 'package:blockatie/views/pages/chat/conversations_page.dart';
import 'package:blockatie/views/pages/hub/profile/profile.dart';
import 'package:blockatie/views/pages/hub/setting/settings.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:blockatie/views/pages/my-store/my_store.dart';
import 'package:blockatie/views/pages/notifications/notifications.dart';
import 'package:blockatie/views/pages/statements/client_statements_page.dart';
import 'package:blockatie/views/pages/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        AppLocalizations.currentLocale.languageCode == 'ar' ? 'ar' : 'en';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatConversationsProvider>().refreshUnreadCount();
    });
  }

  void _openBottomTab(int index, {int? shipmentTabIndex}) {
    final bottomNavProvider = context.read<BottomNavProvider>();
    final homeProvider = context.read<HomeProvider>();

    if (shipmentTabIndex != null) {
      homeProvider.setSelectedTab(shipmentTabIndex);
      bottomNavProvider.setIndex(1);
      return;
    }

    if (index == 0) {
      homeProvider.resetToHome();
    }

    bottomNavProvider.setIndex(index);
  }

  void _openAddShipment() {
    Nav.to(
      const AddShipmentPage(),
      withNav: true,
      navIndex: 4,
    );
  }

  Future<void> _changeLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countryCode = language == 'en' ? 'US' : 'SA';

      await AppLocalizations.changeLanguage(Locale(language, countryCode));
      await prefs.setString('language', language);
      await prefs.setString('country', countryCode);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLanguage = language;
      });
      _showRestartDialog();
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppUtils.showErrorDialog(
        AppTranslations.getText('failed_change_language'),
      );
    }
  }

  void _showRestartDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '${AppTranslations.getText('language_changed')} ${_languageLabel(_selectedLanguage)}',
          ),
          content: Text(
            '${AppTranslations.getText('language_changed_successfully')}\n'
            '${AppTranslations.getText('restart_app_for_full_change')}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppTranslations.getText('later')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Nav.offAll(const SplashPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(AppTranslations.getText('restart_now')),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DFEC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        AppTranslations.getText('select_language'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xff0F172A),
                                ),
                      ),
                    ),
                  ),
                  _LanguageOptionTile(
                    title: _languageLabel('en'),
                    selected: _selectedLanguage == 'en',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _changeLanguage('en');
                    },
                  ),
                  _LanguageOptionTile(
                    title: _languageLabel('ar'),
                    selected: _selectedLanguage == 'ar',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _changeLanguage('ar');
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _languageLabel(String code) {
    return code == 'ar'
        ? AppTranslations.getText('hub_language_arabic')
        : AppTranslations.getText('hub_language_english');
  }

  String _copy(BuildContext context, String en, String ar) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profileInfo;
        final hasSubscription = profile?.subscription == 1;
        final horizontalPadding =
            MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;

        final mainActions = <_ClientActionData>[
          _ClientActionData(
            title: AppTranslations.getText('home'),
            subtitle: _copy(context, 'Dashboard overview', 'لوحة المتجر'),
            icon: Icons.home_rounded,
            color: AppColors.primary,
            onTap: () => _openBottomTab(0),
          ),
          _ClientActionData(
            title: AppTranslations.getText('my_store'),
            subtitle: _copy(context, 'Store details', 'تفاصيل المتجر'),
            icon: Icons.storefront_rounded,
            color: AppColors.primary,
            onTap: () => Nav.to(
              const MyStorePage(),
              withNav: true,
              navIndex: 4,
            ),
          ),
          _ClientActionData(
            title: AppTranslations.getText('wallet'),
            subtitle: _copy(context, 'Balance and payouts', 'الرصيد والسحب'),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xff16A06D),
            onTap: () => _openBottomTab(2),
          ),
          _ClientActionData(
            title: _copy(context, 'My Account', 'حسابي'),
            subtitle: _copy(context, 'Account details', 'بيانات الحساب'),
            icon: Icons.person_rounded,
            color: const Color(0xff7755D6),
            onTap: () => Nav.to(const ProfilePage(), navIndex: 3),
          ),
        ];

        final shippingActions = <_ClientActionData>[
          _ClientActionData(
            title: AppTranslations.getText('shipments'),
            subtitle: _copy(context, 'Track all shipments', 'متابعة الشحنات'),
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            onTap: () => _openBottomTab(1, shipmentTabIndex: 0),
          ),
          if (hasSubscription)
            _ClientActionData(
              title: AppTranslations.getText('shipment_instant'),
              subtitle: _copy(
                context,
                'Fast delivery requests',
                'طلبات التوصيل الفوري',
              ),
              icon: Icons.flash_on_rounded,
              color: AppColors.primary,
              onTap: () => _openBottomTab(1, shipmentTabIndex: 1),
            ),
          _ClientActionData(
            title: AppTranslations.getText('add_shipment'),
            subtitle: _copy(context, 'Create new shipment', 'إنشاء شحنة جديدة'),
            icon: Icons.add_box_rounded,
            color: const Color(0xff16A06D),
            onTap: _openAddShipment,
          ),
          _ClientActionData(
            title: AppTranslations.getText('conversations'),
            subtitle: AppTranslations.getText('hub_conversations_subtitle'),
            icon: Icons.forum_outlined,
            color: const Color(0xff4F46E5),
            showsChatUnreadBadge: true,
            onTap: _openConversations,
          ),
          _ClientActionData(
            title: _copy(context, 'My Statements', 'كشوفاتي'),
            subtitle: _copy(
                context, 'Account statement history', 'سجل كشوفات الحساب'),
            icon: Icons.receipt_long_rounded,
            color: AppColors.primary,
            onTap: () => Nav.to(
              const ClientStatementsPage(),
              withNav: true,
              navIndex: 4,
            ),
          ),
          _ClientActionData(
            title: _copy(context, 'Support', 'الدعم'),
            subtitle: _copy(context, 'Help and assistance', 'المساعدة والدعم'),
            icon: Icons.support_agent_rounded,
            color: const Color(0xffF59E0B),
            onTap: () => Nav.to(
              const SupportAssistancePage(),
              withNav: true,
              navIndex: 4,
            ),
          ),
        ];

        final tools = <_ClientToolData>[
          _ClientToolData(
            title: AppTranslations.getText('notifications'),
            subtitle: AppTranslations.getText('hub_notifications_subtitle'),
            icon: Icons.notifications_none_rounded,
            onTap: () => Nav.to(
              const NotificationsPage(showBackButton: true),
              withNav: true,
              navIndex: 3,
            ),
          ),
          _ClientToolData(
            title: AppTranslations.getText('edit_accounts'),
            subtitle: AppTranslations.getText('hub_settings_subtitle'),
            icon: Icons.settings_rounded,
            onTap: () => Nav.to(const SettingsPage()),
          ),
          _ClientToolData(
            title: AppTranslations.getText('language'),
            subtitle: _languageLabel(_selectedLanguage),
            icon: Icons.language_rounded,
            onTap: _showLanguageSheet,
          ),
          _ClientToolData(
            title: AppTranslations.getText('blockatie_pro'),
            subtitle: AppTranslations.getText('hub_pro_subtitle'),
            icon: Icons.workspace_premium_rounded,
            onTap: () => Nav.to(
              const BlockatieProPage(),
              withNav: true,
              navIndex: 4,
            ),
          ),
          _ClientToolData(
            title: AppTranslations.getText('logout'),
            subtitle: AppTranslations.getText('hub_logout_subtitle'),
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: 0.5),
                isScrollControlled: true,
                builder: (_) => const LogoutBottomSheet(),
              );
            },
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xffF4F7FB),
          body: SafeArea(
            child: Column(
              children: [
                _ClientHubHeader(
                  title: AppTranslations.getText('hub'),
                  subtitle:
                      AppTranslations.getText('hub_everything_in_one_place'),
                  onNotificationsTap: () => Nav.to(
                    const NotificationsPage(showBackButton: true),
                    withNav: true,
                    navIndex: 3,
                  ),
                  onProfileTap: () => Nav.to(const ProfilePage(), navIndex: 3),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      132,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ClientSectionTitle(
                          title: AppTranslations.getText('hub_main'),
                          subtitle: _copy(
                            context,
                            'Move between your main store pages',
                            'تنقل سريع بين صفحات المتجر',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ClientActionSection(actions: mainActions),
                        const SizedBox(height: 22),
                        _ClientSectionTitle(
                          title: AppTranslations.getText('hub_operations'),
                          subtitle: _copy(
                            context,
                            'Open shipments and daily tools quickly',
                            'افتح الشحنات وأدوات العمل بسرعة',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ClientActionSection(actions: shippingActions),
                        const SizedBox(height: 22),
                        _ClientSectionTitle(
                          title: AppTranslations.getText('hub_more_tools'),
                          subtitle: AppTranslations.getText('hub_quick_access'),
                        ),
                        const SizedBox(height: 12),
                        _ClientToolList(tools: tools),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openConversations() {
    Nav.to(const ConversationsPage(), withNav: true, navIndex: 4);
  }
}

class _ClientHubHeader extends StatelessWidget {
  const _ClientHubHeader({
    required this.title,
    required this.subtitle,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Selector<NotificationProvider, int>(
            selector: (_, provider) => provider.unreadCount,
            builder: (context, unreadCount, _) {
              return _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationsTap,
                tooltip: AppTranslations.getText('notifications'),
                badgeCount: unreadCount,
              );
            },
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
            tooltip: AppTranslations.getText('profile'),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xffF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: AppColors.primary,
                ),
                if (badgeCount > 0)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
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

class _ClientSectionTitle extends StatelessWidget {
  const _ClientSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ClientActionSection extends StatelessWidget {
  const _ClientActionSection({required this.actions});

  final List<_ClientActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 330 ? 1 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: _ClientActionCard(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ClientActionCard extends StatelessWidget {
  const _ClientActionCard({required this.action});

  final _ClientActionData action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 92),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child:
                              Icon(action.icon, color: action.color, size: 22),
                        ),
                        if (action.showsChatUnreadBadge)
                          const PositionedDirectional(
                            top: -5,
                            end: -5,
                            child: _ChatUnreadBadge(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.subtitle,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatUnreadBadge extends StatelessWidget {
  const _ChatUnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Selector<ChatConversationsProvider, int>(
      selector: (_, provider) => provider.unreadCount,
      builder: (context, unreadCount, _) {
        if (unreadCount <= 0) return const SizedBox.shrink();

        final label = unreadCount > 99 ? '99+' : '$unreadCount';
        return Semantics(
          label: '${AppTranslations.getText('conversations')}: $label',
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xffE53935),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientToolList extends StatelessWidget {
  const _ClientToolList({required this.tools});

  final List<_ClientToolData> tools;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          for (var index = 0; index < tools.length; index++) ...[
            _ClientToolTile(tool: tools[index]),
            if (index != tools.length - 1)
              const Divider(height: 1, color: Color(0xffECF1F8)),
          ],
        ],
      ),
    );
  }
}

class _ClientToolTile extends StatelessWidget {
  const _ClientToolTile({required this.tool});

  final _ClientToolData tool;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        tool.isDestructive ? const Color(0xffEF4444) : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tool.icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
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
              const SizedBox(width: 10),
              Icon(
                AppLocalizations.isRTL
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 18,
                color: const Color(0xff94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff0F172A),
                      ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : const Color(0xff94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 18}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xffE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _ClientActionData {
  const _ClientActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.showsChatUnreadBadge = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showsChatUnreadBadge;
}

class _ClientToolData {
  const _ClientToolData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}
