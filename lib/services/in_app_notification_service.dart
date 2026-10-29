import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'user_session_state.dart';
import 'session_dio.dart';
import 'package:flutter/material.dart';

class InAppNotificationMessage {
  const InAppNotificationMessage({
    required this.notificationId,
    required this.displayMode,
    required this.priority,
    required this.requiresAck,
    required this.titleAr,
    required this.titleEn,
    required this.messageAr,
    required this.messageEn,
  });

  final int notificationId;
  final String displayMode;
  final String priority;
  final bool requiresAck;
  final String titleAr;
  final String titleEn;
  final String messageAr;
  final String messageEn;

  factory InAppNotificationMessage.fromJson(Map<String, dynamic> json) {
    return InAppNotificationMessage(
      notificationId: _asInt(json['notification_id']),
      displayMode: json['display_mode']?.toString() ?? 'notification_only',
      priority: json['priority']?.toString() ?? 'normal',
      requiresAck: _asBool(json['requires_ack']),
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      messageAr: json['message_ar']?.toString() ?? '',
      messageEn: json['message_en']?.toString() ?? '',
    );
  }

  String titleFor(String languageCode) {
    final preferred = languageCode == 'ar' ? titleAr : titleEn;
    final fallback = languageCode == 'ar' ? titleEn : titleAr;
    if (preferred.trim().isNotEmpty) return preferred.trim();
    if (fallback.trim().isNotEmpty) return fallback.trim();
    return languageCode == 'ar' ? 'إشعار مهم' : 'Important notification';
  }

  String messageFor(String languageCode) {
    final preferred = languageCode == 'ar' ? messageAr : messageEn;
    final fallback = languageCode == 'ar' ? messageEn : messageAr;
    if (preferred.trim().isNotEmpty) return preferred.trim();
    if (fallback.trim().isNotEmpty) return fallback.trim();
    return languageCode == 'ar'
        ? 'يرجى مراجعة هذا التحديث.'
        : 'Please review this update.';
  }
}

class InAppNotificationService extends UserScopedNotifier {
  @override
  void clearUserState() {
    _handledNotificationIds.clear();
    _isChecking = false;
  }

  final Dio _dio = sessionDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final Set<int> _handledNotificationIds = {};
  bool _isChecking = false;

  void _logDioFailure(String endpoint, DioException error) {
    if (!kDebugMode) return;
    debugPrint(
      '$endpoint failed: type=${error.type.name} '
      'status=${error.response?.statusCode}',
    );
  }

  Future<void> checkAndDisplay(BuildContext context) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isChecking) return;
      _isChecking = true;

      try {
        final session =
            await guardSession(AuthService.getSession(), sessionGeneration);
        if (!context.mounted || !session.isValid) {
          return;
        }

        final response = await guardSession(
            _dio.post(
              AppUrls.getInAppNotifications,
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': session.apiKey,
                },
              ),
              data: {
                'user_role': 'client',
                'user_id': session.clientId,
              },
            ),
            sessionGeneration);

        final data = response.data;
        if (response.statusCode != 200 ||
            data is! Map ||
            (data['success'] != true && data['status'] != 'success')) {
          if (kDebugMode) {
            debugPrint(
              'In-app notification fetch failed: type=badResponse '
              'status=${response.statusCode}',
            );
          }
          return;
        }

        final rawNotifications = data['notifications'];
        if (rawNotifications is! List) return;

        for (final raw in rawNotifications) {
          if (!context.mounted) return;
          if (raw is! Map) continue;

          final message = InAppNotificationMessage.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (message.notificationId <= 0 ||
              _handledNotificationIds.contains(message.notificationId)) {
            continue;
          }

          _handledNotificationIds.add(message.notificationId);
          await guardSession(_display(context, message), sessionGeneration);
        }
      } on DioException catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _logDioFailure('In-app notification fetch', e);
      } catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (kDebugMode) {
          debugPrint('In-app notification fetch failed: ${e.runtimeType}');
        }
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isChecking = false;
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> _display(
    BuildContext context,
    InAppNotificationMessage message,
  ) async {
    final sessionGeneration = stateGeneration;
    try {
      if (message.displayMode == 'in_app_banner') {
        _showBanner(context, message);
        return;
      }

      if (message.displayMode == 'in_app_modal' ||
          message.displayMode == 'force_modal') {
        await guardSession(_showModal(context, message), sessionGeneration);
      }
    } on SessionChanged {
      return;
    }
  }

  void _showBanner(BuildContext context, InAppNotificationMessage message) {
    final languageCode = Localizations.localeOf(context).languageCode;
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: _MessageIcon(priority: message.priority),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.titleFor(languageCode),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(message.messageFor(languageCode)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              await _acknowledge(message.notificationId);
            },
            child: Text(languageCode == 'ar' ? 'فهمت' : 'Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showModal(
    BuildContext context,
    InAppNotificationMessage message,
  ) async {
    final sessionGeneration = stateGeneration;
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final isForce = message.displayMode == 'force_modal';

      final acknowledged = await guardSession(
          showDialog<bool>(
            context: context,
            barrierDismissible: !isForce,
            builder: (dialogContext) {
              return PopScope(
                canPop: !isForce,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Row(
                    children: [
                      _MessageIcon(priority: message.priority),
                      const SizedBox(width: 10),
                      Expanded(child: Text(message.titleFor(languageCode))),
                    ],
                  ),
                  content: Text(message.messageFor(languageCode)),
                  actions: [
                    if (!isForce)
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(languageCode == 'ar' ? 'لاحقاً' : 'Later'),
                      ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(languageCode == 'ar' ? 'فهمت' : 'Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          sessionGeneration);

      if (acknowledged == true) {
        await guardSession(
            _acknowledge(message.notificationId), sessionGeneration);
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> _acknowledge(int notificationId) async {
    final sessionGeneration = stateGeneration;
    try {
      try {
        final session =
            await guardSession(AuthService.getSession(), sessionGeneration);
        if (!session.isValid) {
          return;
        }

        await guardSession(
            _dio.post(
              AppUrls.acknowledgeNotification,
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': session.apiKey,
                },
              ),
              data: {
                'user_role': 'client',
                'user_id': session.clientId,
                'notification_id': notificationId,
              },
            ),
            sessionGeneration);
      } on DioException catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _logDioFailure('In-app notification acknowledge', e);
      } catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (kDebugMode) {
          debugPrint(
              'In-app notification acknowledge failed: ${e.runtimeType}');
        }
      }
    } on SessionChanged {
      return;
    }
  }
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final isCritical = priority == 'critical';
    final isImportant = priority == 'important';
    final color = isCritical
        ? Colors.red
        : isImportant
            ? Colors.orange
            : AppColors.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isCritical ? Icons.priority_high_rounded : Icons.notifications_rounded,
        color: color,
      ),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
