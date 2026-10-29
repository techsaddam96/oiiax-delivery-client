import 'dart:async';

import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:blockatie/provider/chat/chat_conversation_provider.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation list prevents duplicate initial requests', () async {
    final completer = Completer<ChatConversationPage>();
    final repository = FakeChatRepository()
      ..listConversationsHandler = ({
        required int limit,
        DateTime? cursorLastMessageAt,
        int? cursorId,
        CancelToken? cancelToken,
      }) {
        return completer.future;
      };
    final provider = ChatConversationsProvider(repository: repository);

    final first = provider.loadInitial();
    final second = provider.loadInitial();
    expect(repository.listConversationCalls, 1);
    completer.complete(
      ChatConversationPage(
        conversations: [_conversation(1)],
        hasMore: false,
      ),
    );
    await Future.wait([first, second]);

    expect(provider.state, ChatConversationsState.loaded);
    expect(provider.conversations, hasLength(1));
    provider.dispose();
  });

  test('conversation pagination merges duplicate ids once', () async {
    final repository = FakeChatRepository()
      ..conversationPages.addAll([
        ChatConversationPage(
          conversations: [_conversation(1), _conversation(2)],
          hasMore: true,
          nextCursorLastMessageAt: DateTime(2026, 7, 30, 12),
          nextCursorId: 2,
        ),
        ChatConversationPage(
          conversations: [_conversation(2), _conversation(3)],
          hasMore: false,
        ),
      ]);
    final provider = ChatConversationsProvider(repository: repository);

    await provider.loadInitial();
    await provider.loadMore();

    expect(
      provider.conversations.map((item) => item.conversationId),
      [1, 2, 3],
    );
    provider.dispose();
  });

  test('conversation list prevents concurrent load more requests', () async {
    final loadMoreCompleter = Completer<ChatConversationPage>();
    final repository = FakeChatRepository()
      ..conversationPages.add(
        ChatConversationPage(
          conversations: [_conversation(1)],
          hasMore: true,
          nextCursorLastMessageAt: DateTime(2026, 7, 30, 12),
          nextCursorId: 1,
        ),
      );
    final provider = ChatConversationsProvider(repository: repository);
    await provider.loadInitial();
    repository.listConversationsHandler = ({
      required int limit,
      DateTime? cursorLastMessageAt,
      int? cursorId,
      CancelToken? cancelToken,
    }) {
      return loadMoreCompleter.future;
    };

    final first = provider.loadMore();
    final second = provider.loadMore();
    expect(repository.listConversationCalls, 2);
    loadMoreCompleter.complete(
      const ChatConversationPage(conversations: [], hasMore: false),
    );
    await Future.wait([first, second]);

    expect(provider.isLoadingMore, isFalse);
    provider.dispose();
  });

  test('refresh replaces the existing conversation page', () async {
    final repository = FakeChatRepository()
      ..conversationPages.addAll([
        ChatConversationPage(
          conversations: [_conversation(1)],
          hasMore: false,
        ),
        ChatConversationPage(
          conversations: [_conversation(2)],
          hasMore: false,
        ),
      ]);
    final provider = ChatConversationsProvider(repository: repository);

    await provider.loadInitial();
    await provider.refresh();

    expect(
      provider.conversations.map((item) => item.conversationId),
      [2],
    );
    provider.dispose();
  });

  test('failed optimistic message retries with the same client id', () async {
    final sentClientIds = <String>[];
    var shouldFail = true;
    final repository = FakeChatRepository()
      ..sendHandler = ({
        required int conversationId,
        required String message,
        required String clientMessageId,
        CancelToken? cancelToken,
      }) async {
        sentClientIds.add(clientMessageId);
        if (shouldFail) {
          shouldFail = false;
          throw const ChatNetworkException();
        }
        return ChatSendResult(
          message: _message(
            id: 20,
            clientMessageId: clientMessageId,
            text: message,
            mine: true,
          ),
          isDuplicate: true,
        );
      };
    final provider = ChatConversationProvider(
      conversationId: 4,
      repository: repository,
    );

    expect(await provider.sendMessage('hello'), isFalse);
    final failed = provider.messages.single;
    expect(failed.localStatus, ChatMessageLocalStatus.failed);
    expect(failed.clientMessageId, isNotNull);

    expect(await provider.retryFailed(failed.clientMessageId!), isTrue);
    expect(sentClientIds, hasLength(2));
    expect(sentClientIds[0], sentClientIds[1]);
    expect(provider.messages, hasLength(1));
    expect(provider.messages.single.messageId, 20);
    expect(
      provider.messages.single.localStatus,
      ChatMessageLocalStatus.sent,
    );
    provider.dispose();
  });

  test('new message fetch deduplicates existing server messages', () async {
    final repository = FakeChatRepository()
      ..messagePages.add(
        ChatMessagesPage(
          messages: [_message(id: 1), _message(id: 2)],
          hasMore: false,
        ),
      )
      ..newMessagePages.add(
        ChatNewMessagesPage(
          messages: [_message(id: 2), _message(id: 3)],
          latestMessageId: 3,
          hasMore: false,
        ),
      );
    final provider = ChatConversationProvider(
      conversationId: 4,
      repository: repository,
    );

    await provider.loadInitial();
    await provider.fetchNewMessages();

    expect(provider.messages.map((message) => message.messageId), [1, 2, 3]);
    expect(provider.latestMessageId, 3);
    provider.dispose();
  });

  test('older messages remain ordered from oldest to newest', () async {
    final repository = FakeChatRepository()
      ..messagePages.addAll([
        ChatMessagesPage(
          messages: [_message(id: 3), _message(id: 4)],
          hasMore: true,
          nextBeforeMessageId: 3,
        ),
        ChatMessagesPage(
          messages: [_message(id: 1), _message(id: 2)],
          hasMore: false,
        ),
      ]);
    final provider = ChatConversationProvider(
      conversationId: 4,
      repository: repository,
    );

    await provider.loadInitial();
    await provider.loadOlder();

    expect(provider.messages.map((message) => message.messageId), [1, 2, 3, 4]);
    provider.dispose();
  });

  test('mark read changes local state only after backend success', () async {
    final repository = FakeChatRepository()
      ..messagePages.add(
        ChatMessagesPage(
          messages: [_message(id: 5, read: false)],
          hasMore: false,
        ),
      )
      ..readHandler = ({
        required int conversationId,
        required int lastReadMessageId,
        CancelToken? cancelToken,
      }) async {
        return ChatReadResult(
          conversationId: conversationId,
          lastReadMessageId: lastReadMessageId,
        );
      };
    final provider = ChatConversationProvider(
      conversationId: 4,
      repository: repository,
    );

    await provider.loadInitial();
    expect(provider.messages.single.isRead, isFalse);
    expect(await provider.markRead(), isTrue);
    expect(provider.messages.single.isRead, isTrue);
    provider.dispose();
  });

  test('disposing during load cancels notification safely', () async {
    final completer = Completer<ChatMessagesPage>();
    final repository = FakeChatRepository()
      ..getMessagesHandler = ({
        required int conversationId,
        int? beforeMessageId,
        required int limit,
        CancelToken? cancelToken,
      }) {
        return completer.future;
      };
    final provider = ChatConversationProvider(
      conversationId: 4,
      repository: repository,
    );

    final request = provider.loadInitial();
    provider.dispose();
    completer.complete(
      const ChatMessagesPage(messages: [], hasMore: false),
    );
    await request;
  });
}

