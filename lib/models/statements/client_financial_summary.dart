import 'statement_json.dart';

class ClientFinancialSummary {
  const ClientFinancialSummary({
    required this.totalStatementsNet,
    required this.totalRemaining,
    required this.statementsCount,
    required this.openStatementsCount,
    required this.latestStatementDate,
  });

  final String totalStatementsNet;
  final String totalRemaining;
  final int statementsCount;
  final int openStatementsCount;
  final String latestStatementDate;

  factory ClientFinancialSummary.fromJson(Map<String, dynamic> json) =>
      ClientFinancialSummary(
        totalStatementsNet: statementString(json['total_statements_net']),
        totalRemaining: statementString(json['total_remaining']),
        statementsCount: statementInt(json['statements_count']),
        openStatementsCount: statementInt(json['open_statements_count']),
        latestStatementDate: statementString(json['latest_statement_date']),
      );
}
