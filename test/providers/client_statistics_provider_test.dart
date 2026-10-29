import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/services/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> wallet({String balance = '96.99 JOD'}) => {
      'shipments': 10,
      'shipments_in_progress': 10,
      'shipments_delivered': 0,
      'cancelled_shipments': 0,
      'wallet_version': 1,
      'balance_total': balance,
      'final_total_value_order': '0.00 JOD',
      'total_required': '0.00 JOD',
      'withdrawable_balance': '0.00',
      'reserved_withdrawals': '0.00',
      'wallet_review_required': false,
      'currency': 'JOD',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StatisticsAdapter adapter;
  late ProfileProvider provider;
  late ClientSession session;

  setUp(() {
    session = const ClientSession(clientId: '12', apiKey: 'test-key');
    adapter = StatisticsAdapter();
    provider = ProfileProvider(
      statisticsDio: Dio()..httpClientAdapter = adapter,
      statisticsSessionReader: () async => session,
    );
  });
  tearDown(() => provider.dispose());

  test('home and wallet share one in-flight request and exact server totals',
      () async {
    final first = provider.fetchClientStatistics();
    final second = provider.fetchClientStatistics();
    expect(identical(first, second), isTrue);
    expect(provider.isLoadingStatistics, isTrue);
    await adapter.started.future;
    expect(adapter.requests, hasLength(1));
    adapter.reply(wallet());
    await Future.wait([first, second]);
    expect(provider.statistics!.balanceTotal, '96.99 JOD');
    expect(provider.statistics!.availableForWithdrawal, 0);
    expect(provider.statistics!.shipments, 10);
    expect(provider.isLoadingStatistics, isFalse);
    expect(provider.statisticsError, isNull);
    expect(adapter.requests.single.headers['X-API-KEY'], 'test-key');
    expect(adapter.requests.single.headers['Cache-Control'], 'no-cache');
  });

  test('a later refresh replaces the shared snapshot, not a second cache',
      () async {
    adapter.reply(wallet());
    await provider.fetchClientStatistics();
    adapter.nextResponse();
    final refresh = provider.fetchClientStatistics();
    expect(provider.statistics, isNull);
    final changed = wallet(balance: '87.99 JOD')
      ..['final_total_value_order'] = '9.00 JOD'
      ..['withdrawable_balance'] = '9.00';
    adapter.reply(changed);
    await refresh;
    expect(adapter.requests, hasLength(2));
    expect(provider.statistics!.balanceTotal, '87.99 JOD');
    expect(provider.statistics!.availableForWithdrawal, 9);
  });

  test('failed refresh does not leave stale spendable money', () async {
    adapter.reply(wallet()..['withdrawable_balance'] = '9.00');
    await provider.fetchClientStatistics();
    adapter.nextResponse();
    adapter.reply({}, status: 503);
    await provider.fetchClientStatistics();
    expect(provider.statistics, isNull);
    expect(provider.statisticsError, isNotEmpty);
    expect(provider.isLoadingStatistics, isFalse);
  });

  test('missing session clears old totals and sends no unauthenticated request',
      () async {
    adapter.reply(wallet());
    await provider.fetchClientStatistics();
    session = const ClientSession(clientId: null, apiKey: null);
    await provider.fetchClientStatistics();
    expect(provider.statistics, isNull);
    expect(provider.statisticsError, isNotEmpty);
    expect(adapter.requests, hasLength(1));
  });

  test('response from an old login cannot populate the new account', () async {
    final pending = provider.fetchClientStatistics();
    await adapter.started.future;
    session = const ClientSession(clientId: '99', apiKey: 'another-test-key');
    adapter.reply(wallet());
    await pending;
    expect(provider.statistics, isNull);
    expect(provider.statisticsError, isNotEmpty);
  });

  test('statistics cannot silently invent zero totals for an incomplete API',
      () async {
    adapter.reply({'shipments': 10, 'balance_total': '96.99 JOD'});
    await provider.fetchClientStatistics();
    expect(provider.statistics, isNull);
    expect(provider.statisticsError, isNotEmpty);
  });

  test('review-required funds stay unavailable', () async {
    adapter.reply(wallet()
      ..['wallet_review_required'] = true
      ..['withdrawable_balance'] = '9.00');
    await provider.fetchClientStatistics();
    expect(provider.statistics!.availableForWithdrawal, isNull);
  });

  test('dispose during a request never notifies a disposed provider', () async {
    final disposableAdapter = StatisticsAdapter();
    final disposable = ProfileProvider(
      statisticsDio: Dio()..httpClientAdapter = disposableAdapter,
      statisticsSessionReader: () async => session,
    );
    final pending = disposable.fetchClientStatistics();
    await disposableAdapter.started.future;
    disposable.dispose();
    disposableAdapter.reply(wallet());
    await pending;
    expect(disposable.statistics, isNull);
  });
}

class StatisticsAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final started = Completer<void>();
  Completer<ResponseBody> _response = Completer<ResponseBody>();

  void nextResponse() => _response = Completer<ResponseBody>();

  void reply(Map<String, dynamic> data, {int status = 200}) {
    _response.complete(ResponseBody.fromString(
      jsonEncode({'success': status == 200, 'data': data}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    ));
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    if (!started.isCompleted) started.complete();
    return _response.future;
  }

  @override
  void close({bool force = false}) {}
}
