import 'chat_conversation.dart';
import 'chat_message.dart';
import 'chat_parsing.dart';

class ChatConversationPage {
  const ChatConversationPage({
    required this.conversations,
    required this.hasMore,
    this.nextCursorLastMessageAt,
    this.nextCursorId,
  });

  final List<ChatConversation> conversations;
  final bool hasMore;
  final DateTime? nextCursorLastMessageAt;
  final int? nextCursorId;

  factory ChatConversationPage.fromJson(Map<String, dynamic> json) {
    final cursor = chatJsonMap(
      json['next_cursor'],
      fieldName: 'next_cursor',
      allowNull: true,
    );
    return ChatConversationPage(
      conversations: List<ChatConversation>.unmodifiable(
        chatJsonList(
          json['conversations'],
          fieldName: 'conversations',
        ).map(
          (item) => ChatConversation.fromJson(
            chatJsonMap(item, fieldName: 'conversation'),
          ),
        ),
      ),
      hasMore: chatBool(json['has_more']),
      nextCursorLastMessageAt: chatDateTime(cursor['cursor_last_message_at']),
      nextCursorId: chatInt(cursor['cursor_id']),
    );
  }
}

class ChatMessagesPage {
  const ChatMessagesPage({
    required this.messages,
    required this.hasMore,
    this.nextBeforeMessageId,
  });

  final List<ChatMessage> messages;
  final bool hasMore;
  final int? nextBeforeMessageId;

  factory ChatMessagesPage.fromJson(Map<String, dynamic> json) {
    return ChatMessagesPage(
      messages: List<ChatMessage>.unmodifiable(
        chatJsonList(json['messages'], fieldName: 'messages').map(
          (item) => ChatMessage.fromJson(
            chatJsonMap(item, fieldName: 'message'),
          ),
        ),
      ),
      hasMore: chatBool(json['has_more']),
      nextBeforeMessageId: chatInt(json['next_before_message_id']),
    );
  }
}

class ChatNewMessagesPage {
  const ChatNewMessagesPage({
    required this.messages,
    required this.latestMessageId,
    required this.hasMore,
  });

  final List<ChatMessage> messages;
  final int latestMessageId;
  final bool hasMore;

  factory ChatNewMessagesPage.fromJson(Map<String, dynamic> json) {
    final latestMessageId = chatInt(json['latest_message_id']);
    if (latestMessageId == null || latestMessageId < 0) {
      throw const FormatException(
        'Invalid chat contract field: latest_message_id',
      );
    }
    return ChatNewMessagesPage(
      messages: List<ChatMessage>.unmodifiable(
        chatJsonList(json['messages'], fieldName: 'messages').map(
          (item) => ChatMessage.fromJson(
            chatJsonMap(item, fieldName: 'message'),
          ),
        ),
      ),
      latestMessageId: latestMessageId,
      hasMore: chatBool(json['has_more']),
    );
  }
}

class ChatSendResult {
  const ChatSendResult({
    required this.message,
    required this.isDuplicate,
  });

  final ChatMessage message;
  final bool isDuplicate;
}

class ChatReadResult {
  const ChatReadResult({
    required this.conversationId,
    required this.lastReadMessageId,
  });

  final int conversationId;
  final int lastReadMessageId;

  factory ChatReadResult.fromJson(Map<String, dynamic> json) {
    return ChatReadResult(
      conversationId: chatRequiredPositiveInt(
        json['conversation_id'],
        fieldName: 'conversation_id',
      ),
      lastReadMessageId: chatRequiredPositiveInt(
        json['last_read_message_id'],
        fieldName: 'last_read_message_id',
      ),
    );
  }
}

class ChatConversationReadyResult {
  const ChatConversationReadyResult({
    required this.created,
    required this.conversation,
  });

  final bool created;
  final ChatConversation conversation;

  factory ChatConversationReadyResult.fromJson(Map<String, dynamic> json) {
    return ChatConversationReadyResult(
      created: chatBool(json['created']),
      conversation: ChatConversation.fromJson(
        chatJsonMap(json['conversation'], fieldName: 'conversation'),
      ),
    );
  }
}
