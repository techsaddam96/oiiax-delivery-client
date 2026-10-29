class ShipmentActionReason {
  const ShipmentActionReason({
    required this.id,
    required this.actionType,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
  });

  final int id;
  final String actionType;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;

  factory ShipmentActionReason.fromJson(Map<String, dynamic> json) {
    return ShipmentActionReason(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      actionType: json['action_type']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),
    );
  }

  String title(bool isRtl) {
    final preferred = isRtl ? titleAr : titleEn;
    final fallback = isRtl ? titleEn : titleAr;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }

  String? description(bool isRtl) {
    final preferred = isRtl ? descriptionAr : descriptionEn;
    final fallback = isRtl ? descriptionEn : descriptionAr;
    final value = (preferred ?? '').trim().isNotEmpty ? preferred : fallback;
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
