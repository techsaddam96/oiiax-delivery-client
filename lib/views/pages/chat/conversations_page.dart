import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/chat/conversation_page.dart';
import 'package:blockatie/views/pages/chat/conversation_tile.dart';
import 'package:blockatie/views/pages/chat/widgets/chat_page_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  static const _paginationThreshold = 260.0;
  final ScrollController _scrollController = ScrollController();
  ChatLauncherProvider? _launcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _launcher ??= context.read<ChatLauncherProvider>()..setChatRouteOpen(true);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ChatConversationsProvider>();
      if (provider.state == ChatConversationsState.initial) {
        provider.loadInitial();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _paginationThreshold) {
      return;
    }
    context.read<ChatConversationsProvider>().loadMore();
  }

  @override
  void dispose() {
    _launcher?.setChatRouteOpen(false);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _openConversation(int index) async {
    final provider = context.read<ChatConversationsProvider>();
    if (index >= provider.conversations.length) return;
    final conversation = provider.conversations[index];
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConversationPage(
          conversationId: conversation.conversationId,
          title: conversation.title,
          shipmentId: conversation.shipmentId,
          policyNum: conversation.policyNum,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: Column(
        children: [
          ChatPageHeader(
            title: AppTranslations.getText('conversations'),
            subtitle: AppTranslations.getText('hub_conversations_subtitle'),
            onBack: Nav.back,
          ),
          Expanded(
            child: Consumer<ChatConversationsProvider>(
              builder: (context, provider, _) {
                if (provider.state == ChatConversationsState.initial ||
                    provider.isLoading) {
                  return const _ConversationListSkeleton();
                }

                if (provider.state == ChatConversationsState.error &&
                    provider.conversations.isEmpty) {
                  return _ConversationErrorState(
                    isSessionError:
                        provider.errorMessage == 'chat_authentication_required',
                    onRetry: provider.loadInitial,
                  );
                }

                if (provider.conversations.isEmpty) {
                  return _ConversationEmptyState(onRefresh: provider.refresh);
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 116),
                    itemCount: provider.conversations.length +
                        (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.conversations.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ChatConversationTile(
                          conversation: provider.conversations[index],
                          onTap: () => _openConversation(index),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationListSkeleton extends StatelessWidget {
  const _ConversationListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 116),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE7EDF5)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              _SkeletonBox(width: 46, height: 46, radius: 15),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 130, height: 12, radius: 6),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 190, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffEAF0F7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.forum_outlined, size: 54, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getText('chat_no_conversations'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff152A46),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getText('chat_no_conversations_description'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff6D7E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationErrorState extends StatelessWidget {
  const _ConversationErrorState({
    required this.isSessionError,
    required this.onRetry,
  });

  final bool isSessionError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final title = AppTranslations.getText(
      isSessionError
          ? 'chat_session_expired'
          : 'chat_unable_load_conversations',
    );
    final description = AppTranslations.getText(
      isSessionError
          ? 'chat_session_expired_description'
          : 'chat_unable_load_conversations_description',
    );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 36, 20, 116),
        children: [
          const SizedBox(height: 84),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffE1EAF4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F153B6A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xffEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSessionError
                        ? Icons.lock_outline_rounded
                        : Icons.forum_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff173451),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff718399),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    label: Text(AppTranslations.getText('try_again')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
