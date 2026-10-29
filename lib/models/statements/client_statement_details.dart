import 'client_statement.dart';
import 'client_statement_line.dart';
import 'statement_json.dart';
import 'statement_pagination.dart';

class ClientStatementDetails {
  const ClientStatementDetails({
    required this.statement,
    required this.summary,
    required this.lines,
    required this.pagination,
  });

  final ClientStatement statement;
  final ClientStatementDetailsSummary summary;
  final List<ClientStatementLine> lines;
  final StatementPagination pagination;

  factory ClientStatementDetails.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] is List ? json['lines'] as List : const [];
    return ClientStatementDetails(
      statement: ClientStatement.fromJson(statementMap(json['statement'])),
      summary:
          ClientStatementDetailsSummary.fromJson(statementMap(json['summary'])),
      lines: rawLines
          .map((line) => ClientStatementLine.fromJson(statementMap(line)))
          .toList(growable: false),
      pagination:
          StatementPagination.fromJson(statementMap(json['pagination'])),
    );
  }
}

class ClientStatementDetailsSummary {
  const ClientStatementDetailsSummary({
    required this.shipmentsCount,
    required this.codTotal,
    required this.deliveryFeesTotal,
    required this.netTotal,
  });

  final int shipmentsCount;
  final String codTotal;
  final String deliveryFeesTotal;
  final String netTotal;

  factory ClientStatementDetailsSummary.fromJson(Map<String, dynamic> json) =>
      ClientStatementDetailsSummary(
        shipmentsCount: statementInt(json['shipments_count']),
        codTotal: statementString(json['cod_total']),
        deliveryFeesTotal: statementString(json['delivery_fees_total']),
        netTotal: statementString(json['net_total']),
      );
}
