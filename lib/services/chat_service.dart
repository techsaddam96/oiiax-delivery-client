import 'package:blockatie/services/session_dio.dart';
import 'dart:convert';
import 'dart:math';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/chat/chat_api_response.dart';
import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/models/chat/chat_pagination.dart';
import 'package:blockatie/models/chat/chat_parsing.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';

typedef ChatApiKeyLoader = Future<String?> Function();

abstract interface class ChatRepository {
  Future<ChatConversationPage> listConversations({
    int limit = 20,
    DateTime? cursorLastMessageAt,
    int? cursorId,
    CancelToken? cancelToken,
  });

  Future<ChatMessagesPage> getMessages({
    required int conversationId,
    int? beforeMessageId,
    int limit = 30,
    CancelToken? cancelToken,
  });

  Future<ChatNewMessagesPage> getNewMessages({
    required int conversationId,
    required int afterMessageId,
    int limit = 50,
    CancelToken? cancelToken,
  });

  Future<ChatSendResult> sendMessage({
    required int conversationId,
    required String message,
    required String clientMessageId,
    CancelToken? cancelToken,
  });

  Future<ChatReadResult> markRead({
    required int conversationId,
    required int lastReadMessageId,
    CancelToken? cancelToken,
  });

  Future<int> getUnreadCount({CancelToken? cancelToken});

  Future<ChatConversationReadyResult> getOrCreateShipmentConversation({
    required int shipmentId,
    CancelToken? cancelToken,
  });
}

