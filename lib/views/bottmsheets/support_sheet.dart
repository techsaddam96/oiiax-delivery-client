import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/hub/support&assistance/support_assistence.dart';
import 'package:flutter/material.dart';

class SupportBottomSheet extends StatelessWidget {
  const SupportBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) => const SupportBottomSheet(),
    );
  }

  bool get _isArabic => AppLocalizations.isRTL;

  String _text(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xffF4F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xffCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('الدعم والمساعدة', 'Support & Help'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _text(
                            'نحن هنا لمساعدة متجرك في أي وقت',
                            'We are here to help your store anytime',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                child: SupportAssistancePage(showAppBar: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
