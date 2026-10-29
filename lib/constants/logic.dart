import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';

class Logic {
  static String timeAgo(String createdAt, {String lang = "en"}) {
    final created = JordanTime.parse(
      createdAt,
      assumeUtcWithoutTimezone: true,
    );

    if (created == null) {
      return createdAt;
    }

    var diff = JordanTime.now().difference(created);
    if (diff.isNegative) {
      diff = Duration.zero;
    }

    if (lang == "ar") {
      if (diff.inSeconds < 60) {
        return "\u0627\u0644\u0622\u0646";
      }
      if (diff.inMinutes < 60) {
        return diff.inMinutes == 1
            ? "\u0645\u0646\u0630 \u062f\u0642\u064a\u0642\u0629"
            : "\u0645\u0646\u0630 ${diff.inMinutes} \u062f\u0642\u064a\u0642\u0629";
      }
      if (diff.inHours < 24) {
        return diff.inHours == 1
            ? "\u0645\u0646\u0630 \u0633\u0627\u0639\u0629"
            : "\u0645\u0646\u0630 ${diff.inHours} \u0633\u0627\u0639\u0627\u062a";
      }
      if (diff.inDays < 30) {
        return diff.inDays == 1
            ? "\u0645\u0646\u0630 \u064a\u0648\u0645"
            : "\u0645\u0646\u0630 ${diff.inDays} \u0623\u064a\u0627\u0645";
      }
      if (diff.inDays < 365) {
        final months = (diff.inDays / 30).floor();
        return months <= 1
            ? "\u0645\u0646\u0630 \u0634\u0647\u0631"
            : "\u0645\u0646\u0630 $months \u0623\u0634\u0647\u0631";
      }

      final years = (diff.inDays / 365).floor();
      return years <= 1
          ? "\u0645\u0646\u0630 \u0633\u0646\u0629"
          : "\u0645\u0646\u0630 $years \u0633\u0646\u0648\u0627\u062a";
    }

    if (diff.inSeconds < 60) {
      return "just now";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} minutes ago";
    }
    if (diff.inHours < 24) {
      return "${diff.inHours} hours ago";
    }
    if (diff.inDays < 30) {
      return "${diff.inDays} days ago";
    }
    if (diff.inDays < 365) {
      return "${(diff.inDays / 30).floor()} months ago";
    }

    return "${(diff.inDays / 365).floor()} years ago";
  }

  static String getCreatedFrom(String createdAt) {
    return AppLocalizations.isArabic
        ? timeAgo(createdAt, lang: "ar")
        : timeAgo(createdAt);
  }
}
