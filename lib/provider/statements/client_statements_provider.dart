import 'package:blockatie/services/user_session_state.dart';
import 'dart:collection';

import 'package:blockatie/models/statements/client_financial_summary.dart';
import 'package:blockatie/models/statements/client_statement.dart';
import 'package:blockatie/models/statements/statement_pagination.dart';
import 'package:blockatie/services/client_statement_service.dart';

enum ClientStatementsState { initial, loading, loaded, empty, error }

class ClientStatementsProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _statements.clear();
    _summary = null;
    _pagination = null;
    _state = ClientStatementsState.initial;
    _errorKey = null;
    _status = null;
    _isRefreshing = false;
    _isLoadingMore = false;
    _isLoadingInitial = false;
  }

  ClientStatementsProvider({ClientStatementService? service})
      : _service = service ?? ClientStatementService();

  final ClientStatementService _service;
  final List<ClientStatement> _statements = [];
  ClientFinancialSummary? _summary;
  StatementPagination? _pagination;
  ClientStatementsState _state = ClientStatementsState.initial;
  String? _errorKey;
  String? _status;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isLoadingInitial = false;

  UnmodifiableListView<ClientStatement> get statements =>
      UnmodifiableListView(_statements);
  ClientFinancialSummary? get summary => _summary;
  ClientStatementsState get state => _state;
  String? get errorKey => _errorKey;
  String? get selectedStatus => _status;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _pagination?.hasMore ?? false;

  Future<void> loadInitial({String? status}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoadingInitial) return;
      _isLoadingInitial = true;
      _status = status;
      _state = ClientStatementsState.loading;
      _errorKey = null;
      notifyListeners();
      try {
        final results = await guardSession(
            Future.wait([
              _service.fetchFinancialSummary(),
              _service.fetchStatements(page: 1, limit: 20, status: _status),
            ]),
            sessionGeneration);
        _summary = results[0] as ClientFinancialSummary;
        final list = results[1] as StatementListResult;
        _statements
          ..clear()
          ..addAll(list.statements);
        _pagination = list.pagination;
        _state = _statements.isEmpty
            ? ClientStatementsState.empty
            : ClientStatementsState.loaded;
      } on StatementException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorKey = error.message;
        _state = ClientStatementsState.error;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isLoadingInitial = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> refresh() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isRefreshing || _isLoadingInitial) return;
      _isRefreshing = true;
      notifyListeners();
      try {
        final results = await guardSession(
            Future.wait([
              _service.fetchFinancialSummary(),
              _service.fetchStatements(page: 1, limit: 20, status: _status),
            ]),
            sessionGeneration);
        _summary = results[0] as ClientFinancialSummary;
        final list = results[1] as StatementListResult;
        _statements
          ..clear()
          ..addAll(list.statements);
        _pagination = list.pagination;
        _state = _statements.isEmpty
            ? ClientStatementsState.empty
            : ClientStatementsState.loaded;
        _errorKey = null;
      } on StatementException catch (error) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _errorKey = error.message;
      } finally {
        if (acceptsState(sessionGeneration)) {
          _isRefreshing = false;
          notifyListeners();
        }
      }
    } on SessionChanged {
      return;
    }
  }

  Future<void> changeStatus(String? status) => loadInitial(status: status);

  Future<void> loadMore() async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoadingMore || _isLoadingInitial || !hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
      try {
        final result = await guardSession(
            _service.fetchStatements(
              page: (_pagination?.page ?? 0) + 1,
              limit: _pagination?.limit ?? 20,
              status: _status,
            ),
            sessionGeneration);
        _statements.addAll(result.statements);
        _pagination = result.pagination;
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
}