class ChatService implements ChatRepository {
  ChatService({
    Dio? dio,
    ChatApiKeyLoader? apiKeyLoader,
  })  : _dio = dio ??
            sessionDio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {'Accept': 'application/json'},
                validateStatus: (_) => true,
              ),
            ),
        _apiKeyLoader = apiKeyLoader ?? AuthService.getApiKey;

  final Dio _dio;
  final ChatApiKeyLoader _apiKeyLoader;

  static final Random _secureRandom = Random.secure();
  static const int _maximumMessageLength = 2000;
  static final RegExp _clientMessageIdPattern =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$');

  static String generateClientMessageId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = List<String>.generate(
      4,
      (_) =>
          _secureRandom.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 'client-chat-$timestamp-$randomPart';
  }

  @override
  Future<ChatConversationPage> listConversations({
    int limit = 20,
    DateTime? cursorLastMessageAt,
    int? cursorId,
    CancelToken? cancelToken,
  }) async {
    _validateLimit(limit, maximum: 50);
    if ((cursorLastMessageAt == null) != (cursorId == null)) {
      throw const ChatValidationException(
        code: 'INVALID_CURSOR',
        safeMessage: 'chat_invalid_cursor',
      );
    }
    if (cursorId != null && cursorId <= 0) {
      throw const ChatValidationException(
        code: 'INVALID_CURSOR',
        safeMessage: 'chat_invalid_cursor',
      );
    }

    final parameters = <String, dynamic>{
      'action': 'list_conversations',
      'limit': limit,
    };
    if (cursorLastMessageAt != null && cursorId != null) {
      parameters['cursor_last_message_at'] =
          _formatDatabaseDateTime(cursorLastMessageAt);
      parameters['cursor_id'] = cursorId;
    }

    return _get(
      parameters: parameters,
      parser: ChatConversationPage.fromJson,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatMessagesPage> getMessages({
    required int conversationId,
    int? beforeMessageId,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    _validatePositiveId(conversationId, 'conversation_id');
    _validateLimit(limit, maximum: 50);
    if (beforeMessageId != null && beforeMessageId <= 0) {
      throw const ChatValidationException(
        code: 'INVALID_BEFORE_MESSAGE_ID',
        safeMessage: 'chat_invalid_message_cursor',
      );
    }

    final parameters = <String, dynamic>{
      'action': 'get_messages',
      'conversation_id': conversationId,
      'limit': limit,
    };
    if (beforeMessageId != null) {
      parameters['before_message_id'] = beforeMessageId;
    }

    return _get(
      parameters: parameters,
      parser: ChatMessagesPage.fromJson,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatNewMessagesPage> getNewMessages({
    required int conversationId,
    required int afterMessageId,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    _validatePositiveId(conversationId, 'conversation_id');
    _validateLimit(limit, maximum: 100);
    if (afterMessageId < 0) {
      throw const ChatValidationException(
        code: 'INVALID_AFTER_MESSAGE_ID',
        safeMessage: 'chat_invalid_message_cursor',
      );
    }

    return _get(
      parameters: {
        'action': 'get_new_messages',
        'conversation_id': conversationId,
        'after_message_id': afterMessageId,
        'limit': limit,
      },
      parser: ChatNewMessagesPage.fromJson,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatSendResult> sendMessage({
    required int conversationId,
    required String message,
    required String clientMessageId,
    CancelToken? cancelToken,
  }) async {
    _validatePositiveId(conversationId, 'conversation_id');
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      throw const ChatValidationException(
        code: 'EMPTY_MESSAGE',
        safeMessage: 'chat_message_required',
      );
    }
    if (normalizedMessage.runes.length > _maximumMessageLength) {
      throw const ChatValidationException(
        code: 'MESSAGE_TOO_LONG',
        safeMessage: 'chat_message_too_long',
      );
    }
    _validateClientMessageId(clientMessageId);

    final payload = await _post(
      data: {
        'action': 'send_message',
        'conversation_id': conversationId,
        'message': normalizedMessage,
        'client_message_id': clientMessageId,
      },
      parser: (data) => chatJsonMap(
        data['message'],
        fieldName: 'message',
      ),
      cancelToken: cancelToken,
    );

    final responseConversationId = chatRequiredPositiveInt(
      payload['conversation_id'],
      fieldName: 'conversation_id',
    );
    final responseClientMessageId = chatString(payload['client_message_id']);
    if (responseConversationId != conversationId ||
        responseClientMessageId != clientMessageId) {
      throw const ChatServerException(
        code: 'INVALID_RESPONSE',
        safeMessage: 'chat_invalid_server_response',
        isRetryable: false,
      );
    }

    return ChatSendResult(
      message: ChatMessage(
        messageId: chatRequiredPositiveInt(
          payload['message_id'],
          fieldName: 'message_id',
        ),
        conversationId: responseConversationId,
        senderRole: 'client',
        senderName: '',
        messageType: 'text',
        message: normalizedMessage,
        isMine: true,
        isRead: false,
        createdAt:
            chatDateTime(payload['created_at_utc'] ?? payload['created_at']),
        clientMessageId: responseClientMessageId,
        localStatus: ChatMessageLocalStatus.sent,
      ),
      isDuplicate: chatBool(payload['is_duplicate']),
    );
  }

  @override
  Future<ChatReadResult> markRead({
    required int conversationId,
    required int lastReadMessageId,
    CancelToken? cancelToken,
  }) async {
    _validatePositiveId(conversationId, 'conversation_id');
    _validatePositiveId(lastReadMessageId, 'last_read_message_id');

    return _post(
      data: {
        'action': 'mark_read',
        'conversation_id': conversationId,
        'last_read_message_id': lastReadMessageId,
      },
      parser: ChatReadResult.fromJson,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<int> getUnreadCount({CancelToken? cancelToken}) async {
    final count = await _get(
      parameters: const {'action': 'unread_count'},
      parser: (data) => chatInt(data['unread_count']) ?? 0,
      cancelToken: cancelToken,
    );
    return count < 0 ? 0 : count;
  }

  @override
  Future<ChatConversationReadyResult> getOrCreateShipmentConversation({
    required int shipmentId,
    CancelToken? cancelToken,
  }) async {
    _validatePositiveId(shipmentId, 'shipment_id');
    return _post(
      data: {
        'action': 'get_or_create_shipment_conversation',
        'shipment_id': shipmentId,
      },
      parser: ChatConversationReadyResult.fromJson,
      cancelToken: cancelToken,
    );
  }

  Future<T> _get<T>({
    required Map<String, dynamic> parameters,
    required T Function(Map<String, dynamic> data) parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'GET',
      queryParameters: parameters,
      parser: parser,
      cancelToken: cancelToken,
    );
  }

  Future<T> _post<T>({
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic> data) parser,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'POST',
      data: data,
      parser: parser,
      cancelToken: cancelToken,
    );
  }

  Future<T> _request<T>({
    required String method,
    required T Function(Map<String, dynamic> data) parser,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    final apiKey = (await _apiKeyLoader())?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const ChatAuthenticationException();
    }

    try {
      final response = await _dio.request<dynamic>(
        AppUrls.clientChat,
        queryParameters: queryParameters,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          contentType:
              method == 'POST' ? Headers.formUrlEncodedContentType : null,
          headers: {
            'Accept': 'application/json',
            'X-API-KEY': apiKey,
          },
        ),
      );
      final json = _decodeResponse(response.data);
      final envelope = ChatApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data,
      );
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300 ||
          !envelope.success) {
        throw _httpException(
          response.statusCode,
          envelope,
          response.headers,
        );
      }
      return parser(envelope.data);
    } on ChatException {
      rethrow;
    } on FormatException {
      throw const ChatServerException(
        code: 'INVALID_RESPONSE',
        safeMessage: 'chat_invalid_server_response',
        isRetryable: false,
      );
    } on DioException catch (error) {
      throw _dioException(error);
    } catch (_) {
      throw const ChatServerException();
    }
  }

  static Map<String, dynamic> _decodeResponse(dynamic body) {
    if (body is String) {
      final normalized = body.trim();
      if (normalized.isEmpty) {
        throw const FormatException('Empty chat response');
      }
      return chatJsonMap(
        jsonDecode(normalized),
        fieldName: 'response',
      );
    }
    return chatJsonMap(body, fieldName: 'response');
  }

  static ChatException _httpException<T>(
    int? statusCode,
    ChatApiResponse<T> response,
    Headers headers,
  ) {
    final code = response.code.isEmpty ? null : response.code;
    final messageEn = response.messageEn.isEmpty ? null : response.messageEn;
    final messageAr = response.messageAr.isEmpty ? null : response.messageAr;
    switch (statusCode) {
      case 401:
        return ChatAuthenticationException(
          code: code,
          messageEn: messageEn,
          messageAr: messageAr,
        );
      case 403:
        return ChatAuthorizationException(
          code: code,
          messageEn: messageEn,
          messageAr: messageAr,
        );
      case 409:
        return ChatConflictException(
          code: code,
          messageEn: messageEn,
          messageAr: messageAr,
        );
      case 429:
        final retryAfter = int.tryParse(
          headers.value('retry-after') ?? '',
        );
        return ChatRateLimitException(
          code: code,
          retryAfterSeconds: retryAfter,
          messageEn: messageEn,
          messageAr: messageAr,
        );
      case 400:
      case 404:
      case 405:
      case 413:
      case 422:
        return ChatValidationException(
          statusCode: statusCode,
          code: code,
          messageEn: messageEn,
          messageAr: messageAr,
        );
      default:
        return ChatServerException(
          statusCode: statusCode,
          code: code,
          messageEn: messageEn,
          messageAr: messageAr,
        );
    }
  }

  static ChatException _dioException(DioException error) {
    final response = error.response;
    if (response != null) {
      try {
        final json = _decodeResponse(response.data);
        final envelope = ChatApiResponse<Map<String, dynamic>>.fromJson(
          json,
          (data) => data,
        );
        return _httpException(
          response.statusCode,
          envelope,
          response.headers,
        );
      } catch (_) {
        return ChatServerException(statusCode: response.statusCode);
      }
    }
    if (error.error is FormatException) {
      return const ChatServerException(
        code: 'INVALID_RESPONSE',
        safeMessage: 'chat_invalid_server_response',
        isRetryable: false,
      );
    }
    if (error.type == DioExceptionType.cancel) {
      return const ChatNetworkException(
        code: 'REQUEST_CANCELLED',
        safeMessage: 'chat_request_cancelled',
        isRetryable: false,
      );
    }
    return const ChatNetworkException();
  }

  static void _validatePositiveId(int value, String fieldName) {
    if (value <= 0) {
      throw ChatValidationException(
        code: 'INVALID_${fieldName.toUpperCase()}',
        safeMessage: 'chat_invalid_request',
      );
    }
  }

  static void _validateLimit(int limit, {required int maximum}) {
    if (limit < 1 || limit > maximum) {
      throw const ChatValidationException(
        code: 'INVALID_LIMIT',
        safeMessage: 'chat_invalid_limit',
      );
    }
  }

  static void _validateClientMessageId(String value) {
    final normalized = value.trim();
    if (normalized.length < 8 ||
        normalized.length > 100 ||
        !_clientMessageIdPattern.hasMatch(normalized)) {
      throw const ChatValidationException(
        code: 'INVALID_CLIENT_MESSAGE_ID',
        safeMessage: 'chat_invalid_client_message_id',
      );
    }
  }

  static String _formatDatabaseDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }
}
