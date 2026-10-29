class NotificationResponse {
  const NotificationResponse({
    required this.status,
    required this.message,
    required this.unreadCount,
    required this.notifications,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final String status;
  final String message;
  final int unreadCount;
  final List<NotificationItem> notifications;
  final int page;
  final int limit;
  final bool hasMore;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final rawNotifications =
        json['notifications'] ?? dataMap['notifications'] ?? const <dynamic>[];
    final resolvedNotifications = rawNotifications is List
        ? rawNotifications
            .whereType<Map>()
            .map(
              (item) => NotificationItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <NotificationItem>[];

    final page = _asInt(json['page'] ?? dataMap['page']);
    final limit = _asInt(json['limit'] ?? dataMap['limit']);

    return NotificationResponse(
      status: (json['status'] ?? json['success'] ?? dataMap['status'])
              ?.toString() ??
          '',
      message: (json['message'] ??
                  json['message_en'] ??
                  json['message_ar'] ??
                  dataMap['message'])
              ?.toString() ??
          '',
      unreadCount: _asInt(json['unread_count'] ?? dataMap['unread_count']),
      notifications: resolvedNotifications,
      page: page <= 0 ? 1 : page,
      limit: limit <= 0 ? resolvedNotifications.length : limit,
      hasMore: _asBool(json['has_more'] ?? dataMap['has_more']),
    );
  }

  NotificationResponse copyWith({
    String? status,
    String? message,
    int? unreadCount,
    List<NotificationItem>? notifications,
    int? page,
    int? limit,
    bool? hasMore,
  }) {
    return NotificationResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      unreadCount: unreadCount ?? this.unreadCount,
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.recipientRowId,
    required this.senderRole,
    required this.senderId,
    required this.type,
    required this.priority,
    required this.displayMode,
    required this.itemId,
    required this.titleEn,
    required this.titleAr,
    required this.messageEn,
    required this.messageAr,
    required this.message,
    required this.url,
    required this.isRead,
    required this.requiresAck,
    required this.readAt,
    required this.acknowledgedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.createdAtJordan,
    required this.createdAtUtc,
  });

  final int id;
  final int recipientRowId;
  final String senderRole;
  final int senderId;
  final String type;
  final String priority;
  final String displayMode;
  final int itemId;
  final String titleEn;
  final String titleAr;
  final String messageEn;
  final String messageAr;
  final String message;
  final String url;
  final int isRead;
  final bool requiresAck;
  final String? readAt;
  final String? acknowledgedAt;
  final String? expiresAt;
  final String createdAt;
  final String createdAtJordan;
  final String createdAtUtc;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _asInt(
        json['notification_id'] ??
            json['notification_recipient_id'] ??
            json['id'],
      ),
      recipientRowId: _asInt(
        json['recipient_row_id'] ?? json['notification_recipient_id'],
      ),
      senderRole: json['sender_role']?.toString() ?? '',
      senderId: _asInt(json['sender_id']),
      type: json['type']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      displayMode: json['display_mode']?.toString() ?? 'list',
      itemId: _asInt(json['item_id'] ?? json['shipment_id']),
      titleEn: (json['title_en'] ?? json['title'])?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      messageEn: json['message_en']?.toString() ?? '',
      messageAr: json['message_ar']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      isRead: _asBoolInt(json['is_read']),
      requiresAck: _asBool(json['requires_ack']),
      readAt: json['read_at']?.toString(),
      acknowledgedAt: json['acknowledged_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      createdAt: (json['created_at'] ?? json['date'] ?? json['createdAt'])
              ?.toString() ??
          '',
      createdAtJordan:
          (json['created_at_jordan'] ?? json['created_at_local'])?.toString() ??
              '',
      createdAtUtc: (json['created_at_utc'])?.toString() ?? '',
    );
  }

  bool get isUnread => isRead == 0;

  NotificationItem copyWith({
    int? isRead,
    String? readAt,
    String? acknowledgedAt,
  }) {
    return NotificationItem(
      id: id,
      recipientRowId: recipientRowId,
      senderRole: senderRole,
      senderId: senderId,
      type: type,
      priority: priority,
      displayMode: displayMode,
      itemId: itemId,
      titleEn: titleEn,
      titleAr: titleAr,
      messageEn: messageEn,
      messageAr: messageAr,
      message: message,
      url: url,
      isRead: isRead ?? this.isRead,
      requiresAck: requiresAck,
      readAt: readAt ?? this.readAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      expiresAt: expiresAt,
      createdAt: createdAt,
      createdAtJordan: createdAtJordan,
      createdAtUtc: createdAtUtc,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is bool) {
    return value ? 1 : 0;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'y';
}

int _asBoolInt(dynamic value) {
  return _asBool(value) ? 1 : _asInt(value);
}