ChatConversation _conversation(int id) {
  return ChatConversation(
    conversationId: id,
    conversationType: 'shipment_client',
    title: 'Operations',
    lastMessage: '',
    lastMessageType: 'text',
    unreadCount: 0,
  );
}

ChatMessage _message({
  required int id,
  String? clientMessageId,
  String text = 'message',
  bool mine = false,
  bool read = false,
}) {
  return ChatMessage(
    messageId: id,
    conversationId: 4,
    senderRole: mine ? 'client' : 'admin',
    senderName: mine ? '' : 'Operations',
    messageType: 'text',
    message: text,
    isMine: mine,
    isRead: read,
    createdAt: DateTime(2026, 7, 30, 12, id),
    clientMessageId: clientMessageId,
    localStatus: ChatMessageLocalStatus.sent,
  );
}

typedef ListConversationsHandler = Future<ChatConversationPage> Function({
  required int limit,
  DateTime? cursorLastMessageAt,
  int? cursorId,
  CancelToken? cancelToken,
});

typedef GetMessagesHandler = Future<ChatMessagesPage> Function({
  required int conversationId,
  int? beforeMessageId,
  required int limit,
  CancelToken? cancelToken,
});

typedef SendHandler = Future<ChatSendResult> Function({
  required int conversationId,
  required String message,
  required String clientMessageId,
  CancelToken? cancelToken,
});

