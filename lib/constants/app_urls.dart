import 'package:flutter/foundation.dart';

class AppUrls {
  static const String productionBaseUrl =
      'https://dashboard.blockatie.com/services';
  static const String _qaBaseUrlOverride =
      String.fromEnvironment('BLOCKATIE_QA_API_BASE_URL');
  static const String _qaEnvironment =
      String.fromEnvironment('BLOCKATIE_QA_ENVIRONMENT');

  /// Required alongside a local API URL before a Warehouse E2E run.
  static const String localWarehouseE2eEnvironment = 'local-warehouse-e2e';

  static String _userAgent = "";
  static String _accessToken = "";

  static final String _baseUrl = _resolveBaseUrl(
    isReleaseBuild: kReleaseMode,
    qaBaseUrl: _qaBaseUrlOverride,
  );

  static setUserAgeent(String userAgent) {
    _userAgent = userAgent;
  }

  static setAccessToken(String accessToken) {
    _accessToken = accessToken;
  }

  static Map<String, String> authHeader() {
    return {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
    };
  }

  static Map<String, String> acessTokenHeader() {
    return {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
      'Authorization': 'Bearer $_accessToken',
    };
  }

  static String get baseUrl => _baseUrl;

  /// True only for the explicitly named local Warehouse acceptance environment.
  static bool get isExplicitLocalWarehouseE2e =>
      !kReleaseMode &&
      _qaEnvironment == localWarehouseE2eEnvironment &&
      _isLocalApiUrl(baseUrl);

  static String get environmentLabel {
    if (isExplicitLocalWarehouseE2e) {
      return 'local Warehouse E2E QA';
    }
    if (_qaBaseUrlOverride.trim().isNotEmpty) {
      return 'debug API override';
    }
    return 'production default';
  }

  /// Forces configuration validation during application startup. In particular,
  /// a release binary compiled with a QA endpoint fails before it can issue a
  /// request, rather than silently falling back to its first API call.
  static void validateActiveConfiguration() {
    if (baseUrl.isEmpty) {
      throw StateError('The API base URL is unavailable.');
    }
  }

  /// Intended for the E2E runner before it creates or cancels QA shipments.
  /// It prevents an operator from mistaking a generic debug build for the
  /// disposable local acceptance environment.
  static void requireExplicitLocalWarehouseE2e() {
    if (!isExplicitLocalWarehouseE2e) {
      throw StateError(
        'Warehouse E2E requires BLOCKATIE_QA_ENVIRONMENT='
        '$localWarehouseE2eEnvironment and a local '
        'BLOCKATIE_QA_API_BASE_URL.',
      );
    }
  }

  static void logActiveEnvironment() {
    if (kDebugMode) {
      final uri = Uri.parse(baseUrl);
      debugPrint(
        '[OIIAX] API environment: $environmentLabel '
        '(${uri.scheme}://${uri.authority}${uri.path})',
      );
    }
  }

  @visibleForTesting
  static String resolveBaseUrlForTesting({
    required bool isReleaseBuild,
    required String qaBaseUrl,
  }) =>
      _resolveBaseUrl(
        isReleaseBuild: isReleaseBuild,
        qaBaseUrl: qaBaseUrl,
      );

  @visibleForTesting
  static bool isExplicitLocalWarehouseE2eForTesting({
    required String baseUrl,
    required String environment,
  }) =>
      environment == localWarehouseE2eEnvironment && _isLocalApiUrl(baseUrl);

  static String _resolveBaseUrl({
    required bool isReleaseBuild,
    required String qaBaseUrl,
  }) {
    final override = qaBaseUrl.trim();
    if (isReleaseBuild) {
      if (override.isNotEmpty) {
        throw StateError(
          'A QA API override is not permitted in a release build.',
        );
      }
      return productionBaseUrl;
    }

    if (override.isEmpty) {
      return productionBaseUrl;
    }

    final uri = Uri.tryParse(override);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw ArgumentError.value(
        qaBaseUrl,
        'BLOCKATIE_QA_API_BASE_URL',
        'must be an absolute HTTP(S) services URL without credentials, query, or fragment',
      );
    }

