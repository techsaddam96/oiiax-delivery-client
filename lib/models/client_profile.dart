class ClientProfileModel {
  final String status;
  final String message;
  final ClientInfo profile;

  ClientProfileModel({
    required this.status,
    required this.message,
    required this.profile,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      profile: ClientInfo.fromJson(json['profile'] ?? {}),
    );
  }
}

class ClientInfo {
  final int id;
  final String nclient;
  final String nstore;
  final String phclient;
  final String lclient;
  final String loshop;
  final int prdclient;
  final String linksShop;
  final String createdAt;
  final int status;
  final int subscription;
  final double? latitude;
  final double? longitude;

  ClientInfo({
    required this.id,
    required this.nclient,
    required this.nstore,
    required this.phclient,
    required this.lclient,
    required this.loshop,
    required this.prdclient,
    required this.linksShop,
    required this.createdAt,
    required this.status,
    required this.subscription,
    this.latitude,
    this.longitude,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] ?? 0,
      nclient: json['nclient'] ?? '',
      nstore: json['nstore'] ?? '',
      phclient: json['phclient'] ?? '',
      lclient: json['lclient'] ?? '',
      loshop: json['loshop'] ?? '',
      prdclient: json['prdclient'] ?? 0,
      linksShop: json['links_shop'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 0,
      subscription: json['subscription'] ?? 0,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}
