class BlockatieProPackage {
  final int id;
  final String slug;
  final String name;
  final String description;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final String currency;
  final String linkContact;
  final int isActive;
  final List<String> features;
  final List<String> featuresAr;
  final List<String> featuresEn;

  BlockatieProPackage({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    required this.currency,
    required this.linkContact,
    required this.isActive,
    required this.features,
    required this.featuresAr,
    required this.featuresEn,
  });

  factory BlockatieProPackage.fromJson(Map<String, dynamic> json) {
    return BlockatieProPackage(
      id: int.tryParse('${json['id'] ?? ''}') ?? 0,
      slug: '${json['slug'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      descriptionAr: '${json['description_ar'] ?? ''}',
      descriptionEn: '${json['description_en'] ?? ''}',
      price: double.tryParse('${json['price'] ?? ''}') ?? 0,
      currency: '${json['currency'] ?? 'JOD'}',
      linkContact: '${json['link_contact'] ?? ''}',
      isActive: int.tryParse('${json['is_active'] ?? ''}') ?? 0,
      features: _stringList(json['features']),
      featuresAr: _stringList(json['features_ar']),
      featuresEn: _stringList(json['features_en']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => '$item').toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'price': price,
      'currency': currency,
      'link_contact': linkContact,
      'is_active': isActive,
      'features': features,
      'features_ar': featuresAr,
      'features_en': featuresEn,
    };
  }

  // Get localized name based on current language
  String get localizedName {
    // This will be used in the UI with AppLocalizations.isRTL
    return name; // Will be overridden in the UI
  }

  // Get localized description based on current language
  String get localizedDescription {
    // This will be used in the UI with AppLocalizations.isRTL
    return description; // Will be overridden in the UI
  }

  // Get localized features based on current language
  List<String> get localizedFeatures {
    // This will be used in the UI with AppLocalizations.isRTL
    return features; // Will be overridden in the UI
  }
}

class BlockatieProResponse {
  final bool success;
  final List<BlockatieProPackage> packages;

  BlockatieProResponse({
    required this.success,
    required this.packages,
  });

  factory BlockatieProResponse.fromJson(Map<String, dynamic> json) {
    return BlockatieProResponse(
      success: json['success'] ?? false,
      packages: (json['packages'] as List<dynamic>?)
              ?.map((package) => BlockatieProPackage.fromJson(package))
              .toList() ??
          [],
    );
  }
}
