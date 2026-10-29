import 'package:blockatie/services/user_session_state.dart';
import 'dart:collection';

import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/models/chat/chat_exception.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:dio/dio.dart';

enum ChatConversationsState {
  initial,
  loading,
  loaded,
  refreshing,
  loadingMore,
  empty,
  error,
}

class ChatConversationsProvider extends UserScopedNotifier {
  ChatConversationsProvider({
    required ChatRepository repository,
    this.pageSize = 20,
  }) : _repository = repository;

  final ChatRepository _repository;
  final int pageSize;

  final List<ChatConversation> _conversations = <ChatConversation>[];
  ChatConversationsState _state = ChatConversationsState.initial;
  DateTime? _nextCursorLastMessageAt;
  int? _nextCursorId;
  bool _hasMore = true;
  int _unreadCount = 0;
  String? _errorMessage;
  DateTime? _lastLoadedAt;
  CancelToken? _requestToken;
  CancelToken? _unreadToken;
  int _requestGeneration = 0;
  bool _unreadRequestInFlight = false;
  bool _disposed = false;

  UnmodifiableListView<ChatConversation> get conversations =>
      UnmodifiableListView(_conversations);
  ChatConversationsState get state => _state;
  bool get hasMore => _hasMore;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  DateTime? get lastLoadedAt => _lastLoadedAt;
  bool get isLoading => _state == ChatConversationsState.loading;
  bool get isRefreshing => _state == ChatConversationsState.refreshing;
  bool get isLoadingMore => _state == ChatConversationsState.loadingMore;

