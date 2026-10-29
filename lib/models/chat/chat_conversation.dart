import 'chat_parsing.dart';

class ChatConversation {
  const ChatConversation({
    required this.conversationId,
    required this.conversationType,
    required this.title,
    required this.lastMessage,
    required this.lastMessageType,
    required this.unreadCount,
    this.shipmentId,
    this.policyNum,
    this.lastMessageAt,
    this.createdAt,
  });

  final int conversationId;
  final String conversationType;
  final int? shipmentId;
  final String title;
  final String? policyNum;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final int unreadCount;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final unreadCount = chatInt(json['unread_count']) ?? 0;
    return ChatConversation(
      conversationId: chatRequiredPositiveInt(
        json['conversation_id'],
        fieldName: 'conversation_id',
      ),
      conversationType: chatString(json['conversation_type']),
      shipmentId: chatInt(json['shipment_id']),
      title: chatString(json['title']),
      policyNum: _nullableString(json['policy_num']),
      lastMessage: chatString(json['last_message']),
      lastMessageType: chatString(
        json['last_message_type'],
        fallback: 'text',
      ),
      lastMessageAt:
          chatDateTime(json['last_message_at_utc'] ?? json['last_message_at']),
      createdAt: chatDateTime(json['created_at_utc'] ?? json['created_at']),
      unreadCount: unreadCount < 0 ? 0 : unreadCount,
    );
  }

  ChatConversation copyWith({
    int? conversationId,
    String? conversationType,
    int? shipmentId,
    bool clearShipmentId = false,
    String? title,
    String? policyNum,
    bool clearPolicyNum = false,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    bool clearLastMessageAt = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    int? unreadCount,
  }) {
    return ChatConversation(
      conversationId: conversationId ?? this.conversationId,
      conversationType: conversationType ?? this.conversationType,
      shipmentId: clearShipmentId ? null : (shipmentId ?? this.shipmentId),
      title: title ?? this.title,
      policyNum: clearPolicyNum ? null : (policyNum ?? this.policyNum),
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt:
          clearLastMessageAt ? null : (lastMessageAt ?? this.lastMessageAt),
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static String? _nullableString(dynamic value) {
    final normalized = chatString(value);
    return normalized.isEmpty ? null : normalized;
  }
}
