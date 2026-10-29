import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/delivery_type_service.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:blockatie/services/in_app_notification_service.dart';
import 'package:blockatie/services/status_service.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/add_shipment/add_shipment.dart';
import 'package:blockatie/views/pages/home/components/header.dart';
import 'package:blockatie/views/pages/home/components/latest_shipments_section.dart';
import 'package:blockatie/views/pages/home/tabs/all-shipments/table_all_shipment.dart';
import 'package:blockatie/views/pages/home/tabs/shipment-instant/shipment_instant.dart';
import 'package:blockatie/views/pages/my-store/my_store.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/client_welcome_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  TabController? tabController;
  bool _didBootstrap = false;

  final InAppNotificationService _inAppNotificationService =
      InAppNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAfterFirstFrame();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tabController ??= TabController(length: 2, vsync: this);
  }

  Future<void> getStatistics() async {
    await context.read<ProfileProvider>().fetchClientStatistics();
  }

  Future<void> getShipments() async {
    await context.read<ShipmentProvider>().getClientShipments(force: true);
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    if (!mounted || _didBootstrap) {
      return;
    }
    _didBootstrap = true;

    final session = await AuthService.getSession();
    if (!mounted || !session.isValid) {
      return;
    }
    FirebaseService.authenticatedShellReady();

    final profileProvider = context.read<ProfileProvider>();
    final shipmentProvider = context.read<ShipmentProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (profileProvider.profileInfo == null && !profileProvider.isLoading) {
      unawaited(profileProvider.fetchClientProfile());
    }
    if (shipmentProvider.shipmentsResponse == null &&
        !shipmentProvider.isLoading) {
      unawaited(shipmentProvider.getClientShipments());
    }
    unawaited(profileProvider.fetchClientStatistics());
    if (notificationProvider.notificationData == null &&
        !notificationProvider.isLoading) {
      unawaited(notificationProvider.fetchClientNotifications());
    }

    unawaited(_startDeferredServices(session));
  }

  Future<void> _startDeferredServices(ClientSession session) async {
    await FirebaseService.initialize();
    await Future.wait([
      FirebaseService.syncClientMessagingSetup(
        clientId: session.clientId,
        apiKey: session.apiKey,
      ),
      DeliveryTypeService.loadDeliveryTypes(),
      StatusService.loadStatusConfig(),
    ]);
    if (!mounted) {
      return;
    }
    await _inAppNotificationService.checkAndDisplay(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inAppNotificationService.dispose();
    tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      unawaited(
        context.read<ProfileProvider>().fetchClientProfile(silent: true),
      );
      unawaited(_inAppNotificationService.checkAndDisplay(context));
    }
  }

  Widget _buildTabViews() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final hasSubscription = profileProvider.profileInfo?.subscription == 1;
        final views = <Widget>[
          const TableAllShipment(),
          hasSubscription ? const ShipmentInstant() : const SizedBox.shrink(),
        ];

        return TabBarView(
          controller: tabController!,
          physics: hasSubscription
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: views,
        );
      },
    );
  }

  void _openShipmentsTab(int tabIndex) {
    final hasInstantAccess =
        context.read<ProfileProvider>().profileInfo?.subscription == 1;
    if (tabIndex == 1 && !hasInstantAccess) {
      tabIndex = 0;
    }
    context.read<HomeProvider>().setSelectedTab(tabIndex);
    context.read<BottomNavProvider>().setIndex(1);
  }

  void _openHomeStore() {
    Nav.to(
      const MyStorePage(),
      withNav: true,
      navIndex: 0,
    );
  }

  void _openAddShipment() {
    Nav.to(
      const AddShipmentPage(),
      withNav: true,
      navIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (tabController == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.bgColor,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final requestedTabIndex = context
        .select<HomeProvider, int>((provider) => provider.selectedTabIndex);
    final hasInstantAccess = context.select<ProfileProvider, bool>(
      (provider) => provider.profileInfo?.subscription == 1,
    );
    final selectedTabIndex =
        requestedTabIndex == 1 && !hasInstantAccess ? 0 : requestedTabIndex;

    if (requestedTabIndex == 1 && !hasInstantAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<HomeProvider>().setSelectedTab(0);
      });
    }

    if (selectedTabIndex != -1 &&
        tabController!.index != selectedTabIndex &&
        mounted) {
      tabController!.animateTo(selectedTabIndex);
    }

    final isDashboard = selectedTabIndex == -1;
    final shipmentsHeader = _resolveShipmentsHeader(context, selectedTabIndex);

    return UpgradeAlert(
      showIgnore: false,
      barrierDismissible: false,
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xffF4F7FB),
          body: Column(
            children: [
              HomeHeader(
                tabController: isDashboard ? null : tabController!,
                notificationCount: 12,
                showSearchFiled: false,
                title: isDashboard
                    ? AppTranslations.getText('home')
                    : shipmentsHeader.$1,
                subtitle: isDashboard
                    ? AppTranslations.getText('hub_home_subtitle')
                    : shipmentsHeader.$2,
              ),
              Expanded(
                child:
                    isDashboard ? _buildInitialHomeContent() : _buildTabViews(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialHomeContent() {
    return Consumer2<ProfileProvider, ShipmentProvider>(
      builder: (context, profileProvider, shipmentProvider, _) {
        final stats = profileProvider.statistics;
        final profile = profileProvider.profileInfo;
        final hasSubscription = profile?.subscription == 1;
        final waitingForDriver = _waitingForDriverCount(shipmentProvider);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              getStatistics(),
              getShipments(),
              context.read<ProfileProvider>().fetchClientProfile(silent: true),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClientWelcomeSummaryCard(
                  profile: profile,
                  stats: stats,
                ),
                const SizedBox(height: 18),
                if (waitingForDriver > 0) ...[
                  _DriverAttentionCard(
                    count: waitingForDriver,
                    onTap: () => _openShipmentsTab(0),
                  ),
                  const SizedBox(height: 12),
                ],
                _SectionHeader(
                  title: AppTranslations.getText('hub_operations'),
                  subtitle: AppTranslations.getText('hub_track_orders'),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(
                  actions: [
                    _DashboardAction(
                      title: AppTranslations.getText('add_shipment'),
                      subtitle: AppTranslations.getText(
                        'hub_add_shipment_subtitle',
                      ),
                      icon: Icons.add_box_rounded,
                      color: const Color(0xff16A06D),
                      onTap: _openAddShipment,
                    ),
                    _DashboardAction(
                      title: AppTranslations.getText('table_all_shipment'),
                      subtitle: AppTranslations.getText(
                        'hub_all_shipments_subtitle',
                      ),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      onTap: () => _openShipmentsTab(0),
                    ),
                    if (hasSubscription)
                      _DashboardAction(
                        title: AppTranslations.getText('shipment_instant'),
                        subtitle: AppTranslations.getText(
                          'hub_instant_shipments_subtitle',
                        ),
                        icon: Icons.flash_on_rounded,
                        color: AppColors.primary,
                        onTap: () => _openShipmentsTab(1),
                      ),
                    _DashboardAction(
                      title: AppTranslations.getText('my_store'),
                      subtitle:
                          AppTranslations.getText('hub_my_store_subtitle'),
                      icon: Icons.storefront_rounded,
                      color: const Color(0xff7755D6),
                      onTap: _openHomeStore,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: AppTranslations.getText('store_statistics'),
                  subtitle: _copy(
                    context,
                    'A clear view of your current store performance.',
                    'نظرة واضحة على أداء المتجر الحالي.',
                  ),
                ),
                const SizedBox(height: 12),
                _StatsGrid(stats: stats),
                const SizedBox(height: 18),
                LatestShipmentsSection(
                  onViewAll: () => _openShipmentsTab(0),
                  onOpenShipment: (shipment) {
                    Nav.to(
                      OrderDetailPage(
                        orderId: shipment.id,
                        orderStatus: shipment.statusNameEn,
                      ),
                      withNav: true,
                      navIndex: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _waitingForDriverCount(ShipmentProvider shipmentProvider) {
    const finalStatuses = <int>{6, 7, 8, 9, 11};
    final shipments =
        shipmentProvider.shipmentsResponse?.shipments ?? const <Shipment>[];

    return shipments.where((shipment) {
      final hasDriver = (shipment.driverId ?? 0) > 0;
      return !hasDriver && !finalStatuses.contains(shipment.shipmentStatusId);
    }).length;
  }

  (String, String) _resolveShipmentsHeader(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return (
          AppTranslations.getText('shipment_instant'),
          _copy(
            context,
            'Track the available fast shipment opportunities for your store.',
            'تابع فرص الشحنات السريعة المتاحة لمتجرك.',
          ),
        );
      default:
        return (
          AppTranslations.getText('shipments'),
          _copy(
            context,
            'Track all your store shipments from one place.',
            'تابع جميع شحنات متجرك من مكان واحد.',
          ),
        );
    }
  }
}

class _DriverAttentionCard extends StatelessWidget {
  const _DriverAttentionCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffFED7AA)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffFFEDD5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Color(0xffC2410C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getText('no_driver_assigned'),
                      style: const TextStyle(
                        color: Color(0xff9A3412),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count ${AppTranslations.getText('shipments')}',
                      style: const TextStyle(
                        color: Color(0xffC2410C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xffC2410C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ClientStatisticsData? stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        title: AppTranslations.getText('shipments'),
        value: '${stats?.shipments ?? 0}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _StatCardData(
        title: AppTranslations.getText('in_progress'),
        value: '${stats?.shipmentsInProgress ?? 0}',
        icon: Icons.local_shipping_outlined,
        color: AppColors.primary,
      ),
      _StatCardData(
        title: AppTranslations.getText('delivered'),
        value: '${stats?.shipmentsDelivered ?? 0}',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xff16A06D),
      ),
      _StatCardData(
        title: AppTranslations.getText('cancelled'),
        value: '${stats?.cancelledShipments ?? 0}',
        icon: Icons.cancel_outlined,
        color: const Color(0xffEF4444),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 620
            ? 3
            : constraints.maxWidth < 330
                ? 1
                : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) =>
                  SizedBox(width: width, child: _StatCard(data: card)))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              data.value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 620
            ? 3
            : constraints.maxWidth < 330
                ? 1
                : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map((action) => SizedBox(
                  width: width, child: _QuickActionTile(action: action)))
              .toList(),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
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

String _copy(BuildContext context, String en, String ar) {
  return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}
