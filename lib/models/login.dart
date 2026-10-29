class LoginResponse {
  final bool success;
  final ClientData data;

  LoginResponse({
    required this.success,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      data: ClientData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class ClientData {
  final int id;
  final String nclient;
  final String nstore;
  final String phclient;
  final String lclient;
  final int prdclient;
  final String loshop;
  final String links_shop;
  final String created_at;
  final String api_key;

  ClientData({
    required this.id,
    required this.nclient,
    required this.nstore,
    required this.phclient,
    required this.lclient,
    required this.prdclient,
    required this.loshop,
    required this.links_shop,
    required this.created_at,
    required this.api_key,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: json['id'] ?? 0,
      nclient: json['nclient'] ?? '',
      nstore: json['nstore'] ?? '',
      phclient: json['phclient'] ?? '',
      lclient: json['lclient'] ?? '',
      prdclient: json['prdclient'] ?? 0,
      loshop: json['loshop'] ?? '',
      links_shop: json['links_shop'] ?? '',
      created_at: json['created_at'] ?? '',
      api_key: json['api_key'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nclient': nclient,
      'nstore': nstore,
      'phclient': phclient,
      'lclient': lclient,
      'prdclient': prdclient,
      'loshop': loshop,
      'links_shop': links_shop,
      'created_at': created_at,
      'api_key': api_key,
    };
  }
}
