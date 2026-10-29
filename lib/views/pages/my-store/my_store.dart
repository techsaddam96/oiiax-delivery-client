import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/models/notifications.dart';
import 'package:blockatie/models/store_statistics.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/store_statistics_provider.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/hub/setting/settings.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  bool get _isArabic => AppLocalizations.isArabic;

  String _copy(String english, String arabic) {
    return _isArabic ? arabic : english;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadInitialData());
    });
  }

  Future<void> _loadInitialData() async {
    final profileProvider = context.read<ProfileProvider>();
    final statisticsProvider = context.read<StoreStatisticsProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final requests = <Future<void>>[];
    if (profileProvider.profileInfo == null && !profileProvider.isLoading) {
      requests.add(profileProvider.fetchClientProfile());
    }
    if (statisticsProvider.statistics == null &&
        !statisticsProvider.isLoading) {
      requests.add(statisticsProvider.fetchStoreStatistics());
    }
    if (notificationProvider.notificationData == null &&
        !notificationProvider.isLoading) {
      requests.add(
        notificationProvider.fetchClientNotifications(limit: 3),
      );
    }

    if (requests.isNotEmpty) {
      await Future.wait(requests);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProfileProvider>().fetchClientProfile(silent: true),
      context
          .read<StoreStatisticsProvider>()
          .fetchStoreStatistics(forceRefresh: true),
      context.read<NotificationProvider>().fetchClientNotifications(
            force: true,
            refresh: true,
            limit: 3,
          ),
    ]);
  }

  void _openSettings() {
    Nav.to(
      const SettingsPage(),
      withNav: true,
      navIndex: 4,
    );
  }

  Future<void> _openNotification(NotificationItem item) async {
    if (item.recipientRowId > 0) {
      await context.read<NotificationProvider>().readNotification(
            recipientRowId: item.recipientRowId,
          );
    }
    if (!mounted || item.itemId <= 0) return;
    Nav.to(OrderDetailPage(orderId: item.itemId));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        body: SafeArea(
          child: Column(
            children: [
              _StorePageHeader(
                title: _copy('My Store', 'متجري'),
                subtitle: _copy(
                  'Your store profile and operational performance',
                  'ملف متجرك وأداؤه التشغيلي',
                ),
                editLabel: _copy('Edit', 'تعديل'),
                onEdit: _openSettings,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 118),
                        sliver: SliverList.list(
                          children: [
                            Consumer<ProfileProvider>(
                              builder: (context, provider, _) {
                                if (provider.profileInfo == null &&
                                    provider.isLoading) {
                                  return const _StoreHeroSkeleton();
                                }
                                if (provider.profileInfo == null) {
                                  return _InlineErrorState(
                                    title: _copy(
                                      'Store information is unavailable',
                                      'بيانات المتجر غير متوفرة',
                                    ),
                                    message: _copy(
                                      'Pull down or try again to load your store.',
                                      'اسحب للأسفل أو حاول مجدداً لتحميل بيانات متجرك.',
                                    ),
                                    buttonLabel:
                                        _copy('Try again', 'إعادة المحاولة'),
                                    onRetry: () {
                                      unawaited(
                                        provider.fetchClientProfile(),
                                      );
                                    },
                                  );
                                }
                                return _StoreHeroCard(
                                  profile: provider.profileInfo!,
                                  isArabic: _isArabic,
                                  copy: _copy,
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            _SectionHeading(
                              title: _copy(
                                'Store Performance',
                                'أداء المتجر',
                              ),
                              subtitle: _copy(
                                'A concise view of your shipment activity',
                                'ملخص سريع لنشاط الشحنات',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Consumer<StoreStatisticsProvider>(
                              builder: (context, provider, _) {
                                if (provider.statistics == null &&
                                    provider.isLoading) {
                                  return const _StatisticsSkeleton();
                                }
                                return _StatisticsGrid(
                                  statistics: provider.statistics,
                                  isArabic: _isArabic,
                                  copy: _copy,
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            Consumer<NotificationProvider>(
                              builder: (context, provider, _) {
                                return _ActivitySection(
                                  notifications: provider.notifications
                                      .take(3)
                                      .toList(growable: false),
                                  isLoading: provider.isLoading &&
                                      provider.notifications.isEmpty,
                                  isArabic: _isArabic,
                                  copy: _copy,
                                  formatTime: _formatTimeAgo,
                                  onTap: (item) {
                                    unawaited(_openNotification(item));
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(NotificationItem item) {
    final rawTime = item.createdAtJordan.trim().isNotEmpty
        ? item.createdAtJordan
        : item.createdAt;
    final createdAt = DateTime.tryParse(rawTime);
    if (createdAt == null) {
      return _copy('Recently', 'مؤخراً');
    }

    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inSeconds < 60) {
      return _copy('Just now', 'الآن');
    }
    if (difference.inMinutes < 60) {
      return _isArabic
          ? 'قبل ${difference.inMinutes} د'
          : '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return _isArabic
          ? 'قبل ${difference.inHours} س'
          : '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return _copy('Yesterday', 'أمس');
    }
    return _isArabic
        ? 'قبل ${difference.inDays} يوم'
        : '${difference.inDays}d ago';
  }
}

class _StorePageHeader extends StatelessWidget {
  const _StorePageHeader({
    required this.title,
    required this.subtitle,
    required this.editLabel,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xff10213D),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xff718096),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: editLabel,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onEdit,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
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

class _StoreHeroCard extends StatelessWidget {
  const _StoreHeroCard({
    required this.profile,
    required this.isArabic,
    required this.copy,
  });

  final ClientInfo profile;
  final bool isArabic;
  final String Function(String english, String arabic) copy;

  bool get _isActive => profile.status == 0;

  String get _storeName {
    final name = profile.nstore.trim();
    return name.isEmpty ? copy('Not available', 'غير متوفر') : name;
  }

  String get _ownerName {
    final name = profile.nclient.trim();
    return name.isEmpty ? copy('Not available', 'غير متوفر') : name;
  }

  String get _phone {
    final phone = profile.phclient.trim();
    return phone.isEmpty ? copy('Not available', 'غير متوفر') : phone;
  }

  String get _address {
    final address = profile.lclient.trim();
    return address.isEmpty
        ? copy('Location not available', 'الموقع غير متوفر')
        : address;
  }

  String? get _logoUrl {
    final path = profile.loshop.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return 'https://dashboard.blockatie.com$normalized';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradient1, AppColors.gradient2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -45,
            end: -38,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StoreLogo(
                      name: _storeName,
                      imageUrl: _logoUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy('Store Account', 'حساب المتجر'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _storeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _HeroPill(
                                icon: _isActive
                                    ? Icons.verified_rounded
                                    : Icons.pause_circle_outline_rounded,
                                label: _isActive
                                    ? copy('Active', 'نشط')
                                    : copy('Inactive', 'غير نشط'),
                              ),
                              _HeroPill(
                                icon: Icons.workspace_premium_outlined,
                                label: profile.subscription == 1
                                    ? copy('Subscribed', 'مشترك')
                                    : copy('Standard', 'عادي'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    children: [
                      _HeroInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: copy('Owner', 'المالك'),
                        value: _ownerName,
                      ),
                      const SizedBox(height: 11),
                      _HeroInfoRow(
                        icon: Icons.phone_outlined,
                        label: copy('Phone', 'الهاتف'),
                        value: _phone,
                        forceLtrValue: true,
                      ),
                      const SizedBox(height: 11),
                      _HeroInfoRow(
                        icon: Icons.location_on_outlined,
                        label: copy('Address', 'العنوان'),
                        value: _address,
                      ),
                    ],
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

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String? imageUrl;

  String get _initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2);
    final value = parts.map((part) => part.characters.first).join();
    return value.isEmpty ? 'B' : value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? _InitialsLogo(initials: _initials)
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _InitialsLogo(initials: _initials);
              },
            ),
    );
  }
}

class _InitialsLogo extends StatelessWidget {
  const _InitialsLogo({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoRow extends StatelessWidget {
  const _HeroInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.forceLtrValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool forceLtrValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: forceLtrValue
                    ? TextDirection.ltr
                    : Directionality.of(context),
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
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
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: Color(0xff10213D),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: Color(0xff718096),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({
    required this.statistics,
    required this.isArabic,
    required this.copy,
  });

  final StoreStatistics? statistics;
  final bool isArabic;
  final String Function(String english, String arabic) copy;

  @override
  Widget build(BuildContext context) {
    final data = statistics;
    final metrics = [
      _MetricData(
        label: copy('Total Shipments', 'إجمالي الشحنات'),
        value: '${data?.totalShipments ?? 0}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _MetricData(
        label: copy('In Progress', 'قيد التنفيذ'),
        value: '${data?.shipmentsInProgress ?? 0}',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xff6956D8),
      ),
      _MetricData(
        label: copy('Delivered', 'تم التسليم'),
        value: '${data?.shipmentsDelivered ?? 0}',
        icon: Icons.verified_outlined,
        color: const Color(0xff16A06D),
      ),
      _MetricData(
        label: copy(
          'Due Balance',
          '\u0627\u0644\u0631\u0635\u064a\u062f \u0627\u0644\u0645\u0633\u062a\u062d\u0642',
        ),
        value: _balanceValue(data?.dueBalance),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xffE58A17),
        forceLtr: true,
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.42,
          ),
          itemBuilder: (_, index) => _MetricCard(data: metrics[index]),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xffE4EAF2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _CompactMetric(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xffE9A11A),
                    label: copy('Rating', 'التقييم'),
                    value: (data?.rating ?? 0).toStringAsFixed(1),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xffE4EAF2),
                ),
                Expanded(
                  child: _CompactMetric(
                    icon: Icons.cancel_outlined,
                    iconColor: const Color(0xffE85D68),
                    label: copy('Cancelled', 'الملغاة'),
                    value: '${data?.cancelledShipments ?? 0}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _balanceValue(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'JOD 0.00';
    if (value.toUpperCase().contains('JOD')) return value;
    return isArabic ? '$value JOD' : 'JOD $value';
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.forceLtr = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool forceLtr;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffE4EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(data.icon, color: data.color, size: 19),
            ),
            Directionality(
              textDirection: data.forceLtr
                  ? TextDirection.ltr
                  : Directionality.of(context),
              child: Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Color(0xff10213D),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Color(0xff718096),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 19),
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
                  color: Color(0xff718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff10213D),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.notifications,
    required this.isLoading,
    required this.isArabic,
    required this.copy,
    required this.formatTime,
    required this.onTap,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool isArabic;
  final String Function(String english, String arabic) copy;
  final String Function(NotificationItem item) formatTime;
  final ValueChanged<NotificationItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: copy('Recent Activity', 'آخر النشاطات'),
          subtitle: copy(
            'The latest updates related to your store',
            'أحدث التحديثات المرتبطة بمتجرك',
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const _ActivitySkeleton()
        else if (notifications.isEmpty)
          _EmptyActivityState(
            title: copy('No recent activity', 'لا توجد نشاطات حديثة'),
            message: copy(
              'New shipment updates will appear here.',
              'ستظهر تحديثات الشحنات الجديدة هنا.',
            ),
          )
        else
          ...notifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(
                item: item,
                title: _titleFor(item),
                message: _messageFor(item),
                time: formatTime(item),
                onTap: () => onTap(item),
              ),
            ),
          ),
      ],
    );
  }

  String _titleFor(NotificationItem item) {
    final localized = isArabic ? item.titleAr.trim() : item.titleEn.trim();
    if (localized.isNotEmpty) return localized;
    final fallback = item.type.replaceAll('_', ' ').trim();
    if (fallback.isNotEmpty) return fallback;
    return copy('Store update', 'تحديث المتجر');
  }

  String _messageFor(NotificationItem item) {
    final localized = isArabic ? item.messageAr.trim() : item.messageEn.trim();
    if (localized.isNotEmpty) return localized;
    if (item.message.trim().isNotEmpty) return item.message.trim();
    return copy(
      'A new update is available.',
      'يتوفر تحديث جديد.',
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.title,
    required this.message,
    required this.time,
    required this.onTap,
  });

  final NotificationItem item;
  final String title;
  final String message;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isUnread
          ? AppColors.primary.withValues(alpha: 0.045)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isUnread
              ? AppColors.primary.withValues(alpha: 0.17)
              : const Color(0xffE4EAF2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.itemId > 0 ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Color(0xff10213D),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Color(0xff8A96A8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xff66758B),
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.itemId > 0) ...[
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xff9AA7B8),
                    size: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineErrorState extends StatelessWidget {
  const _InlineErrorState({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffE4EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xffE85D68).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Color(0xffD94C5A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff10213D),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff718096),
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffE4EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff10213D),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xff718096),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeroSkeleton extends StatelessWidget {
  const _StoreHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffE8EEF7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 72, height: 72, radius: 20),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 78, height: 11),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 160, height: 22),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 110, height: 24, radius: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child:
                _SkeletonBox(width: double.infinity, height: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSkeleton extends StatelessWidget {
  const _StatisticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SkeletonBox(width: double.infinity, height: 120)),
        SizedBox(width: 10),
        Expanded(child: _SkeletonBox(width: double.infinity, height: 120)),
      ],
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonBox(width: double.infinity, height: 76),
        SizedBox(height: 10),
        _SkeletonBox(width: double.infinity, height: 76),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 14,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
