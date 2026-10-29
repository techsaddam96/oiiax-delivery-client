import 'statement_json.dart';

class StatementPagination {
  const StatementPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  final int page;
  final int limit;
  final int total;
  final int pages;

  bool get hasMore => page < pages;

  factory StatementPagination.fromJson(Map<String, dynamic> json) =>
      StatementPagination(
        page: statementInt(json['page']),
        limit: statementInt(json['limit']),
        total: statementInt(json['total']),
        pages: statementInt(json['pages']),
      );
}
