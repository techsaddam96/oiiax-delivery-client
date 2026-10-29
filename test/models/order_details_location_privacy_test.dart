import 'dart:io';

import 'package:blockatie/models/order_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy order-details payload defaults driver location to unavailable', () {
    final driver = Driver.fromJson(const {'id': 9});

    expect(driver.locationState, 'unavailable');
    expect(driver.latitude, isEmpty);
    expect(driver.longitude, isEmpty);
  });

  test('order-details payload preserves the server location-state contract', () {
    final live = Driver.fromJson(const {
      'id': 9,
      'latitude': '31.9539',
      'longitude': '35.9106',
      'location_state': 'live',
    });
    final stale = Driver.fromJson(const {
      'id': 9,
      'latitude': null,
      'longitude': null,
      'location_state': 'stale',
    });

    expect(live.locationState, 'live');
    expect(stale.locationState, 'stale');
    expect(stale.latitude, isEmpty);
    expect(stale.longitude, isEmpty);
  });

  test('tracking screen makes no third-party route request or ETA claim', () {
    final source = File('lib/views/pages/orders/order_details.dart')
        .readAsStringSync();

    expect(source, isNot(contains('router.project-osrm.org')));
    expect(source, isNot(contains("package:http/http.dart")));
    expect(source, isNot(contains('_estimatedTime')));
    expect(source, contains('_routePoints = [widget.targetLocation, widget.driverLocation]'));
    expect(source, contains(r'Direct distance: $_distance'));
  });

  test('tracking is guarded by a live location state before using coordinates', () {
    final source = File('lib/views/pages/orders/order_details.dart')
        .readAsStringSync();

    expect(source, contains("if (driver.locationState != 'live') return false;"));
    expect(source, contains("if (driver.locationState == 'stale')"));
  });
}

