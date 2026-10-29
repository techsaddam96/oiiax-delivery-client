import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/chat/chat_message.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final locale = Localizations.localeOf(context);
    final time = ChatMessageDateFormatter.formatTime(message.createdAt, locale);
    final readTime = ChatMessageDateFormatter.formatTime(message.readAt, locale);
    final status = message.localStatus;

    return Semantics(
      label: isMine
          ? AppTranslations.getText('chat_my_message')
          : message.senderName.trim().isEmpty
              ? AppTranslations.getText('chat_support_message')
              : message.senderName,
      child: Align(
        alignment: isMine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 7),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : const Color(0xffEAF0F7),
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(16),
                topEnd: const Radius.circular(16),
                bottomStart: Radius.circular(isMine ? 16 : 4),
                bottomEnd: Radius.circular(isMine ? 4 : 16),
              ),
              border:
                  isMine ? null : Border.all(color: const Color(0xffDCE5F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine && message.senderName.trim().isNotEmpty) ...[
                  Text(
                    message.senderName.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff33506F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message.message,
                  style: TextStyle(
                    color: isMine ? Colors.white : const Color(0xff1C3048),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (time.isNotEmpty)
                      Text(
                        time,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.78)
                              : const Color(0xff718096),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (isMine && status == ChatMessageLocalStatus.sending) ...[
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.7,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    if (isMine && status == ChatMessageLocalStatus.sent) ...[
                      const SizedBox(width: 5),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.check_rounded,
                        size: 13,
                        color: message.isRead
                            ? const Color(0xffB8F2DF)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ],
                ),
                if (isMine &&
                    status == ChatMessageLocalStatus.sent &&
                    message.isRead) ...[
                  const SizedBox(height: 2),
                  Text(
                    readTime.isEmpty
                        ? AppTranslations.getText('chat_read')
                        : '${AppTranslations.getText('chat_read_at')} $readTime',
                    textDirection: Directionality.of(context),
                    style: const TextStyle(
                      color: Color(0xffB8F2DF),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (isMine && status == ChatMessageLocalStatus.failed) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xffFEE2E2), size: 14),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(44, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppTranslations.getText('chat_retry'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.value});

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Semantics(
      label: ChatMessageDateFormatter.formatDay(value, locale),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xffE7EDF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ChatMessageDateFormatter.formatDay(value, locale),
            style: const TextStyle(
              color: Color(0xff5E7188),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessageDateFormatter {
  ChatMessageDateFormatter._();

  static final Map<String, DateFormat> _timeFormats = <String, DateFormat>{};
  static final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};

  static String formatTime(DateTime? value, Locale locale) {
    if (value == null) return '';
    final localeName = locale.toLanguageTag();
    return _timeFormats
        .putIfAbsent(localeName, () => DateFormat.jm(localeName))
        .format(JordanTime.toJordan(value));
  }

  static String formatDay(DateTime value, Locale locale) {
    final localValue = JordanTime.toJordan(value);
    final now = JordanTime.now();
    if (DateUtils.isSameDay(localValue, now)) {
      return AppTranslations.getText('chat_today');
    }
    if (DateUtils.isSameDay(
      localValue,
      now.subtract(const Duration(days: 1)),
    )) {
      return AppTranslations.getText('chat_yesterday');
    }
    final localeName = locale.toLanguageTag();
    return _dateFormats
        .putIfAbsent(localeName, () => DateFormat('d MMMM y', localeName))
        .format(localValue);
  }

  static bool isDifferentDay(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first != second;
    return !DateUtils.isSameDay(
      JordanTime.toJordan(first),
      JordanTime.toJordan(second),
    );
  }
}
