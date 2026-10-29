import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onBack,
    this.title,
    this.subtitle,
    this.onHelp,
    this.bgColor,
    this.titleColor,
    this.subtileColor,
    this.showBtn = true,
    this.subtitleFont,
  });

  final VoidCallback? onBack;
  final String? title;
  final String? subtitle;
  final VoidCallback? onHelp;
  final Color? bgColor;
  final Color? titleColor;
  final Color? subtileColor;
  final bool? showBtn;
  final double? subtitleFont;

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRtl = AppLocalizations.isRTL;
    final leadingIcon =
        isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded;

    return Container(
      color: const Color(0xffF6F8FC),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0F172A).withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showBtn ?? true)
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onHelp ??
                              () {
                                Nav.to(
                                  const SupportAssistancePage(),
                                  withNav: true,
                                  navIndex: 4,
                                );
                              },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffEEF5FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppTranslations.getText('help'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (showBtn ?? true) const SizedBox(width: 8),
                      Material(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onBack ?? () => Nav.back(),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              leadingIcon,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? AppTranslations.getText('order_details'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: textTheme.titleLarge!.copyWith(
                            color: titleColor ?? const Color(0xff0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle ?? AppTranslations.getText('placed_on_date'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: textTheme.bodySmall!.copyWith(
                            color: subtileColor ?? const Color(0xff64748B),
                            fontSize: subtitleFont ?? 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
