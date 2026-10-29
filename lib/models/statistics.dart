class ClientStatisticsModel {
  final bool success;
  final ClientStatisticsData data;

  ClientStatisticsModel({
    required this.success,
    required this.data,
  });

  factory ClientStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ClientStatisticsModel(
      success: json['success'] ?? false,
      data: ClientStatisticsData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class ClientStatisticsData {
  final int shipments;
  final int shipmentsInProgress;
  final int shipmentsDelivered;
  final int cancelledShipments;
  final String balanceTotal;
  final String totalRequired;
  final String finalTotalValueOrder;
  final int walletVersion;
  final String? withdrawableBalance;
  final String reservedWithdrawals;
  final bool walletReviewRequired;
  // Both directions, from the server: open payouts owed to the merchant and
  // open delivery fees the merchant owes. Null on servers that predate them.
  final String? companyOwesMerchant;
  final String? merchantOwesCompany;

  double? get availableForWithdrawal {
    if (walletVersion != 1 || walletReviewRequired) return null;
    final value = double.tryParse(withdrawableBalance ?? '');
    return value != null && value.isFinite && value >= 0 ? value : null;
  }

  ClientStatisticsData({
    required this.shipments,
    required this.shipmentsInProgress,
    required this.shipmentsDelivered,
    required this.cancelledShipments,
    required this.balanceTotal,
    required this.totalRequired,
    required this.finalTotalValueOrder,
    this.walletVersion = 0,
    this.withdrawableBalance,
    this.reservedWithdrawals = '0.00',
    this.walletReviewRequired = false,
    this.companyOwesMerchant,
    this.merchantOwesCompany,
  });

  factory ClientStatisticsData.fromJson(Map<String, dynamic> json) {
    return ClientStatisticsData(
      shipments: json['shipments'] ?? 0,
      shipmentsInProgress: json['shipments_in_progress'] ?? 0,
      shipmentsDelivered: json['shipments_delivered'] ?? 0,
      cancelledShipments: json['cancelled_shipments'] ?? 0,
      balanceTotal: json['balance_total'] ?? '0.00 JOD',
      totalRequired: json['total_required'] ?? '0.00 JOD',
      finalTotalValueOrder: json['final_total_value_order'] ?? '0.00 JOD',
      walletVersion: json['wallet_version'] is int ? json['wallet_version'] : 0,
      withdrawableBalance: json['withdrawable_balance']?.toString(),
      reservedWithdrawals: json['reserved_withdrawals']?.toString() ?? '0.00',
      walletReviewRequired: json['wallet_review_required'] == true,
      companyOwesMerchant: json['company_owes_merchant']?.toString(),
      merchantOwesCompany: json['merchant_owes_company']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipments': shipments,
      'shipments_in_progress': shipmentsInProgress,
      'shipments_delivered': shipmentsDelivered,
      'cancelled_shipments': cancelledShipments,
      'balance_total': balanceTotal,
      'total_required': totalRequired,
      'final_total_value_order': finalTotalValueOrder,
      'wallet_version': walletVersion,
      'withdrawable_balance': withdrawableBalance,
      'reserved_withdrawals': reservedWithdrawals,
      'wallet_review_required': walletReviewRequired,
      'company_owes_merchant': companyOwesMerchant,
      'merchant_owes_company': merchantOwesCompany,
    };
  }
}
