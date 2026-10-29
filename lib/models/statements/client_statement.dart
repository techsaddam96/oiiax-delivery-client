import 'statement_json.dart';

class ClientStatement {
  const ClientStatement({
    required this.statementId,
    required this.statementNumber,
    required this.periodFrom,
    required this.periodTo,
    required this.netAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    required this.approvedAt,
    required this.hasPdf,
    this.canRevealHandoverCode = false,
  });

  final int statementId;
  final String statementNumber;
  final String periodFrom;
  final String periodTo;
  final String netAmount;
  final String remainingAmount;
  final String status;
  final String createdAt;
  final String approvedAt;
  final bool hasPdf;
  final bool canRevealHandoverCode;

  factory ClientStatement.fromJson(Map<String, dynamic> json) =>
      ClientStatement(
        statementId: statementInt(json['statement_id']),
        statementNumber: statementString(json['statement_number']),
        periodFrom: statementString(json['period_from']),
        periodTo: statementString(json['period_to']),
        netAmount: statementString(json['net_amount']),
        remainingAmount: statementString(json['remaining_amount']),
        status: statementString(json['status']),
        createdAt: statementString(json['created_at']),
        approvedAt: statementString(json['approved_at']),
        hasPdf: statementBool(json['has_pdf']),
        canRevealHandoverCode: json['can_reveal_handover_code'] == true,
      );
}
