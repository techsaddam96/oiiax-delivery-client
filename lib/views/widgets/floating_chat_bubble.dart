import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/chat/chat_conversations_provider.dart';
import 'package:blockatie/provider/chat/chat_launcher_provider.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/chat/conversations_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A single app-shell chat launcher. It is rendered by [MaterialApp.builder],
/// so individual pages never create their own floating chat button.
class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({super.key});

  /// Vertical space this launcher occupies above the bottom safe-area inset.
  ///
  /// Exposed so a screen that scrolls its own content can pad by it rather
  /// than copying the numbers below.
  static const double reservedBottomSpace =
      _FloatingChatBubbleState._bottomNavigationClearance +
          _FloatingChatBubbleState._bubbleDiameter;

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble> {
  /// Matches the Driver app: the two launchers are the same component.
  static const double _bubbleDiameter = 56;
  static const double _horizontalInset = 16;

  /// Clears the floating bottom-nav pill: its row, the brand strip and the
  /// card's own margins.
  static const double _bottomNavigationClearance = 118;

  bool _isOpeningConversations = false;

  Future<void> _openConversations() async {
    if (_isOpeningConversations) {
      return;
    }
    final navigator = Nav.key.currentState;
    if (navigator == null) {
      return;
    }
    _isOpeningConversations = true;
    context.read<ChatLauncherProvider>().setChatRouteOpen(true);
    setState(() => _isOpeningConversations = true);
    try {
      await navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const ConversationsPage()),
      );
      if (mounted) {
        await context.read<ChatConversationsProvider>().refreshUnreadCount();
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningConversations = false);
        context.read<ChatLauncherProvider>().setChatRouteOpen(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ChatLauncherProvider, bool>(
      selector: (_, provider) => provider.shouldShow,
      builder: (context, shouldShow, _) {
        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        return Selector<ChatConversationsProvider, int>(
          selector: (_, provider) => provider.unreadCount,
          builder: (context, unreadCount, _) {
            // The keyboard takes the space the launcher sits in, and covering
            // an input while someone types is worse than hiding it.
            if (MediaQuery.viewInsetsOf(context).bottom > 0) {
              return const SizedBox.shrink();
            }

            return PositionedDirectional(
              // Directional, so the launcher sits on the natural trailing side
              // in both layouts. This was a hardcoded `left`, which put it on
              // the leading edge in English and disagreed with the Driver app.
              end: _horizontalInset,
              bottom: _bottomNavigationClearance +
                  MediaQuery.paddingOf(context).bottom,
              child: _ChatBubbleVisual(
                unreadCount: unreadCount < 0 ? 0 : unreadCount,
                isOpening: _isOpeningConversations,
                onTap: _openConversations,
                diameter: _bubbleDiameter,
              ),
            );
          },
        );
      },
    );
  }
}

/// The launcher's appearance: one compact rounded-square brand control with
/// an optional unread badge.
///
/// Two one-shot animations, both quiet: the badge pops when the count rises,
/// and the whole control dips while pressed. Nothing animates on a loop —
/// this used to drift up and down forever, which rebuilt the launcher every
/// frame for the life of the app and drew the eye with nothing to report.
class _ChatBubbleVisual extends StatefulWidget {
  const _ChatBubbleVisual({
    required this.unreadCount,
    required this.isOpening,
    required this.onTap,
    required this.diameter,
  });

  final int unreadCount;
  final bool isOpening;
  final VoidCallback onTap;
  final double diameter;

  @override
  State<_ChatBubbleVisual> createState() => _ChatBubbleVisualState();
}

/// Unicode LEFT-TO-RIGHT ISOLATE / POP DIRECTIONAL ISOLATE. They fence a run
/// of digits so the surrounding Arabic cannot reorder it.
const String _lri = '\u2066';
const String _pdi = '\u2069';

class _ChatBubbleVisualState extends State<_ChatBubbleVisual>
    with SingleTickerProviderStateMixin {
  static const Duration _badgePopDuration = Duration(milliseconds: 260);
  static const Duration _pressDuration = Duration(milliseconds: 110);
  static const double _cornerRadius = 18;

  late final AnimationController _badgePop;
  late final Animation<double> _badgeScale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _badgePop = AnimationController(vsync: this, duration: _badgePopDuration)
      // Rests at the end of the sequence, so a badge that is simply present
      // sits at its natural size instead of the 0.85 the sequence starts on.
      ..value = 1;
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _badgePop, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _ChatBubbleVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a rise is worth announcing. Reading messages lowers the count, and
    // animating that would draw the eye to something already handled.
    if (widget.unreadCount > oldWidget.unreadCount && widget.unreadCount > 0) {
      _badgePop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _badgePop.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    // The locale MaterialApp resolved, which is also what Directionality is
    // built from. A separate static locale can disagree with it for a frame
    // after a language switch.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // The count is isolated in the Arabic label because an unisolated number
    // sitting between Arabic words can be reordered against them. Written as
    // escapes so the source stays readable and the analyzer stays quiet.
    final isolatedCount = '$_lri${widget.unreadCount}$_pdi';
    final label = hasUnread
        ? (isArabic
            ? 'فتح الرسائل، $isolatedCount رسائل غير مقروءة'
            : 'Open messages, ${widget.unreadCount} unread messages')
        : (isArabic ? 'فتح الرسائل' : 'Open messages');

    return Semantics(
      button: true,
      enabled: !widget.isOpening,
      label: label,
      tooltip: label,
      child: AnimatedScale(
        // Purely visual: it never sits between the pointer and the InkWell,
        // so the tap is delivered at once.
        scale: _isPressed ? 0.95 : 1,
        duration: _pressDuration,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isOpening ? null : widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: Ink(
              key: const ValueKey<String>('client-chat-launcher-surface'),
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_cornerRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradient1, AppColors.primary],
                ),
                // One neutral shadow gives the control separation without a
                // coloured halo that can read as a second circular button.
                boxShadow: _elevation,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (widget.isOpening)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  if (!widget.isOpening && hasUnread)
                    PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: ScaleTransition(
                        scale: _badgeScale,
                        child: _UnreadBadge(count: widget.unreadCount),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const List<BoxShadow> _elevation = [
    BoxShadow(
      color: Color(0x260F172A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xffE53935),
        borderRadius: BorderRadius.circular(10),
        // Separates the badge from the brand gradient underneath it.
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      // The count is already spoken in the button label; the bare digits
      // would merge into it and say it twice.
      child: ExcludeSemantics(
        child: Text(
          label,
          // Digits read left-to-right even in Arabic, so `99+` never becomes
          // `+99`.
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