typedef ReadHandler = Future<ChatReadResult> Function({
  required int conversationId,
  required int lastReadMessageId,
  CancelToken? cancelToken,
});

class FakeChatRepository implements ChatRepository {
  final List<ChatConversationPage> conversationPages = [];
  final List<ChatMessagesPage> messagePages = [];
  final List<ChatNewMessagesPage> newMessagePages = [];
  int listConversationCalls = 0;
  ListConversationsHandler? listConversationsHandler;
  GetMessagesHandler? getMessagesHandler;
  SendHandler? sendHandler;
  ReadHandler? readHandler;

  @override
  Future<ChatConversationPage> listConversations({
    int limit = 20,
    DateTime? cursorLastMessageAt,
    int? cursorId,
    CancelToken? cancelToken,
  }) {
    listConversationCalls++;
    final handler = listConversationsHandler;
    if (handler != null) {
      return handler(
        limit: limit,
        cursorLastMessageAt: cursorLastMessageAt,
        cursorId: cursorId,
        cancelToken: cancelToken,
      );
    }
    return Future.value(conversationPages.removeAt(0));
  }

  @override
  Future<ChatMessagesPage> getMessages({
    required int conversationId,
    int? beforeMessageId,
    int limit = 30,
    CancelToken? cancelToken,
  }) {
    final handler = getMessagesHandler;
    if (handler != null) {
      return handler(
        conversationId: conversationId,
        beforeMessageId: beforeMessageId,
        limit: limit,
        cancelToken: cancelToken,
      );
    }
    return Future.value(messagePages.removeAt(0));
  }

  @override
  Future<ChatNewMessagesPage> getNewMessages({
    required int conversationId,
    required int afterMessageId,
    int limit = 50,
    CancelToken? cancelToken,
  }) {
    return Future.value(newMessagePages.removeAt(0));
  }

  @override
  Future<ChatSendResult> sendMessage({
    required int conversationId,
    required String message,
    required String clientMessageId,
    CancelToken? cancelToken,
  }) {
    final handler = sendHandler;
    if (handler == null) {
      throw StateError('sendHandler is not configured');
    }
    return handler(
      conversationId: conversationId,
      message: message,
      clientMessageId: clientMessageId,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatReadResult> markRead({
    required int conversationId,
    required int lastReadMessageId,
    CancelToken? cancelToken,
  }) {
    final handler = readHandler;
    if (handler == null) {
      throw StateError('readHandler is not configured');
    }
    return handler(
      conversationId: conversationId,
      lastReadMessageId: lastReadMessageId,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<int> getUnreadCount({CancelToken? cancelToken}) async => 0;

  @override
  Future<ChatConversationReadyResult> getOrCreateShipmentConversation({
    required int shipmentId,
    CancelToken? cancelToken,
  }) {
    return Future.value(
      ChatConversationReadyResult(
        created: false,
        conversation: _conversation(1),
      ),
    );
  }
}
