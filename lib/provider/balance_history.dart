import 'package:blockatie/services/session_dio.dart';
import 'package:blockatie/services/user_session_state.dart';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/balance_history.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:dio/dio.dart';

class BalanceHistoryProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    balanceHistoryResponse = null;
    isLoading = false;
    errorMessage = null;
    currentPage = 1;
    hasMoreData = true;
    _selectedFilter = 'all';
    _selectedStatus = 'all';
  }

  BalanceHistoryResponse? balanceHistoryResponse;
  bool isLoading = false;
  String? errorMessage;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool hasMoreData = true;

  // Filter options
  String _selectedFilter = 'all'; // 'all', 'credit', 'debit', 'withdrawal'
  String _selectedStatus = 'all'; // 'all', 'completed', 'pending', 'failed'

  String get selectedFilter => _selectedFilter;
  String get selectedStatus => _selectedStatus;

  List<BalanceTransaction> get transactions {
    if (balanceHistoryResponse == null) return [];
    return balanceHistoryResponse!.transactions;
  }

  List<BalanceTransaction> get filteredTransactions {
    if (balanceHistoryResponse == null) return [];

    return balanceHistoryResponse!.transactions.where((transaction) {
      // Filter by type
      if (_selectedFilter != 'all' &&
          transaction.type.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }

      // Filter by status
      if (_selectedStatus != 'all' &&
          transaction.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();
  }

  int get totalCount => balanceHistoryResponse?.totalCount ?? 0;
  int get filteredCount => filteredTransactions.length;

  // Get balance history from API
  Future<void> fetchBalanceHistory({bool refresh = false}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (refresh) {
        currentPage = 1;
        hasMoreData = true;
      }

      if (!hasMoreData && !refresh) return;

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      try {
        final dio = sessionDio();
        final clientId =
            await guardSession(AuthService.getUserId(), sessionGeneration);
        final apiKey =
            await guardSession(AuthService.getApiKey(), sessionGeneration);

        if (clientId == null || apiKey == null) {
          errorMessage = 'Missing user ID or API key';
          isLoading = false;
          notifyListeners();
          return;
        }

        final response = await guardSession(
            dio.post(
              AppUrls.getBalanceHistory,
              options: Options(
                headers: {
                  'Content-Type': 'application/x-www-form-urlencoded',
                  'X-API-KEY': apiKey,
                },
              ),
              data: {
                'clientId': clientId,
                'page': currentPage,
                'limit': itemsPerPage,
                'filter': _selectedFilter,
                'status': _selectedStatus,
              },
            ),
            sessionGeneration);

        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
          final newResponse = BalanceHistoryResponse.fromJson(response.data);

          if (refresh || currentPage == 1) {
            balanceHistoryResponse = newResponse;
          } else {
            // Append new transactions to existing ones
            final existingTransactions =
                balanceHistoryResponse?.transactions ?? [];
            final allTransactions = [
              ...existingTransactions,
              ...newResponse.transactions
            ];
            balanceHistoryResponse = BalanceHistoryResponse(
              status: newResponse.status,
              message: newResponse.message,
              transactions: allTransactions,
              totalCount: newResponse.totalCount,
            );
          }

          // Check if there's more data
          hasMoreData = newResponse.transactions.length >= itemsPerPage;
        } else {
          errorMessage =
              response.data['message'] ?? 'Failed to fetch balance history';
          AppUtils.showErrorDialog(errorMessage!);
        }
      } catch (e) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        errorMessage = 'Network error occurred';
        AppUtils.showErrorDialog(
            'Failed to load balance history. Please try again.');
      }

      isLoading = false;
      notifyListeners();
    } on SessionChanged {
      return;
    }
  }

  // Load more data (for pagination)
  Future<void> loadMoreTransactions() async {
    final sessionGeneration = stateGeneration;
    try {
      if (isLoading || !hasMoreData) return;

      currentPage++;
      await guardSession(fetchBalanceHistory(), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  // Refresh data
  Future<void> refreshTransactions() async {
    final sessionGeneration = stateGeneration;
    try {
      await guardSession(fetchBalanceHistory(refresh: true), sessionGeneration);
    } on SessionChanged {
      return;
    }
  }

  // Filter transactions
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _selectedFilter = 'all';
    _selectedStatus = 'all';
    notifyListeners();
  }

  // Get transaction statistics
  Map<String, double> getTransactionStats() {
    final transactions = filteredTransactions;
    double totalCredit = 0;
    double totalDebit = 0;

    for (final transaction in transactions) {
      final amount =
          double.tryParse(transaction.amount.replaceAll(' JOD', '')) ?? 0;

      if (transaction.type.toLowerCase() == 'credit' ||
          transaction.type.toLowerCase() == 'payment') {
        totalCredit += amount;
      } else {
        totalDebit += amount;
      }
    }

    return {
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'netAmount': totalCredit - totalDebit,
    };
  }

  // Get recent transactions (last 5)
  List<BalanceTransaction> get recentTransactions {
    final transactions = filteredTransactions;
    return transactions.take(5).toList();
  }

  // Get transactions by date range
  List<BalanceTransaction> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    final startDate = _calendarDate(start);
    final endDate = _calendarDate(end);
    return filteredTransactions.where((transaction) {
      final transactionDate = JordanTime.parse(transaction.createdAt);
      if (transactionDate == null) return false;

      final transactionCalendarDate = _calendarDate(transactionDate);
      return transactionCalendarDate >= startDate &&
          transactionCalendarDate <= endDate;
    }).toList();
  }

  // Get transactions by month
  List<BalanceTransaction> getTransactionsByMonth(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getTransactionsByDateRange(startDate, endDate);
  }

  // Get current month transactions
  List<BalanceTransaction> get currentMonthTransactions {
    final now = JordanTime.now();
    return getTransactionsByMonth(now.year, now.month);
  }

  /// Calendar-only comparisons: the caller's range is a requested business
  /// date, while transaction instants have already been converted to Amman.
  static int _calendarDate(DateTime value) =>
      (value.year * 10000) + (value.month * 100) + value.day;

  // Get current month statistics
  Map<String, double> get currentMonthStats {
    final transactions = currentMonthTransactions;
    double totalCredit = 0;
    double totalDebit = 0;

    for (final transaction in transactions) {
      final amount =
          double.tryParse(transaction.amount.replaceAll(' JOD', '')) ?? 0;

      if (transaction.type.toLowerCase() == 'credit' ||
          transaction.type.toLowerCase() == 'payment') {
        totalCredit += amount;
      } else {
        totalDebit += amount;
      }
    }

    return {
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'netAmount': totalCredit - totalDebit,
    };
  }
}
