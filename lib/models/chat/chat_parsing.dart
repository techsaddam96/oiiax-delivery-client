import 'package:blockatie/utils/time/jordan_time.dart';

Map<String, dynamic> chatJsonMap(
  dynamic value, {
  String fieldName = 'data',
  bool allowNull = false,
}) {
  if (value == null && allowNull) {
    return <String, dynamic>{};
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  throw FormatException('Invalid chat contract field: $fieldName');
}

List<dynamic> chatJsonList(
  dynamic value, {
  required String fieldName,
}) {
  if (value == null) {
    return const <dynamic>[];
  }
  if (value is List) {
    return value;
  }
  throw FormatException('Invalid chat contract field: $fieldName');
}

String chatString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString().trim();
}

int? chatInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(chatString(value));
}

int chatRequiredPositiveInt(dynamic value, {required String fieldName}) {
  final parsed = chatInt(value);
  if (parsed == null || parsed <= 0) {
    throw FormatException('Invalid chat contract field: $fieldName');
  }
  return parsed;
}

bool chatBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  switch (chatString(value).toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
      return true;
    case '0':
    case 'false':
    case 'no':
      return false;
    default:
      return fallback;
  }
}

DateTime? chatDateTime(dynamic value) {
  final normalized = chatString(value);
  if (normalized.isEmpty) {
    return null;
  }
  return JordanTime.parse(normalized);
}
