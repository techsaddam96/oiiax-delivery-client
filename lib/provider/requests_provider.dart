import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/services/requests_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';

class RequestsProvider extends UserScopedNotifier {
  @override
  void clearUserState() {
    _requests = [];
    _isLoading = false;
    _error = null;
    _currentPage = 1;
  }

  List<WithdrawalRequest> _requests = <WithdrawalRequest>[];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  List<WithdrawalRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;

  List<WithdrawalRequest> get paginatedRequests {
    if (_requests.isEmpty) {
      return const <WithdrawalRequest>[];
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= _requests.length) {
      return const <WithdrawalRequest>[];
    }

    final endIndex = (startIndex + _itemsPerPage).clamp(0, _requests.length);
    return _requests.sublist(startIndex, endIndex);
  }

  int get totalPages {
    if (_requests.isEmpty) {
      return 0;
    }
    return (_requests.length / _itemsPerPage).ceil();
  }

  Future<void> fetchRequests({bool force = false}) async {
    final sessionGeneration = stateGeneration;
    try {
      if (_isLoading && !force) {
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final result = await guardSession(
            RequestsService.fetchWithdrawalRequests(), sessionGeneration);
        if (result['success'] == true) {
          final fetched = result['requests'];
          _requests = fetched is List<WithdrawalRequest>
              ? fetched
              : const <WithdrawalRequest>[];
          _currentPage = _requests.isEmpty ? 0 : 1;
          _error = null;
        } else {
          _requests = const <WithdrawalRequest>[];
          _currentPage = 0;
          _error = _safeMessage(
            result['message'],
            fallback: _text(
              'Unable to load wallet data. Please try again.',
              'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
            ),
          );
        }
      } catch (_) {
        if (!acceptsState(sessionGeneration)) throw const SessionChanged();

        _requests = const <WithdrawalRequest>[];
        _currentPage = 0;
        _error = _text(
          'Unable to load wallet data. Please try again.',
          'تعذر تحميل بيانات المحفظة. حاول مرة أخرى.',
        );
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

  Future<void> refresh() {
    return fetchRequests(force: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void goToNextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void goToPrevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  String _safeMessage(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _text(String en, String ar) => AppLocalizations.isArabic ? ar : en;
}
