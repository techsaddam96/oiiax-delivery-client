import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/home.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/firebase_service.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/welcome/client_welcome_page.dart';
import 'package:blockatie/views/pages/hub/setting/settings.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  late final int _accountGeneration;

  bool get _isCurrentAccount =>
      mounted && _accountGeneration == UserSessionState.generation;

  @override
  void initState() {
    super.initState();
    _accountGeneration = UserSessionState.generation;
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final provider = context.read<ProfileProvider>();
    await Future.wait([
      provider.fetchClientProfile(silent: true),
      provider.fetchClientStatistics(),
    ]);

    if (!_isCurrentAccount) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshProfile() async {
    final provider = context.read<ProfileProvider>();
    await Future.wait([
      provider.fetchClientProfile(silent: true),
      provider.fetchClientStatistics(),
    ]);
  }

  Future<void> _openWalletTab() async {
    final navProvider = context.read<BottomNavProvider>();
    navProvider.clearOverlay();
    context.read<HomeProvider>().resetToHome();
    navProvider.setIndex(2);
  }

  void _handleBack() {
    final navProvider = context.read<BottomNavProvider>();
    if (navProvider.overlayPage != null || Navigator.canPop(context)) {
      Nav.back();
      return;
    }

    context.read<HomeProvider>().resetToHome();
    navProvider.setIndex(0);
  }

  void _openSupport() {
    Nav.to(
      const SupportAssistancePage(),
      withNav: true,
      navIndex: 4,
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut || !_isCurrentAccount) return;
    _isLoggingOut = true;
    try {
      // Firebase cleanup must never delay local credential and state removal.
      await AuthService.logout();
    } catch (_) {
      // The synchronous session boundary has already cleared private state.
    } finally {
      // Reset can dispose this overlay; navigation must still finish.
      // A delayed logout must not navigate away from a newer valid account.
      if (AuthService.currentSession?.isValid != true) {
        Nav.offAll(const ClientWelcomePage());
      }
    }
  }

  Future<void> _deleteAccount() async {
    final clientId = await AuthService.getUserId();
    if (!mounted) {
      return;
    }

    if (clientId == null || clientId.trim().isEmpty) {
      _showSnack(
        _copy(
          'Your session is no longer valid. Please login again.',
          'انتهت الجلسة الحالية. يرجى تسجيل الدخول مرة أخرى.',
        ),
        isError: true,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await AuthService.deleteAccount(clientId);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();

      if (result['success'] == true) {
        await FirebaseService.unsubscribeFromClientTopics();
        await AuthService.clearSession();
        if (!mounted) {
          return;
        }
        Nav.offAll(const ClientWelcomePage());
        return;
      }

      _showSnack(
        result['message']?.toString().trim().isNotEmpty == true
            ? result['message'].toString()
            : _copy(
                'Failed to delete account. Please try again.',
                'فشل حذف الحساب. حاول مرة أخرى.',
              ),
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack(
        _copy(
          'Failed to delete account. Please try again.',
          'فشل حذف الحساب. حاول مرة أخرى.',
        ),
        isError: true,
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(_copy('Logout', 'تسجيل الخروج')),
          content: Text(
            _copy(
              'Do you want to log out from this device?',
              'هل تريد تسجيل الخروج من هذا الجهاز؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_copy('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(_copy('Logout', 'تسجيل الخروج')),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _isCurrentAccount) {
      await _logout();
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(_copy('Delete Account', 'حذف الحساب')),
          content: Text(
            _copy(
              'This action cannot be undone. Do you want to continue?',
              'لا يمكن التراجع عن هذا الإجراء. هل تريد المتابعة؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_copy('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffDC2626),
              ),
              child: Text(_copy('Delete', 'حذف')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? const Color(0xffDC2626) : const Color(0xff16A06D),
        ),
      );
  }

  String _copy(String en, String ar) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0:
        return _copy('Active', 'نشط');
      case 1:
        return _copy('Inactive', 'غير نشط');
      case 2:
        return _copy('Suspended', 'موقوف');
      default:
        return _copy('Unknown', 'غير معروف');
    }
  }

  String _subscriptionLabel(int subscription) {
    return subscription == 1
        ? _copy('Subscribed', 'مشترك')
        : _copy('Standard', 'عادي');
  }

  String _value(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _copy('Not available', 'غير متوفر');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profileInfo;
    final statistics = provider.statistics;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _ProfileTopBanner(
              title: _copy('My Account', 'حسابي'),
              subtitle: _copy(
                'Your store profile and account details',
                'ملف المتجر وبيانات الحساب',
              ),
              onBackTap: _handleBack,
              onSupportTap: _openSupport,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refreshProfile,
                child: _isLoading
                    ? const _LoadingState()
                    : profile == null
                        ? _ErrorState(
                            message: provider.profileError ??
                                _copy(
                                  'Unable to load profile data. Please try again.',
                                  'تعذر تحميل بيانات الحساب. حاول مرة أخرى.',
                                ),
                            buttonLabel: _copy('Try again', 'حاول مرة أخرى'),
                            onRetry: _loadProfile,
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                            child: Column(
                              children: [
                                _ProfileHeroCard(
                                  profile: profile,
                                  copy: _copy,
                                  valueResolver: _value,
                                  statusLabel: _statusLabel(profile.status),
                                  subscriptionLabel:
                                      _subscriptionLabel(profile.subscription),
                                ),
                                const SizedBox(height: 16),
                                _QuickActionsGrid(
                                  title:
                                      _copy('Quick Actions', 'إجراءات سريعة'),
                                  actions: [
                                    _QuickActionData(
                                      icon: Icons.edit_outlined,
                                      title: _copy(
                                        'Edit Information',
                                        'تعديل المعلومات',
                                      ),
                                      subtitle: _copy(
                                        'Update store details',
                                        'تحديث بيانات المتجر',
                                      ),
                                      onTap: () => Nav.to(
                                        const SettingsPage(),
                                        withNav: true,
                                        navIndex: 4,
                                      ),
                                    ),
                                    _QuickActionData(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      title: _copy('Wallet', 'المحفظة'),
                                      subtitle: _copy(
                                        'Balances and requests',
                                        'الأرصدة والطلبات',
                                      ),
                                      onTap: () {
                                        unawaited(_openWalletTab());
                                      },
                                    ),
                                    _QuickActionData(
                                      icon: Icons.support_agent_rounded,
                                      title: _copy('Support', 'الدعم'),
                                      subtitle: _copy(
                                        'Open support center',
                                        'فتح مركز الدعم',
                                      ),
                                      onTap: _openSupport,
                                    ),
                                    _QuickActionData(
                                      icon: Icons.logout_rounded,
                                      title: _copy('Logout', 'تسجيل الخروج'),
                                      subtitle: _copy(
                                        'Sign out safely',
                                        'تسجيل خروج آمن',
                                      ),
                                      color: const Color(0xffDC2626),
                                      onTap: () {
                                        unawaited(_showLogoutDialog());
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _StatisticsOverviewCard(
                                  statistics: statistics,
                                  copy: _copy,
                                ),
                                const SizedBox(height: 16),
                                _ProfileHighlightsCard(
                                  localClientId:
                                      AuthService.currentSession?.clientId,
                                  phone: profile.phclient,
                                  copy: _copy,
                                  statusLabel: _statusLabel(profile.status),
                                  subscriptionLabel:
                                      _subscriptionLabel(profile.subscription),
                                  valueResolver: _value,
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  color: const Color(0xffFFF8F8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(
                                      color: Color(0xffF5C2C2),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          _copy(
                                            'Account management',
                                            '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u062d\u0633\u0627\u0628',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xff7F1D1D),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            unawaited(_showDeleteDialog());
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          label: Text(
                                            _copy(
                                              'Delete Account',
                                              '\u062d\u0630\u0641 \u0627\u0644\u062d\u0633\u0627\u0628',
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xffDC2626),
                                            side: const BorderSide(
                                              color: Color(0xffF5B4B4),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBanner extends StatelessWidget {
  const _ProfileTopBanner({
    required this.title,
    required this.subtitle,
    required this.onBackTap,
    required this.onSupportTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBackTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _BannerTextButton(
            label: isRtl ? '\u0645\u0633\u0627\u0639\u062f\u0629' : 'Help',
            onTap: onSupportTap,
          ),
          const SizedBox(width: 8),
          _BannerIconButton(
            icon: isRtl
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
            onTap: onBackTap,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
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

class _BannerIconButton extends StatelessWidget {
  const _BannerIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF1F5F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }
}

class _BannerTextButton extends StatelessWidget {
  const _BannerTextButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.copy,
    required this.valueResolver,
    required this.statusLabel,
    required this.subscriptionLabel,
  });

  final ClientInfo profile;
  final String Function(String en, String ar) copy;
  final String Function(String? value) valueResolver;
  final String statusLabel;
  final String subscriptionLabel;

  @override
  Widget build(BuildContext context) {
    final logoPath = profile.loshop.trim();
    final hasLogo = logoPath.isNotEmpty;
    final logoUrl = hasLogo
        ? logoPath.startsWith('http')
            ? logoPath
            : 'https://dashboard.blockatie.com$logoPath'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy('Store Profile', 'ملف المتجر'),
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valueResolver(profile.nstore),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${copy('Owner', 'المالك')}: ${valueResolver(profile.nclient)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valueResolver(profile.lclient),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroMetaChip(
                      icon: Icons.workspace_premium_outlined,
                      label: copy('Subscription', 'الاشتراك'),
                      value: subscriptionLabel,
                      color: const Color(0xff4F46E5),
                    ),
                    _HeroMetaChip(
                      icon: Icons.verified_user_outlined,
                      label: copy('Account Status', 'حالة الحساب'),
                      value: statusLabel,
                      color: const Color(0xff16A06D),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xffEEF5FF),
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _InitialsCard(text: _initials(profile.nstore)),
                  )
                : _InitialsCard(text: _initials(profile.nstore)),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InitialsCard extends StatelessWidget {
  const _InitialsCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatisticsOverviewCard extends StatelessWidget {
  const _StatisticsOverviewCard({
    required this.statistics,
    required this.copy,
  });

  final ClientStatisticsData? statistics;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: copy('Store Statistics', 'إحصائيات المتجر'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2_outlined,
                  label: copy('Total Shipments', 'إجمالي الشحنات'),
                  value: '${statistics?.shipments ?? 0}',
                  color: const Color(0xff10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_shipping_outlined,
                  label: copy('In Progress', 'قيد التنفيذ'),
                  value: '${statistics?.shipmentsInProgress ?? 0}',
                  color: const Color(0xff4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.cancel_outlined,
                  label: copy('Cancelled', 'تم الإلغاء'),
                  value: '${statistics?.cancelledShipments ?? 0}',
                  color: const Color(0xffEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: copy('Delivered', 'تم التسليم'),
                  value: '${statistics?.shipmentsDelivered ?? 0}',
                  color: const Color(0xffF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHighlightsCard extends StatelessWidget {
  const _ProfileHighlightsCard({
    required this.localClientId,
    required this.phone,
    required this.copy,
    required this.statusLabel,
    required this.subscriptionLabel,
    required this.valueResolver,
  });

  final String? localClientId;
  final String? phone;
  final String Function(String en, String ar) copy;
  final String statusLabel;
  final String subscriptionLabel;
  final String Function(String? value) valueResolver;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: copy('Client Details', 'تفاصيل العميل'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing) / 2;
          final items = [
            _InfoChip(
              icon: Icons.badge_outlined,
              label: copy('Client ID', 'رقم العميل'),
              value: valueResolver(localClientId),
            ),
            _InfoChip(
              icon: Icons.phone_rounded,
              label: copy('Phone', 'الهاتف'),
              value: valueResolver(phone),
            ),
            _InfoChip(
              icon: Icons.workspace_premium_outlined,
              label: copy('Subscription', 'الاشتراك'),
              value: subscriptionLabel,
            ),
            _InfoChip(
              icon: Icons.verified_user_outlined,
              label: copy('Account Status', 'حالة الحساب'),
              value: statusLabel,
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items) SizedBox(width: itemWidth, child: item),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 13,
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.title,
    required this.actions,
  });

  final String title;
  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: title,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.16,
        ),
        itemBuilder: (context, index) => _QuickActionTile(data: actions[index]),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    final color = data.color ?? AppColors.primary;
    return Material(
      color: const Color(0xffF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: color, size: 22),
              ),
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE1E8F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 180),
      children: [
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.buttonLabel,
    required this.onRetry,
  });

  final String message;
  final String buttonLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 140, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffE1E8F2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  unawaited(onRetry());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

String _initials(String text) {
  final parts = text
      .split(RegExp(r'\s+'))
      .where((item) => item.trim().isNotEmpty)
      .take(2)
      .map((item) => item.characters.first.toUpperCase())
      .join();
  return parts.isEmpty ? 'B' : parts;
}
