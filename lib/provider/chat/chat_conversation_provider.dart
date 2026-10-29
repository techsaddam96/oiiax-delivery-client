import 'package:blockatie/services/user_session_state.dart';
import 'dart:collection';

import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:dio/dio.dart';

enum ChatConversationState {
  initial,
  loading,
  loaded,
  loadingOlder,
  loadingNewer,
  empty,
  error,
}

class ChatConversationProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _loadGeneration++;
    _loadToken?.cancel('session changed');
    _sendToken?.cancel('session changed');
    _readToken?.cancel('session changed');
    _loadToken = null;
    _sendToken = null;
    _readToken = null;
    _messages.clear();
    _state = ChatConversationState.initial;
    _hasOlder = true;
    _hasMoreNewer = false;
    _nextBeforeMessageId = null;
    _latestMessageId = 0;
    _isSending = false;
    _isMarkingRead = false;
    _isRefreshingReadReceipts = false;
    _errorMessage = null;
  }

  ChatConversationProvider({
    required this.conversationId,
    required ChatRepository repository,
    this.pageSize = 30,
    this.newMessagesPageSize = 50,
  })  : assert(conversationId > 0),
        _repository = repository;

  final int conversationId;
  final ChatRepository _repository;
  final int pageSize;
  final int newMessagesPageSize;

  final List<ChatMessage> _messages = <ChatMessage>[];
  ChatConversationState _state = ChatConversationState.initial;
  bool _hasOlder = true;
  bool _hasMoreNewer = false;
  int? _nextBeforeMessageId;
  int _latestMessageId = 0;
  bool _isSending = false;
  bool _isMarkingRead = false;
  bool _isRefreshingReadReceipts = false;
  String? _errorMessage;
  CancelToken? _loadToken;
  CancelToken? _sendToken;
  CancelToken? _readToken;
  int _loadGeneration = 0;
  bool _disposed = false;

  UnmodifiableListView<ChatMessage> get messages =>
      UnmodifiableListView(_messages);
  ChatConversationState get state => _state;
  bool get hasOlder => _hasOlder;
  bool get hasMoreNewer => _hasMoreNewer;
  bool get isSending => _isSending;
  bool get isMarkingRead => _isMarkingRead;
  String? get errorMessage => _errorMessage;
  int get latestMessageId => _latestMessageId;
  bool get isLoading => _state == ChatConversationState.loading;
  bool get isLoadingOlder => _state == ChatConversationState.loadingOlder;
  bool get isLoadingNewer => _state == ChatConversationState.loadingNewer;

  Future<void> loadInitial() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading || _messages.isNotEmpty) {
        return;
      }
      final generation = ++_loadGeneration;
      final token = CancelToken();
      _loadToken = token;
      _state = ChatConversationState.loading;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.getMessages(
              conversationId: conversationId,
              limit: pageSize,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _messages
          ..clear()
          ..addAll(page.messages);
        _sortAndRecalculateLatest();
        _hasOlder = page.hasMore;
        _nextBeforeMessageId = page.nextBeforeMessageId;
        _state = _messages.isEmpty
            ? ChatConversationState.empty
            : ChatConversationState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = ChatConversationState.error;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _loadToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> loadOlder() async {
    final sessionGeneration = stateGeneration;
    try {
      if (!_hasOlder ||
          isLoading ||
          isLoadingOlder ||
          _nextBeforeMessageId == null) {
        return;
      }
      final generation = ++_loadGeneration;
      final token = CancelToken();
      _loadToken = token;
      _state = ChatConversationState.loadingOlder;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.getMessages(
              conversationId: conversationId,
              beforeMessageId: _nextBeforeMessageId,
              limit: pageSize,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _mergeMessages(page.messages);
        _hasOlder = page.hasMore;
        _nextBeforeMessageId = page.nextBeforeMessageId;
        _state = _messages.isEmpty
            ? ChatConversationState.empty
            : ChatConversationState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = _messages.isEmpty
            ? ChatConversationState.error
            : ChatConversationState.loaded;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _loadToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> fetchNewMessages() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading || isLoadingOlder || isLoadingNewer) {
        return;
      }
      final generation = ++_loadGeneration;
      final token = CancelToken();
      _loadToken = token;
      _state = ChatConversationState.loadingNewer;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.getNewMessages(
              conversationId: conversationId,
              afterMessageId: _latestMessageId,
              limit: newMessagesPageSize,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _mergeMessages(page.messages);
        _latestMessageId = page.latestMessageId > _latestMessageId
            ? page.latestMessageId
            : _latestMessageId;
        _hasMoreNewer = page.hasMore;
        _state = _messages.isEmpty
            ? ChatConversationState.empty
            : ChatConversationState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = _messages.isEmpty
            ? ChatConversationState.error
            : ChatConversationState.loaded;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _loadToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<bool> sendMessage(String value) async {
    final sessionGeneration = stateGeneration;
    try {
      final normalized = value.trim();
      if (_isSending) {
        return false;
      }
      if (normalized.isEmpty) {
        _errorMessage = 'chat_message_required';
        _notify();
        return false;
      }

      final clientMessageId = ChatService.generateClientMessageId();
      final optimisticMessage = ChatMessage(
        conversationId: conversationId,
        senderRole: 'client',
        senderName: '',
        messageType: 'text',
        message: normalized,
        isMine: true,
        isRead: false,
        createdAt: DateTime.now(),
        clientMessageId: clientMessageId,
        localStatus: ChatMessageLocalStatus.sending,
      );
      _messages.add(optimisticMessage);
      _isSending = true;
      _errorMessage = null;
      _sortAndRecalculateLatest();
      _notify();

      return await guardSession(
          _submitMessage(
            message: normalized,
            clientMessageId: clientMessageId,
          ),
          sessionGeneration);
    } on SessionChanged {
      return false;
    }
  }

  Future<bool> retryFailed(String clientMessageId) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isSending) {
        return false;
      }
      final index = _messages.indexWhere(
        (message) =>
            message.clientMessageId == clientMessageId &&
            message.localStatus == ChatMessageLocalStatus.failed,
      );
      if (index < 0) {
        return false;
      }

      final failedMessage = _messages[index];
      _messages[index] = failedMessage.copyWith(
        localStatus: ChatMessageLocalStatus.sending,
      );
      _isSending = true;
      _errorMessage = null;
      _notify();
      return await guardSession(
          _submitMessage(
            message: failedMessage.message,
            clientMessageId: clientMessageId,
          ),
          sessionGeneration);
    } on SessionChanged {
      return false;
    }
  }

  Future<bool> _submitMessage({
    required String message,
    required String clientMessageId,
  }) async {
    final sessionGeneration = stateGeneration;
    try {
      final token = CancelToken();
      _sendToken = token;
      try {
        final result = await guardSession(
            _repository.sendMessage(
              conversationId: conversationId,
              message: message,
              clientMessageId: clientMessageId,
              cancelToken: token,
            ),
            sessionGeneration);
        if (_disposed || token.isCancelled) {
          return false;
        }
        _mergeMessages(<ChatMessage>[result.message]);
        return true;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_disposed && !_isCancelled(error)) {
          _setLocalMessageStatus(
            clientMessageId,
            ChatMessageLocalStatus.failed,
          );
          _errorMessage = _safeMessage(error);
        }
        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (!_disposed && identical(_sendToken, token)) {
            _isSending = false;
            _sendToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<bool> markRead() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isMarkingRead) {
        return false;
      }
      final lastReadableMessageId = _messages
          .where(
            (message) =>
                !message.isMine &&
                message.messageId != null &&
                message.messageId! > 0,
          )
          .fold<int>(
            0,
            (latest, message) =>
                message.messageId! > latest ? message.messageId! : latest,
          );
      if (lastReadableMessageId == 0) {
        return false;
      }

      _isMarkingRead = true;
      final token = CancelToken();
      _readToken = token;
      _notify();
      try {
        final result = await guardSession(
            _repository.markRead(
              conversationId: conversationId,
              lastReadMessageId: lastReadableMessageId,
              cancelToken: token,
            ),
            sessionGeneration);
        if (_disposed || token.isCancelled) {
          return false;
        }
        for (var index = 0; index < _messages.length; index++) {
          final current = _messages[index];
          final messageId = current.messageId;
          if (!current.isMine &&
              messageId != null &&
              messageId <= result.lastReadMessageId) {
            _messages[index] = current.copyWith(isRead: true);
          }
        }
        return true;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_disposed && !_isCancelled(error)) {
          _errorMessage = _safeMessage(error);
        }
        return false;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (!_disposed && identical(_readToken, token)) {
            _isMarkingRead = false;
            _readToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return false;
    }
  }

  Future<void> refreshReadReceipts() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isRefreshingReadReceipts ||
          !_messages.any(
            (message) =>
                message.isMine &&
                !message.isRead &&
                message.messageId != null &&
                message.messageId! > 0,
          )) {
        return;
      }

      _isRefreshingReadReceipts = true;
      try {
        final page = await guardSession(
            _repository.getMessages(
              conversationId: conversationId,
              limit: pageSize,
            ),
            sessionGeneration);
        if (_disposed) {
          return;
        }
        _mergeMessages(page.messages);
        _notify();
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        // Receipt refresh is opportunistic and must never interrupt chat usage.
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isRefreshingReadReceipts = false;
        }
      }
    } on SessionChanged {
      return;
    }
  }

  void _mergeMessages(Iterable<ChatMessage> incoming) {
    final serverIndexes = <int, int>{};
    final clientIndexes = <String, int>{};
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (message.messageId != null) {
        serverIndexes[message.messageId!] = index;
      }
      final clientId = message.clientMessageId;
      if (clientId != null && clientId.isNotEmpty) {
        clientIndexes[clientId] = index;
      }
    }

    var didChange = false;
    for (final message in incoming) {
      int? index;
      final clientId = message.clientMessageId;
      if (clientId != null && clientId.isNotEmpty) {
        index = clientIndexes[clientId];
      }
      index ??=
          message.messageId == null ? null : serverIndexes[message.messageId!];

      if (index == null) {
        _messages.add(message);
        didChange = true;
        final newIndex = _messages.length - 1;
        if (message.messageId != null) {
          serverIndexes[message.messageId!] = newIndex;
        }
        if (clientId != null && clientId.isNotEmpty) {
          clientIndexes[clientId] = newIndex;
        }
      } else {
        final existing = _messages[index];
        final replacement = message.copyWith(
          clientMessageId: message.clientMessageId ?? existing.clientMessageId,
          createdAt: message.createdAt ?? existing.createdAt,
        );
        if (replacement != existing) {
          _messages[index] = replacement;
          didChange = true;
        }
        if (message.messageId != null) {
          serverIndexes[message.messageId!] = index;
        }
      }
    }
    if (didChange) {
      _sortAndRecalculateLatest();
    }
  }

  void _setLocalMessageStatus(
    String clientMessageId,
    ChatMessageLocalStatus status,
  ) {
    final index = _messages.indexWhere(
      (message) => message.clientMessageId == clientMessageId,
    );
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(localStatus: status);
    }
  }

  void _sortAndRecalculateLatest() {
    _messages.sort((first, second) {
      if (first.messageId != null && second.messageId != null) {
        return first.messageId!.compareTo(second.messageId!);
      }
      final firstTime = first.createdAt;
      final secondTime = second.createdAt;
      if (firstTime != null && secondTime != null) {
        final byTime = firstTime.compareTo(secondTime);
        if (byTime != 0) {
          return byTime;
        }
      }
      if (first.messageId == null && second.messageId != null) {
        return 1;
      }
      if (first.messageId != null && second.messageId == null) {
        return -1;
      }
      return 0;
    });
    _latestMessageId = _messages.fold<int>(
      0,
      (latest, message) =>
          message.messageId != null && message.messageId! > latest
              ? message.messageId!
              : latest,
    );
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  static bool _isCancelled(Object error) {
    return error is ChatNetworkException && error.code == 'REQUEST_CANCELLED';
  }

  static String _safeMessage(Object error) {
    return error is ChatException ? error.safeMessage : 'chat_unknown_error';
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    _loadToken?.cancel('chat conversation provider disposed');
    _sendToken?.cancel('chat conversation provider disposed');
    _readToken?.cancel('chat conversation provider disposed');
    super.dispose();
  }
}
