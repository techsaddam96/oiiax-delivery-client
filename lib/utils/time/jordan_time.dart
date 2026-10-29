import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class JordanTime {
  JordanTime._();

  static const String timezoneId = 'Asia/Amman';

  static bool _isInitialized = false;
  static tz.Location? _amman;

  static void ensureInitialized() {
    if (_isInitialized) {
      return;
    }

    tz_data.initializeTimeZones();
    _amman = tz.getLocation(timezoneId);
    _isInitialized = true;
  }

  static tz.Location get location {
    ensureInitialized();
    return _amman!;
  }

  static tz.TZDateTime now() {
    return tz.TZDateTime.now(location);
  }

  static tz.TZDateTime toJordan(DateTime value) {
    return tz.TZDateTime.from(value.toUtc(), location);
  }

  static tz.TZDateTime? parse(
    String? value, {
    String? jordanValue,
    String? utcValue,
    bool assumeUtcWithoutTimezone = false,
  }) {
    ensureInitialized();

    final source = _pickSource(
      primary: jordanValue,
      secondary: utcValue,
      fallback: value,
    );
    if (source == null) {
      return null;
    }

    final normalized =
        source.contains(' ') ? source.replaceFirst(' ', 'T') : source;
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return null;
    }

    if (_hasExplicitTimezone(source)) {
      return tz.TZDateTime.from(parsed.toUtc(), location);
    }

    if (assumeUtcWithoutTimezone) {
      final utcDateTime = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
      return tz.TZDateTime.from(utcDateTime, location);
    }

    return tz.TZDateTime(
      location,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static String formatForNotifications({
    required String locale,
    required String? value,
    String? jordanValue,
    String? utcValue,
    required String justNowLabel,
    required String todayLabel,
    required String yesterdayLabel,
    required String minuteAgoLabel,
    required String minutesAgoLabel,
    required String hourAgoLabel,
    required String hoursAgoLabel,
    required String unavailableLabel,
  }) {
    // Notifications are operational records: their calendar labels and clock
    // values follow the Jordan business day even when the merchant's device is
    // configured for another time zone. Prefer the API's explicit Jordan copy;
    // fall back to its explicit UTC instant, then to the legacy Amman-local
    // DATETIME value. A legacy offset-less value is never guessed to be UTC.
    final parsed = parse(
      value,
      jordanValue: jordanValue,
      utcValue: utcValue,
    );
    if (parsed == null) {
      return unavailableLabel;
    }

    final nowJordan = now();
    final difference = nowJordan.difference(parsed);

    if (difference.inSeconds < 60) {
      return justNowLabel;
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes == 1) {
        return minuteAgoLabel;
      }
      return '$minutes $minutesAgoLabel';
    }

    final isSameDay = _isSameDay(parsed, nowJordan);
    if (difference.inHours < 6 && isSameDay) {
      final hours = difference.inHours;
      if (hours <= 1) {
        return hourAgoLabel;
      }
      return '$hours $hoursAgoLabel';
    }

    final timeFormat = DateFormat('h:mm a', locale);
    if (isSameDay) {
      return '$todayLabel ${timeFormat.format(parsed)}';
    }

    final yesterday = nowJordan.subtract(const Duration(days: 1));
    if (_isSameDay(parsed, yesterday)) {
      return '$yesterdayLabel ${timeFormat.format(parsed)}';
    }

    return DateFormat('dd/MM/yyyy h:mm a', locale).format(parsed);
  }

  static String? _pickSource({
    required String? primary,
    required String? secondary,
    required String? fallback,
  }) {
    for (final candidate in [primary, secondary, fallback]) {
      final normalized = candidate?.trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static bool _hasExplicitTimezone(String value) {
    final normalized = value.trim();
    return RegExp(r'(Z|z|[+\-]\d{2}:\d{2}|[+\-]\d{4})$').hasMatch(normalized);
  }

  static bool _isSameDay(tz.TZDateTime first, tz.TZDateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

}
