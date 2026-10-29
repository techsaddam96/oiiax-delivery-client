import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/chat/chat_conversation.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final unread = conversation.unreadCount > 0;
    final lastMessage = conversation.lastMessage.trim();
    final shipmentNumber = conversation.policyNum?.trim();
    final time = ChatConversationTimeFormatter.format(
      conversation.lastMessageAt,
      locale,
      yesterdayLabel: AppTranslations.getText('chat_yesterday'),
    );

    return Semantics(
      button: true,
      label: unread
          ? '${conversation.title}, ${AppTranslations.getText('chat_unread_message')}'
          : conversation.title,
      child: Material(
        color: unread ? const Color(0xffF0F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    unread ? const Color(0xffB9D7FF) : const Color(0xffE4EAF3),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _ConversationAvatar(
                  title: conversation.title,
                  unread: unread,
                  isShipment: conversation.shipmentId != null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title.isEmpty
                                  ? AppTranslations.getText('conversations')
                                  : conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xff10233F),
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              time,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: unread
                                    ? AppColors.primary
                                    : const Color(0xff7B8798),
                                fontSize: 11,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (shipmentNumber != null && shipmentNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              8,
                              4,
                              8,
                              4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffEAF3FF),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${AppTranslations.getText('chat_shipment_number')}: $shipmentNumber',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff31639C),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage.isEmpty
                            ? AppTranslations.getText('chat_start_conversation')
                            : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread
                              ? const Color(0xff263B57)
                              : const Color(0xff718096),
                          fontSize: 12,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  _UnreadBadge(count: conversation.unreadCount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.title,
    required this.unread,
    required this.isShipment,
  });

  final String title;
  final bool unread;
  final bool isShipment;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? '?' : title.trim().characters.first;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: unread ? const Color(0xffDDEBFF) : const Color(0xffEEF3FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: isShipment
          ? Icon(
              Icons.local_shipping_outlined,
              color: unread ? const Color(0xff0756B4) : const Color(0xff63748A),
              size: 22,
            )
          : Text(
              initial.toUpperCase(),
              style: TextStyle(
                color:
                    unread ? const Color(0xff0756B4) : const Color(0xff63748A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: '$label ${AppTranslations.getText('chat_unread_messages')}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ChatConversationTimeFormatter {
  ChatConversationTimeFormatter._();

  static final Map<String, DateFormat> _timeFormats = <String, DateFormat>{};
  static final Map<String, DateFormat> _dayFormats = <String, DateFormat>{};
  static final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};

  static String format(
    DateTime? value,
    Locale locale, {
    required String yesterdayLabel,
  }) {
    if (value == null) return '';

    final localValue = JordanTime.toJordan(value);
    final now = JordanTime.now();
    final localeName = locale.toLanguageTag();
    if (DateUtils.isSameDay(localValue, now)) {
      return _timeFormats
          .putIfAbsent(localeName, () => DateFormat.jm(localeName))
          .format(localValue);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(localValue, yesterday)) return yesterdayLabel;

    if (now.difference(localValue).inDays < 7) {
      return _dayFormats
          .putIfAbsent(localeName, () => DateFormat.E(localeName))
          .format(localValue);
    }

    return _dateFormats
        .putIfAbsent(localeName, () => DateFormat('d/M/y', localeName))
        .format(localValue);
  }
}
