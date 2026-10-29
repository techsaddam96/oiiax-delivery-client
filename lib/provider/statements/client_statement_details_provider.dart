import 'package:blockatie/services/user_session_state.dart';
import 'dart:collection';

import 'package:blockatie/models/statements/client_statement_details.dart';
import 'package:blockatie/models/statements/client_statement_line.dart';
import 'package:blockatie/models/statements/statement_pagination.dart';
import 'package:blockatie/services/client_statement_service.dart';

class ClientStatementDetailsProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _lines.clear();
    _details = null;
    _pagination = null;
    _errorKey = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isDownloadingPdf = false;
  }

  ClientStatementDetailsProvider({ClientStatementService? service})
      : _service = service ?? ClientStatementService();

  final ClientStatementService _service;
  final List<ClientStatementLine> _lines = [];
  ClientStatementDetails? _details;
  StatementPagination? _pagination;
  String? _errorKey;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isDownloadingPdf = false;

  ClientStatementDetails? get details => _details;
  UnmodifiableListView<ClientStatementLine> get lines =>
      UnmodifiableListView(_lines);
  String? get errorKey => _errorKey;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isDownloadingPdf => _isDownloadingPdf;
  bool get hasMore => _pagination?.hasMore ?? false;

  Future<void> load(int statementId) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoading) return;
      _isLoading = true;
      _errorKey = null;
      notifyListeners();
      try {
        final result = await guardSession(
            _service.fetchStatementDetails(
                statementId: statementId, page: 1, limit: 30),
            sessionGeneration);
        _details = result;
        _pagination = result.pagination;
        _lines
          ..clear()
          ..addAll(result.lines);
      } on StatementException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorKey = error.message;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> loadMore() async {
    final sessionGeneration = stateGeneration;
    try {
      final statementId = _details?.statement.statementId ?? 0;
      if (_isLoadingMore || !hasMore || statementId <= 0) return;
      _isLoadingMore = true;
      notifyListeners();
      try {
        final result = await guardSession(
            _service.fetchStatementDetails(
              statementId: statementId,
              page: (_pagination?.page ?? 0) + 1,
              limit: _pagination?.limit ?? 30,
            ),
            sessionGeneration);
        _pagination = result.pagination;
        _lines.addAll(result.lines);
      } on StatementException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorKey = error.message;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoadingMore = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<String?> downloadPdf() async {
    final sessionGeneration = stateGeneration;
    try {
      final statement = _details?.statement;
      if (statement == null || _isDownloadingPdf) return 'pdf';
      _isDownloadingPdf = true;
      notifyListeners();
      try {
        await guardSession(
            _service.downloadAndOpenStatementPdf(
              statementId: statement.statementId,
              statementNumber: statement.statementNumber,
            ),
            sessionGeneration);
        return null;
      } on StatementException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        return error.message;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isDownloadingPdf = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return null;
    }
  }
}
