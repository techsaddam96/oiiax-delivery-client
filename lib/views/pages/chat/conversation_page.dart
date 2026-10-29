import 'dart:async';
import 'package:blockatie/services/user_session_state.dart';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/provider/chat/chat_conversation_provider.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/services/chat_service.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/chat/widgets/chat_message_bubble.dart';
import 'package:blockatie/views/pages/chat/widgets/chat_page_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.title,
    this.shipmentId,
    this.policyNum,
    this.repository,
  });

  final int conversationId;
  final String title;
  final int? shipmentId;
  final String? policyNum;
  @visibleForTesting
  final ChatRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatConversationProvider>(
      create: (_) => ChatConversationProvider(
        conversationId: conversationId,
        repository: repository ?? ChatService(),
      ),
      child: _ConversationView(title: title, policyNum: policyNum),
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({required this.title, this.policyNum});

  final String title;
  final String? policyNum;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView>
    with WidgetsBindingObserver {
  static const _olderMessagesThreshold = 220.0;
  static const _bottomThreshold = 160.0;
  static const _pollingInterval = Duration(seconds: 5);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final int _accountGeneration = UserSessionState.generation;
  bool get _active =>
      mounted && _accountGeneration == UserSessionState.generation;
  void _resetConversation() {
    _stopPolling();
    _messageController.clear();
    _hasUnreadNewMessages = false;
  }

  Timer? _pollingTimer;
  bool _pollInFlight = false;
  bool _hasUnreadNewMessages = false;
  bool _initialScrollCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserSessionState.register(_resetConversation);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_active) unawaited(_loadInitial());
    });
  }

  Future<void> _loadInitial() async {
    if (!_active) return;
    final provider = context.read<ChatConversationProvider>();
    await provider.loadInitial();
    if (!_active || provider.state == ChatConversationState.error) return;
    await _scrollToEnd(jump: true);
    _initialScrollCompleted = true;
    unawaited(_markVisibleMessagesRead());
    _startPolling();
  }

  void _onScroll() {
    if (!_active) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= _olderMessagesThreshold) {
      unawaited(_loadOlderKeepingPosition());
    }
  }

  Future<void> _loadOlderKeepingPosition() async {
    final provider = context.read<ChatConversationProvider>();
    if (!provider.hasOlder || provider.isLoading || provider.isLoadingOlder) {
      return;
    }

    final position = _scrollController.position;
    final previousPixels = position.pixels;
    final previousMaxExtent = position.maxScrollExtent;
    await provider.loadOlder();
    if (!_active || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active || !_scrollController.hasClients) return;
      final currentPosition = _scrollController.position;
      final extentDifference =
          currentPosition.maxScrollExtent - previousMaxExtent;
      final target = (previousPixels + extentDifference).clamp(
        currentPosition.minScrollExtent,
        currentPosition.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.extentAfter < _bottomThreshold;
  }

  Future<void> _scrollToEnd({bool jump = false}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (jump) {
        _scrollController.jumpTo(position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) {
      _showMessage(AppTranslations.getText('chat_message_required'));
      return;
    }

    final provider = context.read<ChatConversationProvider>();
    final conversationsProvider = context.read<ChatConversationsProvider>();
    if (provider.isSending) return;
    _messageController.clear();
    final success = await provider.sendMessage(text);
    if (!_active) return;
    await _scrollToEnd();
    if (success && provider.messages.isNotEmpty) {
      conversationsProvider.applyLatestMessage(provider.messages.last);
    } else if (!success) {
      _showMessage(_chatErrorText(provider.errorMessage));
    }
  }

  Future<void> _retryMessage(String clientMessageId) async {
    final provider = context.read<ChatConversationProvider>();
    final conversationsProvider = context.read<ChatConversationsProvider>();
    final success = await provider.retryFailed(clientMessageId);
    if (!_active) return;
    await _scrollToEnd();
    if (success && provider.messages.isNotEmpty) {
      conversationsProvider.applyLatestMessage(provider.messages.last);
    } else if (!success) {
      _showMessage(_chatErrorText(provider.errorMessage));
    }
  }

  Future<void> _markVisibleMessagesRead() async {
    final provider = context.read<ChatConversationProvider>();
    final didMarkRead = await provider.markRead();
    if (didMarkRead && mounted && _active) {
      context
          .read<ChatConversationsProvider>()
          .updateConversationUnread(provider.conversationId, 0);
    }
  }

  void _startPolling({bool refreshNow = false}) {
    if (!_active || _pollingTimer != null) return;
    if (refreshNow) unawaited(_pollForMessages());
    _pollingTimer = Timer.periodic(
      _pollingInterval,
      (_) => unawaited(_pollForMessages()),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollForMessages() async {
    if (!_active || _pollInFlight) return;
    final provider = context.read<ChatConversationProvider>();
    if (provider.isLoading ||
        provider.isLoadingOlder ||
        provider.isLoadingNewer) {
      return;
    }

    _pollInFlight = true;
    try {
      final knownKeys =
          provider.messages.map((message) => message.identityKey).toSet();
      var pages = 0;
      do {
        await provider.fetchNewMessages();
        if (!_active) return;
        pages++;
      } while (_active && provider.hasMoreNewer && pages < 3);

      if (!_active) return;
      await provider.refreshReadReceipts();

      if (!mounted || !_active) return;
      final received = provider.messages
          .where((message) => !knownKeys.contains(message.identityKey))
          .toList(growable: false);
      if (received.isEmpty) return;

      final conversationsProvider = context.read<ChatConversationsProvider>();
      for (final message in received) {
        conversationsProvider.applyLatestMessage(message);
      }
      unawaited(_markVisibleMessagesRead());
      if (_isNearBottom) {
        await _scrollToEnd();
      } else if (_active) {
        setState(() => _hasUnreadNewMessages = true);
      }
    } finally {
      _pollInFlight = false;
    }
  }

  void _showMessage(String value) {
    if (!_active || value.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _chatErrorText(String? key) {
    if (key == 'chat_rate_limited') {
      return AppTranslations.getText('chat_rate_limited');
    }
    if (key == 'chat_access_denied') {
      return AppTranslations.getText('chat_access_denied');
    }
    if (key == 'chat_authentication_required') {
      return AppTranslations.getText('chat_session_expired');
    }
    return AppTranslations.getText('chat_message_failed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startPolling(refreshNow: _initialScrollCompleted);
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopPolling();
    }
  }

  @override
  void dispose() {
    UserSessionState.unregister(_resetConversation);
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policyNum?.trim() ?? '';
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        body: Column(
          children: [
            ChatPageHeader(
              title: widget.title.isEmpty
                  ? AppTranslations.getText('conversations')
                  : widget.title,
              subtitle: policy.isEmpty
                  ? AppTranslations.getText('hub_conversations_subtitle')
                  : '${AppTranslations.getText('chat_shipment_number')} #$policy',
              icon: Icons.chat_bubble_outline_rounded,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Consumer<ChatConversationProvider>(
                      builder: (context, provider, _) =>
                          _buildMessages(provider),
                    ),
                  ),
                  _MessageComposer(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    isSending: context.select<ChatConversationProvider, bool>(
                      (provider) => provider.isSending,
                    ),
                    onSend: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatConversationProvider provider) {
    if (provider.isLoading || provider.state == ChatConversationState.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.state == ChatConversationState.error &&
        provider.messages.isEmpty) {
      return _MessageLoadError(
        message: _chatErrorText(provider.errorMessage),
        onRetry: _loadInitial,
      );
    }

    if (provider.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            AppTranslations.getText('chat_start_support_conversation'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff5D718B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
          itemCount:
              provider.messages.length + (provider.isLoadingOlder ? 1 : 0),
          itemBuilder: (context, index) {
            if (provider.isLoadingOlder && index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final messageIndex = index - (provider.isLoadingOlder ? 1 : 0);
            final message = provider.messages[messageIndex];
            final previous =
                messageIndex > 0 ? provider.messages[messageIndex - 1] : null;
            return KeyedSubtree(
              key: ValueKey(message.identityKey),
              child: Column(
                children: [
                  if (previous == null ||
                      ChatMessageDateFormatter.isDifferentDay(
                        previous.createdAt,
                        message.createdAt,
                      ))
                    if (message.createdAt != null)
                      ChatDateSeparator(value: message.createdAt!),
                  ChatMessageBubble(
                    message: message,
                    onRetry:
                        message.localStatus == ChatMessageLocalStatus.failed &&
                                message.clientMessageId != null
                            ? () => _retryMessage(message.clientMessageId!)
                            : null,
                  ),
                ],
              ),
            );
          },
        ),
        if (_hasUnreadNewMessages)
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: () {
                setState(() => _hasUnreadNewMessages = false);
                unawaited(_scrollToEnd());
              },
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              label: Text(AppTranslations.getText('chat_new_messages')),
            ),
          ),
      ],
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x190F172A),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isSending) onSend();
                  },
                  decoration: InputDecoration(
                    hintText: AppTranslations.getText('chat_type_message'),
                    filled: true,
                    fillColor: const Color(0xffF1F5F9),
                    contentPadding:
                        const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: AppTranslations.getText('chat_send'),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton(
                    onPressed: isSending ? null : onSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageLoadError extends StatelessWidget {
  const _MessageLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: Color(0xff64748B)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppTranslations.getText('try_again')),
            ),
          ],
        ),
      ),
    );
  }
}
