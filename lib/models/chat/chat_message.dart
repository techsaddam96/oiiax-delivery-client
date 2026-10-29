import 'chat_parsing.dart';

enum ChatMessageLocalStatus {
  sending,
  sent,
  failed,
}

class ChatMessage {
  const ChatMessage({
    required this.conversationId,
    required this.senderRole,
    required this.senderName,
    required this.messageType,
    required this.message,
    required this.isMine,
    required this.isRead,
    required this.localStatus,
    this.messageId,
    this.clientMessageId,
    this.createdAt,
    this.readAt,
  });

  final int? messageId;
  final int conversationId;
  final String senderRole;
  final String senderName;
  final String messageType;
  final String message;
  final bool isMine;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? clientMessageId;
  final ChatMessageLocalStatus localStatus;

  String get identityKey {
    final serverId = messageId;
    if (serverId != null && serverId > 0) {
      return 'server:$serverId';
    }
    final requestId = clientMessageId?.trim() ?? '';
    if (requestId.isNotEmpty) {
      return 'client:$requestId';
    }
    throw StateError('A chat message must have a stable identity');
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final clientMessageId = chatString(json['client_message_id']);
    return ChatMessage(
      messageId: chatRequiredPositiveInt(
        json['message_id'],
        fieldName: 'message_id',
      ),
      conversationId: chatRequiredPositiveInt(
        json['conversation_id'],
        fieldName: 'conversation_id',
      ),
      senderRole: chatString(json['sender_role']),
      senderName: chatString(json['sender_name']),
      messageType: chatString(json['message_type'], fallback: 'text'),
      message: chatString(json['message']),
      isMine: chatBool(json['is_mine']),
      isRead: chatBool(json['is_read']),
      createdAt: chatDateTime(json['created_at_utc'] ?? json['created_at']),
      readAt: chatDateTime(json['read_at_utc'] ?? json['read_at']),
      clientMessageId: clientMessageId.isEmpty ? null : clientMessageId,
      localStatus: ChatMessageLocalStatus.sent,
    );
  }

  ChatMessage copyWith({
    int? messageId,
    bool clearMessageId = false,
    int? conversationId,
    String? senderRole,
    String? senderName,
    String? messageType,
    String? message,
    bool? isMine,
    bool? isRead,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    DateTime? readAt,
    bool clearReadAt = false,
    String? clientMessageId,
    bool clearClientMessageId = false,
    ChatMessageLocalStatus? localStatus,
  }) {
    return ChatMessage(
      messageId: clearMessageId ? null : (messageId ?? this.messageId),
      conversationId: conversationId ?? this.conversationId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      messageType: messageType ?? this.messageType,
      message: message ?? this.message,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      clientMessageId: clearClientMessageId
          ? null
          : (clientMessageId ?? this.clientMessageId),
      localStatus: localStatus ?? this.localStatus,
    );
  }
}
