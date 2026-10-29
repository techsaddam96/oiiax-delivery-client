/// The merchant's side of one shipment's money, exactly as the server computed
/// it. Display only: the app never recomputes or sends these amounts back.
///
/// Older shipments (before the financial model) carry only [productToCollect];
/// every fee figure is null and the UI hides it.
class ShipmentFinancial {
  final String paymentType;
  final double productToCollect;
  final double? feeDue;
  final double? feeCollected;
  final double? feeRemaining;
  final String? collectionStatus;
  final double? merchantPayable;
  final double? merchantReceivable;

  const ShipmentFinancial({
    required this.paymentType,
    required this.productToCollect,
    this.feeDue,
    this.feeCollected,
    this.feeRemaining,
    this.collectionStatus,
    this.merchantPayable,
    this.merchantReceivable,
  });

  bool get isPrepaid => paymentType == 'prepaid';

  /// True when the server tracks this shipment's fee (not a legacy row).
  bool get isTracked => feeDue != null;

  static ShipmentFinancial? tryParse(dynamic json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    return ShipmentFinancial(
      paymentType: map['payment_type'] == 'prepaid' ? 'prepaid' : 'cod',
      productToCollect: _money(map['product_to_collect']) ?? 0,
      feeDue: _money(map['fee_due']),
      feeCollected: _money(map['fee_collected']),
      feeRemaining: _money(map['fee_remaining']),
      collectionStatus: map['collection_status']?.toString(),
      merchantPayable: _money(map['merchant_payable']),
      merchantReceivable: _money(map['merchant_receivable']),
    );
  }
}

/// What cancelling now would cost, from the server. The cancel endpoint stays
/// the authority; this only lets the app warn before the merchant confirms.
class CancellationPreview {
  final bool allowed;
  final String? stage;
  final double feeIfCancelled;

  const CancellationPreview({
    required this.allowed,
    required this.stage,
    required this.feeIfCancelled,
  });

  static CancellationPreview? tryParse(dynamic json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    return CancellationPreview(
      allowed: map['allowed'] == true,
      stage: map['stage']?.toString(),
      feeIfCancelled: _money(map['fee_if_cancelled']) ?? 0,
    );
  }
}

double? _money(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
