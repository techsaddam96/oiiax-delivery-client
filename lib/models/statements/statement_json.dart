String statementString(dynamic value) => value?.toString().trim() ?? '';

int statementInt(dynamic value) =>
    int.tryParse(statementString(value)) ?? (value is num ? value.toInt() : 0);

bool statementBool(dynamic value) {
  if (value is bool) return value;
  final text = statementString(value).toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}

Map<String, dynamic> statementMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}
