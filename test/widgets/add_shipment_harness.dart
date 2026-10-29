import 'dart:async';

import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/models/productsType_model.dart';
import 'package:blockatie/provider/add_shipment_provider.dart';
import 'package:blockatie/provider/bottom_nav.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/services/regions_service.dart';
import 'package:blockatie/services/shipment_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/add_shipment/add_shipment.dart';
import 'package:blockatie/views/pages/add_shipment/add_shipment_reference_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed option lists, so the page renders without the network.
class FixedReferenceData extends AddShipmentReferenceData {
  const FixedReferenceData();

  @override
  Future<void> load({required bool force}) async {}

  @override
  List<Region> get regions => [
        Region(
            id: 11,
            enregion: 'Abdali',
            anregion: 'العبدلي',
            idDrivers: 0,
            status: 0,
            idcity: 1),
        Region(
            id: 12,
            enregion: 'Downtown',
            anregion: 'وسط البلد',
            idDrivers: 0,
            status: 0,
            idcity: 1),
      ];

  @override
  List<Map<String, dynamic>> get deliveryTypes => const [
        {
          'id': '1',
          'type_name_en': 'Instant',
          'type_name_ar': 'فوري',
          'description_en': 'Deliver immediately.',
          'description_ar': 'تسليم مباشر.',
        },
        {
          'id': '2',
          'type_name_en': 'Scheduled',
          'type_name_ar': 'مجدول',
          'description_en': 'Set a date and time.',
          'description_ar': 'حدد موعداً.',
        },
      ];
}

/// Records what the page hands to the provider instead of calling the API.
class RecordingAddShipmentProvider extends AddShipmentProvider {
  RecordingAddShipmentProvider() {
    productsType = ProductsTypeData.fromJson({
      'status': 'success',
      'message': '',
      'products_types': [
        {
          'id': '1',
          'type_name_en': 'Fragile',
          'type_name_ar': 'قابل للكسر',
          'description_en': 'Handle with care',
          'description_ar': 'يُعامل بعناية',
        },
        {
          'id': '2',
          'type_name_en': 'Non-fragile',
          'type_name_ar': 'غير قابل للكسر',
          'description_en': 'Regular parcel',
          'description_ar': 'طرد عادي',
        },
      ],
    });
  }

  final List<Map<String, Object?>> calls = [];
  Completer<bool>? gate;
  Object? failWith;
  bool _busy = false;

  @override
  bool get isSubmitting => _busy;

  @override
  Future<bool> addShipment({
    required String recipientName,
    required String recipientPhone,
    required int regionId,
    required String deliveryAddress,
    required String shipmentCost,
    required int productTypeId,
    required int deliveryTypeId,
    required DateTime shipmentDate,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? reference,
    int? piecesCount,
    String? note,
    String paymentType = 'cod',
    double? quotedDeliveryCost,
  }) async {
    if (_busy) {
      return false;
    }
    _busy = true;
    notifyListeners();
    calls.add({
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'regionId': regionId,
      'deliveryAddress': deliveryAddress,
      'shipmentCost': shipmentCost,
      'productTypeId': productTypeId,
      'deliveryTypeId': deliveryTypeId,
      'shipmentDate': shipmentDate,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'reference': reference,
      'piecesCount': piecesCount,
      'note': note,
      'paymentType': paymentType,
      'quotedDeliveryCost': quotedDeliveryCost,
    });
    try {
      if (gate != null) {
        await gate!.future;
      }
      if (failWith != null) {
        throw failWith!;
      }
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

class QuietShipments extends ShipmentProvider {
  @override
  Future<void> getClientShipments(
      {bool force = false, bool silent = false}) async {}
}

class QuietInstantShipments extends ShipmentInstantprovider {
  @override
  Future<void> getShipmentsInstant(
      {bool force = false, bool silent = false}) async {}
}

const double kNavBarHeight = 110;

class Harness {
  Harness({
    this.arabic = true,
    this.instantAccess = true,
    DeliveryQuoteLoader? quoteLoader,
  }) : quoteLoader = quoteLoader ?? defaultQuoteLoader;

  final bool arabic;
  final bool instantAccess;
  final DeliveryQuoteLoader quoteLoader;
  final provider = RecordingAddShipmentProvider();

  static Future<DeliveryQuote> defaultQuoteLoader({
    required int regionId,
    required int deliveryTypeId,
  }) async => DeliveryQuote(
        regionId: regionId,
        cityId: 1,
        deliveryTypeId: deliveryTypeId,
        deliveryCost: regionId == 11 ? 1.5 : 2.0,
        currency: 'JOD',
      );

  /// The app shell around the page: the real CustomBottomNavBar does not
  /// resize for the keyboard and extends its body behind a floating nav bar.
  Widget build() {
    final profile = ProfileProvider()
      ..profileInfo = ClientInfo.fromJson({
        'id': 1,
        'nclient': 'QA owner',
        'nstore': 'QA store',
        'phclient': '0790000000',
        'lclient': 'QA address',
        'subscription': instantAccess ? 1 : 0,
      });
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AddShipmentProvider>.value(value: provider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ChangeNotifierProvider<ShipmentProvider>(
            create: (_) => QuietShipments()),
        ChangeNotifierProvider<ShipmentInstantprovider>(
            create: (_) => QuietInstantShipments()),
        ChangeNotifierProvider<BottomNavProvider>(
            create: (_) => BottomNavProvider()),
      ],
      child: MaterialApp(
        navigatorKey: Nav.key,
        locale: arabic ? AppLocalizations.arabic : AppLocalizations.english,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: Stack(
            children: [
              AddShipmentPage(
                referenceData: FixedReferenceData(),
                quoteLoader: quoteLoader,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              key: const Key('shellNav'),
              height: kNavBarHeight,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Future<Harness> pumpPage(
  WidgetTester tester, {
  bool arabic = true,
  bool instantAccess = true,
  Size size = const Size(393, 852),
  DeliveryQuoteLoader? quoteLoader,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() => AppLocalizations.changeLanguage(
      arabic ? AppLocalizations.arabic : AppLocalizations.english));
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
  addTearDown(tester.view.reset);
  final harness = Harness(
    arabic: arabic,
    instantAccess: instantAccess,
    quoteLoader: quoteLoader,
  );
  await tester.pumpWidget(harness.build());
  await tester.pumpAndSettle();
  return harness;
}

/// Opens a soft keyboard of [height] logical pixels (devicePixelRatio is 1).
Future<void> openKeyboard(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  // Android reports no bottom system padding while the keyboard is up.
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 0);
  await tester.pumpAndSettle();
}

Future<void> closeKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = FakeViewPadding.zero;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
  await tester.pumpAndSettle();
}