  Future<void> loadInitial() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading || isRefreshing || _conversations.isNotEmpty) {
        return;
      }
      final generation = ++_requestGeneration;
      final token = CancelToken();
      _requestToken = token;
      _state = ChatConversationsState.loading;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.listConversations(
              limit: pageSize,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _replaceWithPage(page.conversations);
        _hasMore = page.hasMore;
        _nextCursorLastMessageAt = page.nextCursorLastMessageAt;
        _nextCursorId = page.nextCursorId;
        _lastLoadedAt = DateTime.now();
        _state = _conversations.isEmpty
            ? ChatConversationsState.empty
            : ChatConversationsState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = ChatConversationsState.error;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _requestToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> refresh() async {
    final sessionGeneration = stateGeneration;
    try {
      _requestToken?.cancel('chat conversations refreshed');
      final generation = ++_requestGeneration;
      final token = CancelToken();
      _requestToken = token;
      _state = ChatConversationsState.refreshing;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.listConversations(
              limit: pageSize,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _replaceWithPage(page.conversations);
        _hasMore = page.hasMore;
        _nextCursorLastMessageAt = page.nextCursorLastMessageAt;
        _nextCursorId = page.nextCursorId;
        _lastLoadedAt = DateTime.now();
        _state = _conversations.isEmpty
            ? ChatConversationsState.empty
            : ChatConversationsState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = _conversations.isEmpty
            ? ChatConversationsState.error
            : ChatConversationsState.loaded;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _requestToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> loadMore() async {
    final sessionGeneration = stateGeneration;
    try {
      if (!_hasMore ||
          isLoading ||
          isRefreshing ||
          isLoadingMore ||
          _nextCursorLastMessageAt == null ||
          _nextCursorId == null) {
        return;
      }
      final generation = ++_requestGeneration;
      final token = CancelToken();
      _requestToken = token;
      _state = ChatConversationsState.loadingMore;
      _errorMessage = null;
      _notify();

      try {
        final page = await guardSession(
            _repository.listConversations(
              limit: pageSize,
              cursorLastMessageAt: _nextCursorLastMessageAt,
              cursorId: _nextCursorId,
              cancelToken: token,
            ),
            sessionGeneration);
        if (!_isCurrent(generation)) {
          return;
        }
        _mergeConversations(page.conversations);
        _hasMore = page.hasMore;
        _nextCursorLastMessageAt = page.nextCursorLastMessageAt;
        _nextCursorId = page.nextCursorId;
        _lastLoadedAt = DateTime.now();
        _state = _conversations.isEmpty
            ? ChatConversationsState.empty
            : ChatConversationsState.loaded;
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCurrent(generation) || _isCancelled(error)) {
          return;
        }
        _errorMessage = _safeMessage(error);
        _state = _conversations.isEmpty
            ? ChatConversationsState.error
            : ChatConversationsState.loaded;
      } finally {
        if (acceptsState(sessionGeneration)) {
          if (_isCurrent(generation)) {
            _requestToken = null;
            _notify();
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> refreshUnreadCount() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_unreadRequestInFlight) {
        return;
      }
      _unreadRequestInFlight = true;
      final token = CancelToken();
      _unreadToken = token;
      try {
        final count = await guardSession(
            _repository.getUnreadCount(cancelToken: token), sessionGeneration);
        if (_disposed || token.isCancelled) {
          return;
        }
        _unreadCount = count < 0 ? 0 : count;
        _notify();
      } catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        if (!_isCancelled(error)) {
          _errorMessage = _safeMessage(error);
          _notify();
        }
      } finally {
        if (acceptsState(sessionGeneration)) {
          _unreadRequestInFlight = false;
          if (identical(_unreadToken, token)) {
            _unreadToken = null;
          }
        }
      }
    } on SessionChanged {
      return;
    }
  }

  /// Clears client-specific chat state when its session is no longer valid.
  void reset() => resetUserState();

  @override
  void clearUserState() {
    _requestGeneration++;
    _requestToken?.cancel('chat session cleared');
    _unreadToken?.cancel('chat session cleared');
    _requestToken = null;
    _unreadToken = null;
    _unreadRequestInFlight = false;
    _conversations.clear();
    _state = ChatConversationsState.initial;
    _nextCursorLastMessageAt = null;
    _nextCursorId = null;
    _hasMore = true;
    _unreadCount = 0;
    _errorMessage = null;
    _lastLoadedAt = null;
  }

  void applyLatestMessage(ChatMessage message) {
    final index = _conversations.indexWhere(
      (conversation) => conversation.conversationId == message.conversationId,
    );
    if (index < 0) {
      return;
    }
    final current = _conversations.removeAt(index);
    final updated = current.copyWith(
      lastMessage: message.message,
      lastMessageType: message.messageType,
      lastMessageAt: message.createdAt ?? DateTime.now(),
      unreadCount:
          message.isMine ? current.unreadCount : current.unreadCount + 1,
    );
    _conversations.insert(0, updated);
    if (!message.isMine) {
      _unreadCount++;
    }
    _notify();
  }

  void updateConversationUnread(int conversationId, int unreadCount) {
    final index = _conversations.indexWhere(
      (conversation) => conversation.conversationId == conversationId,
    );
    if (index < 0) {
      return;
    }
    final current = _conversations[index];
    final normalized = unreadCount < 0 ? 0 : unreadCount;
    final difference = normalized - current.unreadCount;
    _conversations[index] = current.copyWith(unreadCount: normalized);
    _unreadCount = (_unreadCount + difference).clamp(0, 1 << 31).toInt();
    _notify();
  }

  void upsertConversation(ChatConversation conversation) {
    final index = _conversations.indexWhere(
      (item) => item.conversationId == conversation.conversationId,
    );
    if (index >= 0) {
      _conversations.removeAt(index);
    }
    _conversations.insert(0, conversation);
    if (_state == ChatConversationsState.initial ||
        _state == ChatConversationsState.empty) {
      _state = ChatConversationsState.loaded;
    }
    _notify();
  }

  void _replaceWithPage(List<ChatConversation> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
  }

  void _mergeConversations(List<ChatConversation> incoming) {
    final knownIds = _conversations
        .map((conversation) => conversation.conversationId)
        .toSet();
    for (final conversation in incoming) {
      if (knownIds.add(conversation.conversationId)) {
        _conversations.add(conversation);
      }
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _requestGeneration;

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
    _requestGeneration++;
    _requestToken?.cancel('chat conversations provider disposed');
    _unreadToken?.cancel('chat conversations provider disposed');
    super.dispose();
  }
}
