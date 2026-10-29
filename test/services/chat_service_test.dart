import 'dart:convert';
import 'dart:typed_data';

import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late QueueHttpAdapter adapter;

  setUp(() {
    dio = Dio(
      BaseOptions(
        validateStatus: (_) => true,
        responseType: ResponseType.json,
      ),
    );
    adapter = QueueHttpAdapter();
    dio.httpClientAdapter = adapter;
  });

  test('does not send a request without an api key', () async {
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => null,
    );

    await expectLater(
      service.getUnreadCount(),
      throwsA(isA<ChatAuthenticationException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('lists conversations with secure header and no client identity',
      () async {
    adapter.enqueueJson(
      200,
      _success({
        'conversations': [
          {
            'conversation_id': '7',
            'conversation_type': 'shipment_client',
            'shipment_id': '91',
            'title': 'Operations',
            'policy_num': 'NOB-91',
            'last_message': 'Ready',
            'last_message_type': 'text',
            'last_message_at': '2026-07-30 12:00:00',
            'unread_count': '2',
          },
        ],
        'has_more': false,
        'next_cursor': null,
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final page = await service.listConversations();

    expect(page.conversations.single.conversationId, 7);
    expect(page.conversations.single.unreadCount, 2);
    final request = adapter.requests.single;
    expect(request.headers['X-API-KEY'], 'safe-test-key');
    expect(request.queryParameters['action'], 'list_conversations');
    expect(request.queryParameters.containsKey('client_id'), isFalse);
    expect(request.queryParameters.containsKey('sender_role'), isFalse);
  });

  test('sends a complete conversation cursor for the next page', () async {
    adapter.enqueueJson(
      200,
      _success({
        'conversations': <dynamic>[],
        'has_more': false,
        'next_cursor': null,
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await service.listConversations(
      cursorLastMessageAt: DateTime(2026, 7, 30, 12, 30),
      cursorId: 9,
    );

    final query = adapter.requests.single.queryParameters;
    expect(query['cursor_last_message_at'], '2026-07-30 12:30:00');
    expect(query['cursor_id'], 9);
  });

  test('gets initial and older message pages with correct cursors', () async {
    adapter
      ..enqueueJson(
        200,
        _success({
          'messages': <dynamic>[],
          'has_more': true,
          'next_before_message_id': 50,
        }),
      )
      ..enqueueJson(
        200,
        _success({
          'messages': <dynamic>[],
          'has_more': false,
          'next_before_message_id': null,
        }),
      );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final initial = await service.getMessages(conversationId: 9);
    await service.getMessages(
      conversationId: 9,
      beforeMessageId: initial.nextBeforeMessageId,
    );

    expect(
      adapter.requests.first.queryParameters.containsKey('before_message_id'),
      isFalse,
    );
    expect(
      adapter.requests.last.queryParameters['before_message_id'],
      50,
    );
  });

  test('gets new messages after the latest server id', () async {
    adapter.enqueueJson(
      200,
      _success({
        'messages': [
          {
            'message_id': 12,
            'conversation_id': 9,
            'sender_role': 'admin',
            'sender_name': 'Operations',
            'message_type': 'text',
            'message': 'Update',
            'is_mine': false,
            'is_read': false,
            'created_at': '2026-07-30 12:20:00',
          },
        ],
        'latest_message_id': 12,
        'has_more': false,
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final page = await service.getNewMessages(
      conversationId: 9,
      afterMessageId: 11,
    );

    expect(page.latestMessageId, 12);
    expect(page.messages.single.message, 'Update');
    expect(adapter.requests.single.queryParameters['after_message_id'], 11);
  });

  test('send message trims text and parses idempotent response', () async {
    adapter.enqueueJson(
      201,
      _success({
        'message': {
          'message_id': 44,
          'conversation_id': 9,
          'client_message_id': 'client-chat-test-44',
          'is_duplicate': false,
          'created_at': '2026-07-30 12:20:00',
        },
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final result = await service.sendMessage(
      conversationId: 9,
      message: '  hello  ',
      clientMessageId: 'client-chat-test-44',
    );

    expect(result.isDuplicate, isFalse);
    expect(result.message.message, 'hello');
    expect(result.message.localStatus, ChatMessageLocalStatus.sent);
    expect(result.message.clientMessageId, 'client-chat-test-44');
    final data = adapter.requests.single.data as Map<String, dynamic>;
    expect(data['message'], 'hello');
    expect(data.containsKey('client_id'), isFalse);
    expect(data.containsKey('sender_id'), isFalse);
  });

  for (final message in ['رسالة تجريبية', 'English message', 'تم ✅🚚']) {
    test('sends supported Unicode text: ${message.runes.length} runes',
        () async {
      adapter.enqueueJson(
        200,
        _success({
          'message': {
            'message_id': 45,
            'conversation_id': 9,
            'client_message_id': 'client-chat-unicode-45',
            'is_duplicate': true,
            'created_at': '2026-07-30 12:20:00',
          },
        }),
      );
      final service = ChatService(
        dio: dio,
        apiKeyLoader: () async => 'safe-test-key',
      );

      final result = await service.sendMessage(
        conversationId: 9,
        message: message,
        clientMessageId: 'client-chat-unicode-45',
      );

      expect(result.message.message, message);
    });
  }

  test('rejects an empty message before network request', () async {
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.sendMessage(
        conversationId: 9,
        message: '   ',
        clientMessageId: 'client-chat-empty-1',
      ),
      throwsA(isA<ChatValidationException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('maps conflict response to typed exception', () async {
    adapter.enqueueJson(
      409,
      _failure('CHAT_MESSAGE_CONFLICT'),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.sendMessage(
        conversationId: 9,
        message: 'hello',
        clientMessageId: 'client-chat-test-44',
      ),
      throwsA(
        isA<ChatConflictException>().having(
          (error) => error.isRetryable,
          'isRetryable',
          isFalse,
        ),
      ),
    );
  });

  test('maps rate limit and Retry-After safely', () async {
    adapter.enqueueJson(
      429,
      _failure('CHAT_RATE_LIMITED'),
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'retry-after': ['12'],
      },
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.getUnreadCount(),
      throwsA(
        isA<ChatRateLimitException>()
            .having(
              (error) => error.retryAfterSeconds,
              'retryAfterSeconds',
              12,
            )
            .having(
              (error) => error.isRetryable,
              'isRetryable',
              isTrue,
            ),
      ),
    );
  });

  for (final status in [401, 403]) {
    test('maps HTTP $status to the correct typed exception', () async {
      adapter.enqueueJson(
        status,
        _failure(status == 401 ? 'UNAUTHORIZED' : 'CHAT_ACCESS_DENIED'),
      );
      final service = ChatService(
        dio: dio,
        apiKeyLoader: () async => 'safe-test-key',
      );

      await expectLater(
        service.getUnreadCount(),
        throwsA(
          status == 401
              ? isA<ChatAuthenticationException>()
              : isA<ChatAuthorizationException>(),
        ),
      );
    });
  }

  test('maps malformed response to non-sensitive server exception', () async {
    adapter.enqueueRaw(200, '<html>failure</html>');
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.getUnreadCount(),
      throwsA(
        isA<ChatServerException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('validates message length before network request', () async {
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.sendMessage(
        conversationId: 1,
        message: List.filled(2001, 'a').join(),
        clientMessageId: 'client-chat-test-long',
      ),
      throwsA(isA<ChatValidationException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('maps transport timeout to retryable network exception', () async {
    adapter.failure = (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    await expectLater(
      service.getUnreadCount(),
      throwsA(
        isA<ChatNetworkException>().having(
          (error) => error.isRetryable,
          'isRetryable',
          isTrue,
        ),
      ),
    );
  });

  test('reads non-negative unread count from numeric string', () async {
    adapter.enqueueJson(
      200,
      _success({'unread_count': '6'}),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    expect(await service.getUnreadCount(), 6);
  });

  test('marks all messages through a single last read id', () async {
    adapter.enqueueJson(
      200,
      _success({
        'conversation_id': 9,
        'last_read_message_id': 55,
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final result = await service.markRead(
      conversationId: 9,
      lastReadMessageId: 55,
    );

    expect(result.lastReadMessageId, 55);
    final data = adapter.requests.single.data as Map<String, dynamic>;
    expect(data['action'], 'mark_read');
    expect(data['last_read_message_id'], 55);
  });

  test('gets or creates shipment conversation without client id', () async {
    adapter.enqueueJson(
      201,
      _success({
        'created': true,
        'conversation': {
          'conversation_id': 71,
          'conversation_type': 'shipment_client',
          'shipment_id': 81,
          'title': 'Operations',
          'policy_num': 'NOB-81',
          'last_message_at': null,
          'created_at': '2026-07-30 12:00:00',
        },
      }),
    );
    final service = ChatService(
      dio: dio,
      apiKeyLoader: () async => 'safe-test-key',
    );

    final result = await service.getOrCreateShipmentConversation(
      shipmentId: 81,
    );

    expect(result.created, isTrue);
    expect(result.conversation.conversationId, 71);
    final data = adapter.requests.single.data as Map<String, dynamic>;
    expect(data['shipment_id'], 81);
    expect(data.containsKey('client_id'), isFalse);
  });
}

Map<String, dynamic> _success(Map<String, dynamic> data) {
  return {
    'success': true,
    'status': 'success',
    'code': 'OK',
    'message': 'OK',
    'message_en': 'OK',
    'message_ar': 'OK',
    'data': data,
  };
}

Map<String, dynamic> _failure(String code) {
  return {
    'success': false,
    'status': 'error',
    'code': code,
    'message': 'Request failed',
    'message_en': 'Request failed',
    'message_ar': 'Request failed',
    'data': <String, dynamic>{},
  };
}

class QueueHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<ResponseBody> _responses = <ResponseBody>[];
  DioException Function(RequestOptions options)? failure;

  void enqueueJson(
    int statusCode,
    Map<String, dynamic> body, {
    Map<String, List<String>>? headers,
  }) {
    enqueueRaw(
      statusCode,
      jsonEncode(body),
      headers: headers ??
          {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
    );
  }

  void enqueueRaw(
    int statusCode,
    String body, {
    Map<String, List<String>>? headers,
  }) {
    _responses.add(
      ResponseBody.fromString(
        body,
        statusCode,
        headers: headers ??
            {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final requestFailure = failure;
    if (requestFailure != null) {
      throw requestFailure(options);
    }
    if (_responses.isEmpty) {
      throw StateError('No response queued');
    }
    return _responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}
