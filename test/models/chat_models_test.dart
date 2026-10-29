import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConversation', () {
    test('parses nullable values and numeric strings safely', () {
      final conversation = ChatConversation.fromJson({
        'conversation_id': '12',
        'conversation_type': 'shipment_client',
        'shipment_id': '45',
        'title': 'Operations',
        'policy_num': 'NOB-45',
        'last_message': null,
        'last_message_type': null,
        'last_message_at': '2026-07-30 09:30:00',
        'unread_count': '3',
      });

      expect(conversation.conversationId, 12);
      expect(conversation.shipmentId, 45);
      expect(conversation.lastMessage, isEmpty);
      expect(conversation.lastMessageType, 'text');
      expect(conversation.lastMessageAt, isNotNull);
      expect(conversation.unreadCount, 3);
    });

    test('rejects a missing stable conversation id', () {
      expect(
        () => ChatConversation.fromJson(const {}),
        throwsFormatException,
      );
    });
  });

  group('ChatMessage', () {
    test('parses server messages as sent', () {
      final message = ChatMessage.fromJson({
        'message_id': '8',
        'conversation_id': 2,
        'sender_role': 'admin',
        'sender_name': 'Operations',
        'message_type': 'text',
        'message': 'Hello',
        'is_mine': '0',
        'is_read': 1,
        'created_at': '2026-07-30 10:00:00',
      });

      expect(message.messageId, 8);
      expect(message.isMine, isFalse);
      expect(message.isRead, isTrue);
      expect(message.localStatus, ChatMessageLocalStatus.sent);
      expect(message.identityKey, 'server:8');
    });

    test('uses client id as optimistic identity', () {
      const message = ChatMessage(
        conversationId: 2,
        senderRole: 'client',
        senderName: '',
        messageType: 'text',
        message: 'Pending',
        isMine: true,
        isRead: false,
        clientMessageId: 'client-chat-test-1',
        localStatus: ChatMessageLocalStatus.sending,
      );

      expect(message.identityKey, 'client:client-chat-test-1');
    });
  });

  test('conversation pagination parses cursor contract', () {
    final page = ChatConversationPage.fromJson({
      'conversations': [
        {
          'conversation_id': 2,
          'conversation_type': 'shipment_client',
          'title': 'Operations',
          'last_message': '',
          'last_message_type': 'text',
          'unread_count': 0,
        },
      ],
      'has_more': true,
      'next_cursor': {
        'cursor_last_message_at': '2026-07-30 11:00:00',
        'cursor_id': '2',
      },
    });

    expect(page.conversations, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.nextCursorId, 2);
    expect(page.nextCursorLastMessageAt, isNotNull);
  });
}
