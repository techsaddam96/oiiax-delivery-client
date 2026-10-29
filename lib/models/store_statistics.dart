class StoreStatistics {
  final int totalOrders;
  final int activeOrders;
  final String revenue;
  final String dueBalance;
  final double rating;
  final int totalShipments;
  final int shipmentsInProgress;
  final int shipmentsDelivered;
  final int cancelledShipments;

  StoreStatistics({
    required this.totalOrders,
    required this.activeOrders,
    required this.revenue,
    required this.dueBalance,
    required this.rating,
    required this.totalShipments,
    required this.shipmentsInProgress,
    required this.shipmentsDelivered,
    required this.cancelledShipments,
  });

  factory StoreStatistics.fromJson(Map<String, dynamic> json) {
    return StoreStatistics(
      totalOrders: json['shipments'] ?? 0,
      activeOrders: json['shipments_in_progress'] ?? 0,
      // Keep the "Current Balance" metric consistent with the wallet, home,
      // and profile surfaces. `final_total_value_order` is total due, not the
      // current balance.
      revenue: json['balance_total'] ?? '0.00 JOD',
      dueBalance: json['final_total_value_order'] ?? '0.00 JOD',
      rating: _parseRating(json['rating']),
      totalShipments: json['shipments'] ?? 0,
      shipmentsInProgress: json['shipments_in_progress'] ?? 0,
      shipmentsDelivered: json['shipments_delivered'] ?? 0,
      cancelledShipments: json['cancelled_shipments'] ?? 0,
    );
  }

  /// Create StoreStatistics from JSON with a separate rating value
  factory StoreStatistics.fromJsonWithRating(
      Map<String, dynamic> json, double rating) {
    return StoreStatistics(
      totalOrders: json['shipments'] ?? 0,
      activeOrders: json['shipments_in_progress'] ?? 0,
      revenue: json['balance_total'] ?? '0.00 JOD',
      dueBalance: json['final_total_value_order'] ?? '0.00 JOD',
      rating: rating,
      totalShipments: json['shipments'] ?? 0,
      shipmentsInProgress: json['shipments_in_progress'] ?? 0,
      shipmentsDelivered: json['shipments_delivered'] ?? 0,
      cancelledShipments: json['cancelled_shipments'] ?? 0,
    );
  }

  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is int) return rating.toDouble();
    if (rating is double) return rating;
    if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'activeOrders': activeOrders,
      'revenue': revenue,
      'dueBalance': dueBalance,
      'rating': rating,
      'totalShipments': totalShipments,
      'shipmentsInProgress': shipmentsInProgress,
      'shipmentsDelivered': shipmentsDelivered,
      'cancelledShipments': cancelledShipments,
    };
  }

  @override
  String toString() {
    return 'StoreStatistics(totalOrders: $totalOrders, activeOrders: $activeOrders, revenue: $revenue, dueBalance: $dueBalance, rating: $rating, totalShipments: $totalShipments, shipmentsInProgress: $shipmentsInProgress, shipmentsDelivered: $shipmentsDelivered, cancelledShipments: $cancelledShipments)';
  }
}