    if (uri.scheme == 'http' && !_isLocalHost(uri.host)) {
      throw ArgumentError.value(
        qaBaseUrl,
        'BLOCKATIE_QA_API_BASE_URL',
        'cleartext HTTP is permitted only for a local emulator/QA host',
      );
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path != '/services') {
      throw ArgumentError.value(
        qaBaseUrl,
        'BLOCKATIE_QA_API_BASE_URL',
        'must end with /services',
      );
    }
    return uri.replace(path: path).toString();
  }

  static bool _isLocalApiUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'http' && _isLocalHost(uri.host);
  }

  static bool _isLocalHost(String host) {
    return const <String>{
      '10.0.2.2',
      '10.0.3.2',
      '127.0.0.1',
      '::1',
      'localhost',
    }.contains(host.toLowerCase());
  }

  static String _endpoint(String path) => '$baseUrl/$path';

  static String get clientlogin => _endpoint('client_login.php');
  static String get clientregister => _endpoint('register_client.php');
  static String get clientPasswordReset =>
      '$baseUrl/api_client_password_reset.php';
  static String get clientEmailVerification =>
      '$baseUrl/api_client_email_verification.php';
  static String get clientSession => _endpoint('api_client_session.php');
  static String get profileInfo => _endpoint('client_profile.php');
  static String get clientStatistics => _endpoint('get_statistics.php');
  static String get updateClientProfile => _endpoint('update_client_info.php');
  static String get clientWithdrawalRequests => _endpoint('api_requests.php');
  static String get clientAddWithdrawalRequest =>
      '$baseUrl/api_add_withdrawal_request.php';
  static String get getNotificatios => _endpoint('get_notifications.php');
  static String get readNotification => _endpoint('api_read_notification.php');
  static String get updateClientFcmToken =>
      '$baseUrl/api_update_client_fcm_token.php';
  static String get getInAppNotifications =>
      '$baseUrl/api_get_in_app_notifications.php';
  static String get acknowledgeNotification =>
      '$baseUrl/api_acknowledge_notification.php';
  static String get getClientShipments => _endpoint('api_shipments.php');
  static String get getClientShipmentInstant =>
      '$baseUrl/api_shipments_instant.php';
  static String get acceptShipment => _endpoint('accept_shipment_driver.php');
  static String get markAsReceive => _endpoint('mark_as_arrived_driver.php');
  static String get completeShipment => '$baseUrl/complete_shipment_driver.php';
  static String get cancelShipment => _endpoint('api_cancel_shipment.php');
  static String get shipmentActionReasons =>
      '$baseUrl/api_shipment_action_reasons.php';

  // Order Details URL
  static String get getOrderDetails => _endpoint('api_order_details.php');

  // Balance History URLs
  static String get getBalanceHistory => _endpoint('api_balance_history.php');
  static String get getTransactionDetails =>
      '$baseUrl/api_transaction_details.php';

  // Status Configuration URL
  static String get getStatusConfig => _endpoint('api_status_config.php');

  // Delivery Types URL
  static String get getDeliveryTypes => _endpoint('api_delivery_types.php');
  static String get getRegions => _endpoint('api_regions.php');
  static String get createClientShipment =>
      '$baseUrl/api_add_shipment_from_client.php';
  static String get clientShipmentQuote =>
      '$baseUrl/api_client_shipment_quote.php';

  // Delete Account URL
  static String get deleteAccount => _endpoint('api_delete_account_client.php');
  static String get blockatieProPackages => _endpoint('api_packages.php');
  static String get clientRating => _endpoint('api_client_rating.php');
  static String get addDriverReview => _endpoint('api_add_driver_review.php');
  static String get clientChat => _endpoint('api_client_chat.php');
  static String get clientStatements => _endpoint('api_client_statements.php');
  static String get clientStatementDetails =>
      '$baseUrl/api_client_statement_details.php';
  static String get clientFinancialSummary =>
      '$baseUrl/api_client_financial_summary.php';
  static String get clientStatementPdf =>
      '$baseUrl/api_client_statement_pdf.php';

  // get product type
  static String get getProductType => _endpoint('api_product_type.php');
  static String get getDrivers => _endpoint('api_drivers.php');
  static String get getStatusShipment => _endpoint('api_order_status.php');
  static String get shipmentFilter => _endpoint('shipment_filter.php');
}
