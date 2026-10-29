import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shared app-style header for the conversations list and chat details.
class ChatPageHeader extends StatelessWidget {
  const ChatPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.icon = Icons.forum_rounded,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final backIcon =
        isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded;

    return Container(
      color: const Color(0xffF6F8FC),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0F172A).withValues(alpha: .055),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: const Color(0xffEEF5FF),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          backIcon,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeaderIcon(
                    icon: icon,
                    color: const Color(0xffEAF2FF),
                    iconColor: AppColors.primary,
                    tooltip: title,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xffD8E7FB)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 23),
      ),
    );
  }
}
