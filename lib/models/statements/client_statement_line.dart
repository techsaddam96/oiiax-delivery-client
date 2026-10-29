import 'statement_json.dart';

class ClientStatementLine {
  const ClientStatementLine({
    required this.shipmentId,
    required this.shipmentReference,
    required this.shipmentAmount,
    required this.deliveryFee,
    required this.commissionAmount,
    required this.netAmount,
    required this.shipmentStatus,
    required this.shipmentDate,
  });

  final int shipmentId;
  final String shipmentReference;
  final String shipmentAmount;
  final String deliveryFee;
  final String commissionAmount;
  final String netAmount;
  final String shipmentStatus;
  final String shipmentDate;

  factory ClientStatementLine.fromJson(Map<String, dynamic> json) =>
      ClientStatementLine(
        shipmentId: statementInt(json['shipment_id']),
        shipmentReference: statementString(json['policy_num']),
        shipmentAmount: statementString(json['shipment_amount']),
        deliveryFee: statementString(json['delivery_fee']),
        commissionAmount: statementString(json['commission_amount']),
        netAmount: statementString(json['net_amount']),
        shipmentStatus: statementString(json['shipment_status']),
        shipmentDate: statementString(json['shipment_date']),
      );
}
