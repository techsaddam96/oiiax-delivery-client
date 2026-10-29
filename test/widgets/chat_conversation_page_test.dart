import 'dart:async';
import 'package:blockatie/services/user_session_state.dart';

import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/views/pages/chat/conversation_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'session reset stops polling and clears an open conversation draft',
      (tester) async {
    final repository = _WidgetChatRepository();
    await tester.pumpWidget(_chatApp(repository));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Private draft');
    await tester.pump(const Duration(seconds: 6));
    final calls = repository.newMessageCalls;
    expect(calls, greaterThan(0));
    UserSessionState.reset(SessionResetReason.logout);
    await tester.pump();
    expect(find.text('Private draft'), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    expect(repository.newMessageCalls, calls);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows loading then an empty conversation state', (tester) async {
    final messages = Completer<ChatMessagesPage>();
    final repository = _WidgetChatRepository()
      ..getMessagesHandler = ({
        required int conversationId,
        int? beforeMessageId,
        required int limit,
        CancelToken? cancelToken,
      }) =>
          messages.future;

    await tester.pumpWidget(_chatApp(repository));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    messages.complete(const ChatMessagesPage(messages: [], hasMore: false));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders client and admin messages without interpreting content',
      (tester) async {
    final repository = _WidgetChatRepository()
      ..messagePage = ChatMessagesPage(
        messages: <ChatMessage>[
          _message(id: 1, text: '<b>رسالة العميل</b>', mine: true),
          _message(id: 2, text: 'Admin reply 😀', mine: false),
        ],
        hasMore: false,
      );

    await tester.pumpWidget(_chatApp(repository, locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('<b>رسالة العميل</b>'), findsOneWidget);
    expect(find.text('Admin reply 😀'), findsOneWidget);
    expect(find.text('Operations'), findsNWidgets(2));
  });
}

Widget _chatApp(_WidgetChatRepository repository, {Locale? locale}) {
  return ChangeNotifierProvider<ChatConversationsProvider>(
    create: (_) => ChatConversationsProvider(repository: repository),
    child: MaterialApp(
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ConversationPage(
        conversationId: 4,
        title: 'Operations',
        repository: repository,
      ),
    ),
  );
}

ChatMessage _message({
  required int id,
  required String text,
  required bool mine,
}) {
  return ChatMessage(
    messageId: id,
    conversationId: 4,
    senderRole: mine ? 'client' : 'admin',
    senderName: mine ? '' : 'Operations',
    messageType: 'text',
    message: text,
    isMine: mine,
    isRead: false,
    createdAt: DateTime(2026, 7, 30, 12, id),
    localStatus: ChatMessageLocalStatus.sent,
  );
}

class _WidgetChatRepository implements ChatRepository {
  int newMessageCalls = 0;
  ChatMessagesPage messagePage = const ChatMessagesPage(
    messages: <ChatMessage>[],
    hasMore: false,
  );
  Future<ChatMessagesPage> Function({
    required int conversationId,
    int? beforeMessageId,
    required int limit,
    CancelToken? cancelToken,
  })? getMessagesHandler;

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
    return Future<ChatMessagesPage>.value(messagePage);
  }

  @override
  Future<ChatNewMessagesPage> getNewMessages({
    required int conversationId,
    required int afterMessageId,
    int limit = 50,
    CancelToken? cancelToken,
  }) {
    newMessageCalls++;
    return Future<ChatNewMessagesPage>.value(
      const ChatNewMessagesPage(
        messages: <ChatMessage>[],
        latestMessageId: 0,
        hasMore: false,
      ),
    );
  }

  @override
  Future<ChatConversationPage> listConversations({
    int limit = 20,
    DateTime? cursorLastMessageAt,
    int? cursorId,
    CancelToken? cancelToken,
  }) =>
      Future<ChatConversationPage>.value(
        const ChatConversationPage(
          conversations: <ChatConversation>[],
          hasMore: false,
        ),
      );

  @override
  Future<ChatSendResult> sendMessage({
    required int conversationId,
    required String message,
    required String clientMessageId,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<ChatReadResult> markRead({
    required int conversationId,
    required int lastReadMessageId,
    CancelToken? cancelToken,
  }) =>
      Future<ChatReadResult>.value(
        ChatReadResult(
          conversationId: conversationId,
          lastReadMessageId: lastReadMessageId,
        ),
      );

  @override
  Future<int> getUnreadCount({CancelToken? cancelToken}) async => 0;

  @override
  Future<ChatConversationReadyResult> getOrCreateShipmentConversation({
    required int shipmentId,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}
