import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class DriverRatingDisplay extends StatelessWidget {
  const DriverRatingDisplay({
    super.key,
    required this.rating,
    this.compact = false,
  });

  final int rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffDCE8F6)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: const Color(0xffFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xffF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl
                      ? '\u062a\u0642\u064a\u064a\u0645\u0643 \u0644\u0644\u0633\u0627\u0626\u0642'
                      : 'Your driver rating',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2,
                  runSpacing: 4,
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xffF59E0B),
                        size: compact ? 17 : 19,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRtl
                          ? '\u062a\u0642\u064a\u064a\u0645\u0643: $rating \u0645\u0646 5'
                          : 'Your rating: $rating of 5',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
