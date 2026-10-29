import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/models/notifications.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/notification.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:blockatie/views/pages/home/components/header.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:blockatie/views/pages/orders/order_details.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.showBackButton = false,
  });

  final bool showBackButton;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    JordanTime.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<NotificationProvider>().fetchClientNotifications();
    });
  }

  void _openSupport() {
    Nav.to(
      const SupportAssistancePage(),
      withNav: true,
      navIndex: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),
      appBar: widget.showBackButton
          ? CustomAppBar(
              title: _text('notifications_title'),
              subtitle: _text('notifications_subtitle'),
              showBtn: true,
              onHelp: _openSupport,
              onBack: Nav.back,
            )
          : null,
      body: SafeArea(
        top: !widget.showBackButton,
        child: Column(
          children: [
            if (!widget.showBackButton)
              HomeHeader(
                title: _text('notifications_title'),
                subtitle: _text('notifications_subtitle'),
                showNotificationShortcut: false,
                showProfileShortcut: false,
                showHelpButton: true,
                onHelpTap: _openSupport,
              ),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => provider.fetchClientNotifications(
                      force: true,
                      refresh: true,
                    ),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 220) {
                          provider.loadMoreNotifications();
                        }
                        return false;
                      },
                      child: _buildBody(provider),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          _StateCard(
            icon: Icons.notifications_active_outlined,
            title: _text('notifications_loading_title'),
            message: _text('notifications_loading_message'),
            isLoading: true,
          ),
        ],
      );
    }

    if (provider.errorKey != null && provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          _StateCard(
            icon: Icons.error_outline_rounded,
            title: _text('notifications_generic_error'),
            message: _text(provider.errorKey!),
            actionLabel: _text('notifications_retry'),
            onAction: () => provider.fetchClientNotifications(
              force: true,
              refresh: true,
            ),
          ),
        ],
      );
    }

    if (provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          _StateCard(
            icon: Icons.notifications_none_rounded,
            title: _text('notifications_empty_title'),
            message: _text('notifications_empty_message'),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount:
          provider.notifications.length + 1 + (provider.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _NotificationSummary(
            unreadCount: provider.unreadCount,
            totalCount: provider.notifications.length,
            title: _text('notifications_title'),
            unreadLabel: _text('notifications_unread'),
            totalLabel: _text('notifications_total'),
            latestLabel: _text('notifications_latest'),
          );
        }

        final listIndex = index - 1;
        if (listIndex >= provider.notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          );
        }

        final notification = provider.notifications[listIndex];
        return _NotificationCard(
          notification: notification,
          title: _titleFor(notification),
          message: _messageFor(notification),
          timeLabel: _formattedTime(notification),
          unreadLabel: _text('notifications_new'),
          openOrderLabel: _text('notifications_open_order'),
          isReading: provider.isReading(notification.recipientRowId),
          onTap: () => _handleNotificationTap(notification),
        );
      },
    );
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    final epoch = UserSessionState.generation;
    if (AuthService.currentSession?.isValid != true) return;
    final navProvider = context.read<BottomNavProvider>();
    final provider = context.read<NotificationProvider>();
    var resolvedNotification = notification;
    if (notification.isUnread) {
      final didRead = await provider.readNotification(
        recipientRowId: notification.recipientRowId,
      );
      if (!mounted ||
          epoch != UserSessionState.generation ||
          AuthService.currentSession?.isValid != true) {
        return;
      }
      if (!didRead) {
        _showSnack(
          _text('notifications_mark_read_failed'),
          isError: true,
        );
      } else {
        resolvedNotification = notification.copyWith(
          isRead: 1,
          readAt: DateTime.now().toIso8601String(),
        );
      }
    }

    if (_hasShipmentTarget(resolvedNotification)) {
      navProvider.clearOverlay();
      Nav.to(OrderDetailPage(orderId: resolvedNotification.itemId));
      return;
    }

    _showNotificationSheet(resolvedNotification);
  }

  void _showNotificationSheet(NotificationItem notification) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _NotificationDetailsSheet(
          title: _titleFor(notification),
          message: _messageFor(notification),
          timeLabel: _formattedTime(notification),
          isUnread: notification.isUnread,
          unreadLabel: _text('notifications_unread'),
          readLabel: _text('notifications_read'),
        );
      },
    );
  }

  bool _hasShipmentTarget(NotificationItem notification) {
    if (notification.itemId <= 0) {
      return false;
    }

    final type = notification.type.toLowerCase();
    return type.contains('shipment') ||
        type.contains('order') ||
        notification.url.contains('shipment') ||
        notification.url.contains('order');
  }

  String _titleFor(NotificationItem notification) {
    final locale = Localizations.localeOf(context).languageCode;
    final localized =
        locale == 'ar' ? notification.titleAr : notification.titleEn;
    if (localized.trim().isNotEmpty) {
      return localized.trim();
    }

    if (notification.type.trim().isEmpty) {
      return locale == 'ar' ? 'إشعار' : 'Notification';
    }

    final normalized = notification.type.replaceAll('_', ' ').trim();
    if (locale == 'ar') {
      if (normalized.toLowerCase().contains('shipment')) {
        return 'تحديث شحنة';
      }
      if (normalized.toLowerCase().contains('payment')) {
        return 'تنبيه مالي';
      }
      return 'إشعار المتجر';
    }

    return normalized
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _messageFor(NotificationItem notification) {
    final locale = Localizations.localeOf(context).languageCode;
    final localized =
        locale == 'ar' ? notification.messageAr : notification.messageEn;
    if (localized.trim().isNotEmpty) {
      return localized.trim();
    }
    if (notification.message.trim().isNotEmpty) {
      return notification.message.trim();
    }
    return _text('notifications_no_message');
  }

  String _formattedTime(NotificationItem notification) {
    final locale = Localizations.localeOf(context).languageCode;
    return JordanTime.formatForNotifications(
      locale: locale,
      value: notification.createdAt,
      jordanValue: notification.createdAtJordan,
      utcValue: notification.createdAtUtc,
      justNowLabel: _text('just_now'),
      todayLabel: _text('notifications_today'),
      yesterdayLabel: _text('notifications_yesterday'),
      minuteAgoLabel: _text('notifications_minute_ago'),
      minutesAgoLabel: _text('notifications_minutes_ago'),
      hourAgoLabel: _text('notifications_hour_ago'),
      hoursAgoLabel: _text('notifications_hours_ago'),
      unavailableLabel: _text('not_available'),
    );
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

  String _text(String key) => AppTranslations.getText(key);
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.unreadCount,
    required this.totalCount,
    required this.title,
    required this.unreadLabel,
    required this.totalLabel,
    required this.latestLabel,
  });

  final int unreadCount;
  final int totalCount;
  final String title;
  final String unreadLabel;
  final String totalLabel;
  final String latestLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 28,
            ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latestLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      label: unreadLabel,
                      value: unreadCount.toString(),
                    ),
                    _SummaryChip(
                      label: totalLabel,
                      value: totalCount.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.unreadLabel,
    required this.openOrderLabel,
    required this.isReading,
    required this.onTap,
  });

  final NotificationItem notification;
  final String title;
  final String message;
  final String timeLabel;
  final String unreadLabel;
  final String openOrderLabel;
  final bool isReading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isReading ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unread ? const Color(0xffF8FBFF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unread ? const Color(0xffCFE3FF) : const Color(0xffE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(notification: notification),
              const SizedBox(width: 14),
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
                            style: const TextStyle(
                              color: Color(0xff0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ReadStatePill(
                          unread: unread,
                          unreadLabel: unreadLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: timeLabel,
                        ),
                        if (notification.itemId > 0)
                          _MetaPill(
                            icon: Icons.open_in_new_rounded,
                            label: openOrderLabel,
                            highlighted: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isReading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final icon = _resolveIcon(notification.type, notification.priority);
    final background = notification.isUnread
        ? const Color(0xffE8F1FF)
        : const Color(0xffF1F5F9);
    final foreground =
        notification.isUnread ? AppColors.primary : const Color(0xff64748B);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: foreground, size: 24),
    );
  }

  static IconData _resolveIcon(String type, String priority) {
    final normalizedType = type.toLowerCase();
    final normalizedPriority = priority.toLowerCase();

    if (normalizedPriority == 'critical' || normalizedPriority == 'high') {
      return Icons.priority_high_rounded;
    }
    if (normalizedType.contains('shipment') ||
        normalizedType.contains('order')) {
      return Icons.local_shipping_outlined;
    }
    if (normalizedType.contains('payment') ||
        normalizedType.contains('wallet')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (normalizedType.contains('support') ||
        normalizedType.contains('message')) {
      return Icons.support_agent_rounded;
    }
    return Icons.notifications_none_rounded;
  }
}

class _ReadStatePill extends StatelessWidget {
  const _ReadStatePill({
    required this.unread,
    required this.unreadLabel,
  });

  final bool unread;
  final String unreadLabel;

  @override
  Widget build(BuildContext context) {
    if (!unread) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffE9F7EF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        unreadLabel,
        style: const TextStyle(
          color: Color(0xff11875D),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xffEEF5FF) : const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              highlighted ? const Color(0xffD8E8FF) : const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? AppColors.primary : const Color(0xff64748B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? AppColors.primary : const Color(0xff475569),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xffEEF5FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  )
                : Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.isUnread,
    required this.unreadLabel,
    required this.readLabel,
  });

  final String title;
  final String message;
  final String timeLabel;
  final bool isUnread;
  final String unreadLabel;
  final String readLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xffCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? const Color(0xffE9F7EF)
                        : const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isUnread ? unreadLabel : readLabel,
                    style: TextStyle(
                      color: isUnread
                          ? const Color(0xff11875D)
                          : const Color(0xff475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetaPill(
              icon: Icons.schedule_rounded,
              label: timeLabel,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xff334155),
                fontSize: 14,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
