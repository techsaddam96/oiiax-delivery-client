import 'package:blockatie/services/session_dio.dart';
import 'dart:io';
import 'dart:async';
import 'user_session_state.dart';

import 'package:blockatie/constants/app_urls.dart';
import 'package:blockatie/models/statements/client_financial_summary.dart';
import 'package:blockatie/models/statements/client_statement.dart';
import 'package:blockatie/models/statements/client_statement_details.dart';
import 'package:blockatie/models/statements/statement_json.dart';
import 'package:blockatie/models/statements/statement_pagination.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class StatementException implements Exception {
  const StatementException(this.message);
  final String message;
}

class StatementAuthenticationException extends StatementException {
  const StatementAuthenticationException() : super('authentication');
}

class StatementAuthorizationException extends StatementException {
  const StatementAuthorizationException() : super('authorization');
}

class StatementNotFoundException extends StatementException {
  const StatementNotFoundException() : super('not_found');
}

class StatementValidationException extends StatementException {
  const StatementValidationException() : super('validation');
}

class StatementNetworkException extends StatementException {
  const StatementNetworkException() : super('network');
}

class StatementServerException extends StatementException {
  const StatementServerException() : super('server');
}

class StatementPdfException extends StatementException {
  const StatementPdfException() : super('pdf');
}

class StatementListResult {
  const StatementListResult(this.statements, this.pagination);
  final List<ClientStatement> statements;
  final StatementPagination pagination;
}

class ClientStatementService {
  static final Set<File> _temporaryPdfs = {};
  static void _clearTemporaryPdfs() {
    final files = List<File>.of(_temporaryPdfs);
    _temporaryPdfs.clear();
    for (final file in files) {
      unawaited(file
          .delete()
          .then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    }
  }

  ClientStatementService({Dio? dio})
      : _dio = dio ??
            sessionDio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 12),
              responseType: ResponseType.json,
            ));

  final Dio _dio;

  Future<String> revealHandoverCode(int statementId) async {
    final generation = UserSessionState.generation;
    if (statementId <= 0) throw const StatementValidationException();
    final key = (await AuthService.getApiKey())?.trim() ?? '';
    if (key.isEmpty || generation != UserSessionState.generation) {
      throw const StatementAuthenticationException();
    }
    try {
      final response = await _dio.post<dynamic>(
        '${AppUrls.baseUrl}/api_client_statement_handover_code.php',
        data: {'statement_id': statementId},
        options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {'X-API-KEY': key, 'Accept': 'application/json'}),
      );
      if (generation != UserSessionState.generation) {
        throw const StatementAuthenticationException();
      }
      final body = statementMap(response.data);
      final data = statementMap(body['data']);
      final code = data['handover_code'];
      if (response.statusCode != 200 ||
          body['success'] != true ||
          data['statement_id'] != statementId ||
          code is! String ||
          !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
        throw const StatementServerException();
      }
      return code;
    } on DioException catch (error) {
      throw _exceptionFromStatus(error.response?.statusCode);
    }
  }

  Future<StatementListResult> fetchStatements({
    required int page,
    required int limit,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (page < 1 || limit < 1 || limit > 50) {
      throw const StatementValidationException();
    }
    final data = await _get(AppUrls.clientStatements, {
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    final items =
        data['statements'] is List ? data['statements'] as List : const [];
    return StatementListResult(
      items
          .map((item) => ClientStatement.fromJson(statementMap(item)))
          .toList(growable: false),
      StatementPagination.fromJson(statementMap(data['pagination'])),
    );
  }

  Future<ClientFinancialSummary> fetchFinancialSummary() async {
    final data = await _get(AppUrls.clientFinancialSummary, const {});
    return ClientFinancialSummary.fromJson(data);
  }

  Future<ClientStatementDetails> fetchStatementDetails({
    required int statementId,
    required int page,
    required int limit,
  }) async {
    if (statementId <= 0 || page < 1 || limit < 1 || limit > 100) {
      throw const StatementValidationException();
    }
    final data = await _get(AppUrls.clientStatementDetails, {
      'statement_id': statementId,
      'page': page,
      'limit': limit,
    });
    return ClientStatementDetails.fromJson(data);
  }

  Future<void> downloadAndOpenStatementPdf({
    required int statementId,
    required String statementNumber,
  }) async {
    final generation = UserSessionState.generation;
    UserSessionState.register(_clearTemporaryPdfs);
    if (statementId <= 0) throw const StatementValidationException();
    final apiKey = (await AuthService.getApiKey())?.trim() ?? '';
    if (apiKey.isEmpty) throw const StatementAuthenticationException();
    try {
      final response = await _dio.get<List<int>>(
        AppUrls.clientStatementPdf,
        queryParameters: {'statement_id': statementId},
        options: Options(
          headers: {'X-API-KEY': apiKey, 'Accept': 'application/pdf'},
          responseType: ResponseType.bytes,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.length < 5) {
        throw const StatementPdfException();
      }
      if (generation != UserSessionState.generation) {
        throw const StatementAuthenticationException();
      }
      final directory = await getTemporaryDirectory();
      if (generation != UserSessionState.generation) {
        throw const StatementAuthenticationException();
      }
      final safeName =
          statementNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File(
          '${directory.path}${Platform.pathSeparator}statement_${generation}_${safeName.isEmpty ? 'file' : safeName}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (generation != UserSessionState.generation) {
        await file.delete();
        throw const StatementAuthenticationException();
      }
      _temporaryPdfs.add(file);
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      if (result.type != ResultType.done) {
        throw const StatementPdfException();
      }
    } on DioException catch (error) {
      throw _exceptionFromStatus(error.response?.statusCode);
    } on StatementException {
      rethrow;
    } catch (_) {
      throw const StatementPdfException();
    }
  }

  Future<Map<String, dynamic>> _get(
      String url, Map<String, dynamic> query) async {
    final apiKey = (await AuthService.getApiKey())?.trim() ?? '';
    if (apiKey.isEmpty) throw const StatementAuthenticationException();
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: query,
        options: Options(
            headers: {'X-API-KEY': apiKey, 'Accept': 'application/json'}),
      );
      final body = statementMap(response.data);
      if (body['success'] != true) throw const StatementServerException();
      return statementMap(body['data']);
    } on DioException catch (error) {
      throw _exceptionFromStatus(error.response?.statusCode);
    } on StatementException {
      rethrow;
    } catch (_) {
      throw const StatementServerException();
    }
  }

  StatementException _exceptionFromStatus(int? statusCode) {
    if (statusCode == 401) return const StatementAuthenticationException();
    if (statusCode == 403) return const StatementAuthorizationException();
    if (statusCode == 404) return const StatementNotFoundException();
    if (statusCode == 400 || statusCode == 422) {
      return const StatementValidationException();
    }
    if (statusCode == null) {
      return const StatementNetworkException();
    }
    return const StatementServerException();
  }
}
