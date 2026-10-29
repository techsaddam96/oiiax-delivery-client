import 'dart:async';

import 'package:blockatie/services/shipment_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'add_shipment_harness.dart';

// ---------------------------------------------------------------- helpers

Finder byKey(String key) => find.byKey(Key(key));

Future<void> tapPrimary(WidgetTester tester) async {
  await tester.tap(byKey('addShipmentPrimary'));
  await tester.pumpAndSettle();
}

Future<void> tapBack(WidgetTester tester) async {
  await tester.tap(byKey('addShipmentBack'));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(byKey(key));
  await tester.enterText(byKey(key), text);
  await tester.pump();
}

String fieldText(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(byKey(key)).controller!.text;

FocusNode focusOf(WidgetTester tester, String key) => tester
    .widget<EditableText>(
        find.descendant(of: byKey(key), matching: find.byType(EditableText)))
    .focusNode;

Future<void> fillRecipient(WidgetTester tester,
    {String name = 'سامي الأحمد', String phone = '0791234567'}) async {
  await enter(tester, 'recipientName', name);
  await enter(tester, 'recipientPhone', phone);
}

Future<void> pickArea(WidgetTester tester, int id) async {
  await tester.ensureVisible(byKey('areaSelector'));
  await tester.tap(byKey('areaSelector'));
  await tester.pumpAndSettle();
  await tester.tap(byKey('area_$id'));
  await tester.pumpAndSettle();
}

/// Recipient → Location → Shipment → Payment, landing on Review.
Future<void> completeToReview(WidgetTester tester,
    {bool prepaid = false, String amount = '15'}) async {
  await fillRecipient(tester);
  await tapPrimary(tester);
  await pickArea(tester, 11);
  await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
  await tapPrimary(tester);
  await tapPrimary(tester); // shipment step: the preselected defaults are valid
  if (prepaid) {
    await tester.tap(byKey('paymentPrepaid'));
    await tester.pumpAndSettle();
  } else {
    await enter(tester, 'codAmount', amount);
  }
  await tapPrimary(tester);
}

double ctaBottom(WidgetTester tester) =>
    tester.getRect(byKey('addShipmentCta')).bottom;

void main() {
  testWidgets('1. the screen opens on the recipient step (Arabic)',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('إضافة شحنة'), findsOneWidget);
    expect(find.text('بيانات المستلم'), findsOneWidget);
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(find.text('متابعة'), findsOneWidget);
    expect(byKey('recipientName'), findsOneWidget);
    expect(byKey('addShipmentBack'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2. recipient name is validated inline and focused',
      (tester) async {
    await pumpPage(tester);
    await tapPrimary(tester);
    expect(find.text('اسم المستلم مطلوب.'), findsOneWidget);
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(focusOf(tester, 'recipientName').hasFocus, isTrue);
  });

  testWidgets('3. phone is validated with the Jordan mobile rule',
      (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester, phone: '0612345678');
    await tapPrimary(tester);
    expect(find.text('استخدم رقم هاتف أردني صالح يبدأ بـ 077 أو 078 أو 079.'),
        findsOneWidget);
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(focusOf(tester, 'recipientPhone').hasFocus, isTrue);
  });

  testWidgets('4. Continue advances and the recipient collapses to a summary',
      (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);
    expect(byKey('areaSelector'), findsOneWidget);
    expect(byKey('recipientName'), findsNothing);
    expect(find.textContaining('سامي الأحمد'), findsOneWidget);
  });

  testWidgets('5. Previous keeps the recipient values', (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await tapBack(tester);
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(fieldText(tester, 'recipientName'), 'سامي الأحمد');
    expect(fieldText(tester, 'recipientPhone'), '0791234567');
  });

  testWidgets('6. the chosen area persists across steps', (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await pickArea(tester, 12);
    expect(find.text('وسط البلد'), findsOneWidget);
    await tapBack(tester);
    await tapPrimary(tester);
    expect(find.text('وسط البلد'), findsOneWidget);
  });

  testWidgets('7. the address persists when going back from the next step',
      (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
    await tapPrimary(tester);
    expect(find.text('الخطوة 3 من 5'), findsOneWidget);
    await tapBack(tester);
    expect(fieldText(tester, 'deliveryAddress'), 'شارع الرينبو، بناية 12');
  });

  testWidgets(
      '8-9. payment cards switch, and the COD amount shows only for COD',
      (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
    await tapPrimary(tester);
    await tapPrimary(tester);
    expect(find.text('الخطوة 4 من 5'), findsOneWidget);
    expect(byKey('codAmount'), findsOneWidget);

    await tester.tap(byKey('paymentPrepaid'));
    await tester.pumpAndSettle();
    expect(byKey('codAmount'), findsNothing);
    expect(find.textContaining('دفع العميل للتاجر مسبقاً'), findsOneWidget);

    await tester.tap(byKey('paymentCod'));
    await tester.pumpAndSettle();
    expect(byKey('codAmount'), findsOneWidget);
    expect(fieldText(tester, 'codAmount'), '');

    await tapPrimary(tester);
    expect(find.text('قيمة الشحنة مطلوبة.'), findsOneWidget);
    expect(focusOf(tester, 'codAmount').hasFocus, isTrue);
  });

  testWidgets('10. the review reflects every entered value', (tester) async {
    await pumpPage(tester);
    await completeToReview(tester, amount: '15');
    expect(find.text('الخطوة 5 من 5'), findsOneWidget);
    expect(find.text('إنشاء الشحنة'), findsOneWidget);
    for (final text in [
      'سامي الأحمد',
      '0791234567',
      'العبدلي',
      'شارع الرينبو، بناية 12',
      'فوري',
      'قابل للكسر',
      'الدفع عند الاستلام',
      '15 د.أ',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('تعديل'), findsNWidgets(4));
  });

  testWidgets('10b. the merchant sees the authoritative quote before submit',
      (tester) async {
    final harness = await pumpPage(tester, arabic: false);
    await fillRecipient(tester, name: 'Sam', phone: '0791234567');
    await tapPrimary(tester);
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'Rainbow Street, Building 12');
    await tapPrimary(tester);
    await tapPrimary(tester);

    expect(find.text('1.50 JOD · Abdali'), findsOneWidget);
    await enter(tester, 'codAmount', '15');
    await tapPrimary(tester);
    await tapPrimary(tester);

    expect(harness.provider.calls.single['quotedDeliveryCost'], 1.5);
    expect(find.text('1.50 JOD · Abdali'), findsOneWidget);
  });

  testWidgets('10c. a stale quote response cannot overwrite a newer area',
      (tester) async {
    final firstQuote = Completer<DeliveryQuote>();
    final secondQuote = Completer<DeliveryQuote>();
    final loader = ({required int regionId, required int deliveryTypeId}) {
      return regionId == 11 ? firstQuote.future : secondQuote.future;
    };
    await pumpPage(tester, arabic: false, quoteLoader: loader);
    await fillRecipient(tester, name: 'Sam', phone: '0791234567');
    await tapPrimary(tester);

    await tester.tap(byKey('areaSelector'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('area_11'));
    await tester.pump();
    await tester.tap(byKey('areaSelector'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('area_12'));
    await tester.pump();

    firstQuote.complete(const DeliveryQuote(
      regionId: 11,
      cityId: 1,
      deliveryTypeId: 1,
      deliveryCost: 1.5,
      currency: 'JOD',
    ));
    await tester.pump();
    expect(find.textContaining('Calculating the delivery price'), findsOneWidget);

    secondQuote.complete(const DeliveryQuote(
      regionId: 12,
      cityId: 1,
      deliveryTypeId: 1,
      deliveryCost: 2.0,
      currency: 'JOD',
    ));
    await tester.pump();
    expect(find.text('2.00 JOD · Downtown'), findsOneWidget);
    expect(find.textContaining('1.50 JOD'), findsNothing);
  });

  testWidgets('10d. an unavailable quote blocks creation without a fallback',
      (tester) async {
    Future<DeliveryQuote> unavailable({
      required int regionId,
      required int deliveryTypeId,
    }) async {
      throw const ShipmentServiceException(
        code: 'DELIVERY_PRICE_UNAVAILABLE',
        messageEn: 'Delivery price is not configured for the selected area.',
        messageAr: 'سعر التوصيل غير مُعد للمنطقة المختارة.',
      );
    }

    final harness = await pumpPage(tester, quoteLoader: unavailable);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
    await tapPrimary(tester);
    await tapPrimary(tester);
    await enter(tester, 'codAmount', '15');
    await tapPrimary(tester);
    await tapPrimary(tester);

    expect(harness.provider.calls, isEmpty);
    expect(find.text('سعر التوصيل غير مُعد للمنطقة المختارة.'), findsWidgets);
  });

  testWidgets('11. the provider receives the same contract as before (COD)',
      (tester) async {
    final harness = await pumpPage(tester);
    await fillRecipient(tester, phone: '+962 79 123 4567');
    await tapPrimary(tester);
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', '  شارع الرينبو، بناية 12  ');
    await tapPrimary(tester);
    await tapPrimary(tester);
    await enter(tester, 'codAmount', '15.5');
    await tapPrimary(tester);
    await tapPrimary(tester);

    expect(harness.provider.calls, hasLength(1));
    final call = harness.provider.calls.single;
    expect(call['recipientName'], 'سامي الأحمد');
    expect(call['recipientPhone'], '0791234567');
    expect(call['regionId'], 11);
    expect(call['deliveryAddress'], 'شارع الرينبو، بناية 12');
    expect(call['shipmentCost'], '15.5');
    expect(call['productTypeId'], 1);
    expect(call['deliveryTypeId'], 1);
    expect(call['paymentType'], 'cod');
    expect(call['deliveryLatitude'], isNull);
    expect(call['deliveryLongitude'], isNull);
    expect(call['reference'], isNull);
    expect(call['piecesCount'], isNull);
    expect(call['note'], isNull);
    expect(call['shipmentDate'], isA<DateTime>());
    expect(find.text('تم إنشاء الشحنة'), findsOneWidget);
  });

  testWidgets('11b. prepaid still sends 0 and "prepaid"; optional fields kept',
      (tester) async {
    final harness = await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await pickArea(tester, 12);
    await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
    await tapPrimary(tester);
    await tester.ensureVisible(byKey('chip_2'));
    await tester.tap(byKey('chip_2'));
    await tester.ensureVisible(byKey('choice_2'));
    await tester.tap(byKey('choice_2'));
    await tester.pumpAndSettle();
    await enter(tester, 'shipmentNote', 'اتصل قبل الوصول');
    await tester.ensureVisible(byKey('moreDetailsToggle'));
    await tester.tap(byKey('moreDetailsToggle'));
    await tester.pumpAndSettle();
    await enter(tester, 'reference', 'ORD-77');
    await enter(tester, 'piecesCount', '3');
    await tapPrimary(tester);
    await tester.tap(byKey('paymentPrepaid'));
    await tester.pumpAndSettle();
    await tapPrimary(tester);
    await tapPrimary(tester);

    final call = harness.provider.calls.single;
    expect(call['paymentType'], 'prepaid');
    expect(call['shipmentCost'], '0');
    expect(call['regionId'], 12);
    expect(call['productTypeId'], 2);
    expect(call['deliveryTypeId'], 2);
    expect(call['reference'], 'ORD-77');
    expect(call['piecesCount'], 3);
    expect(call['note'], 'اتصل قبل الوصول');
  });

  testWidgets(
      '12. keyboard inset is applied once: no blank band above the keyboard',
      (tester) async {
    await pumpPage(tester);
    // Closed: the actions sit above the shell's floating nav bar.
    final closedBottom = ctaBottom(tester);
    expect(closedBottom, lessThanOrEqualTo(852 - kNavBarHeight));

    await tester.tap(byKey('recipientName'));
    await openKeyboard(tester, 300);
    const keyboardTop = 852.0 - 300;
    expect(keyboardTop - ctaBottom(tester), inInclusiveRange(0, 1),
        reason: 'the bottom actions sit directly on the keyboard');
    final scroll =
        tester.widget<SingleChildScrollView>(byKey('addShipmentScroll'));
    expect((scroll.padding! as EdgeInsets).bottom, lessThan(24),
        reason: 'no keyboard height added to the scroll padding');
    final field = tester.getRect(byKey('recipientName'));
    expect(field.bottom, lessThan(tester.getRect(byKey('addShipmentCta')).top));

    await closeKeyboard(tester);
    expect(ctaBottom(tester), closedBottom);
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(393, 852)]) {
    testWidgets(
        '13. ${size.width.toInt()}x${size.height.toInt()}: each field stays '
        'visible above the keyboard, no overflow', (tester) async {
      await pumpPage(tester, size: size);
      final keyboard = (size.height * 0.42).roundToDouble();
      Future<void> focusAndCheck(String key) async {
        await tester.ensureVisible(byKey(key));
        await tester.tap(byKey(key));
        await openKeyboard(tester, keyboard);
        final input = tester.getRect(find.descendant(
            of: byKey(key), matching: find.byType(EditableText)));
        final ctaTop = tester.getRect(byKey('addShipmentCta')).top;
        expect(
            size.height - keyboard - ctaBottom(tester), inInclusiveRange(0, 1),
            reason: '$key: no gap between the actions and the keyboard');
        // The text being typed is fully on screen: below the status bar and
        // above the actions (multi-line fields: at least their first line).
        expect(input.top, greaterThanOrEqualTo(24), reason: '$key top');
        final lineBottom = input.top + 24;
        expect(lineBottom, lessThanOrEqualTo(ctaTop), reason: '$key line');
        if (tester
                .widget<EditableText>(find.descendant(
                    of: byKey(key), matching: find.byType(EditableText)))
                .maxLines ==
            1) {
          expect(input.bottom, lessThanOrEqualTo(ctaTop),
              reason: '$key fully visible');
        }
        await closeKeyboard(tester);
      }

      await focusAndCheck('recipientName');
      await focusAndCheck('recipientPhone');
      await fillRecipient(tester);
      await tapPrimary(tester);
      await pickArea(tester, 11);
      await focusAndCheck('deliveryAddress');
      await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
      await tapPrimary(tester);
      await focusAndCheck('shipmentNote');
      await tapPrimary(tester);
      await focusAndCheck('codAmount');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      '13b. keyboard opened and closed repeatedly, step changed while open',
      (tester) async {
    await pumpPage(tester);
    final closedBottom = ctaBottom(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(byKey('recipientName'));
      await openKeyboard(tester, 280);
      await closeKeyboard(tester);
      expect(ctaBottom(tester), closedBottom);
    }
    await fillRecipient(tester);
    await tester.tap(byKey('recipientPhone'));
    await openKeyboard(tester, 280);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('14. a missing area is revealed, a short address is focused',
      (tester) async {
    await pumpPage(tester);
    await fillRecipient(tester);
    await tapPrimary(tester);
    await tapPrimary(tester);
    expect(find.text('يرجى اختيار منطقة التوصيل.'), findsOneWidget);
    expect(find.text('الخطوة 2 من 5'), findsOneWidget);

    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'قصير');
    await tapPrimary(tester);
    expect(find.text('يرجى إدخال عنوان توصيل أكثر تفصيلاً.'), findsOneWidget);
    expect(focusOf(tester, 'deliveryAddress').hasFocus, isTrue);
  });

  testWidgets('14b. editing from the review returns to the review',
      (tester) async {
    await pumpPage(tester);
    await completeToReview(tester);
    await tester.tap(find.text('تعديل').first);
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 1 من 5'), findsOneWidget);
    expect(find.text('حفظ والعودة للمراجعة'), findsOneWidget);
    await enter(tester, 'recipientName', 'سامي محمد');
    await tapPrimary(tester);
    expect(find.text('الخطوة 5 من 5'), findsOneWidget);
    expect(find.text('سامي محمد'), findsOneWidget);
  });

  testWidgets('15. Arabic renders right-to-left', (tester) async {
    await pumpPage(tester);
    expect(Directionality.of(tester.element(byKey('recipientName'))),
        TextDirection.rtl);
    final title = tester.getRect(find.text('بيانات المستلم'));
    expect(title.center.dx, greaterThan(393 / 2));
  });

  testWidgets('16. English renders left-to-right with English copy',
      (tester) async {
    final harness = await pumpPage(tester, arabic: false);
    expect(find.text('Add Shipment'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(Directionality.of(tester.element(byKey('recipientName'))),
        TextDirection.ltr);
    final title = tester.getRect(find.text('Recipient').last);
    expect(title.center.dx, lessThan(393 / 2));
    await fillRecipient(tester, name: 'Sami Ahmad');
    await tapPrimary(tester);
    await pickArea(tester, 11);
    expect(find.text('Abdali'), findsOneWidget);
    await enter(tester, 'deliveryAddress', 'Rainbow Street, building 12');
    await tapPrimary(tester);
    await tapPrimary(tester);
    await enter(tester, 'codAmount', '9');
    await tapPrimary(tester);
    expect(find.text('Create Shipment'), findsOneWidget);
    await tapPrimary(tester);
    expect(harness.provider.calls.single['recipientName'], 'Sami Ahmad');
  });

  testWidgets('16b. without instant access only the scheduled type is offered',
      (tester) async {
    final harness = await pumpPage(tester, instantAccess: false);
    await completeToReview(tester);
    expect(find.text('مجدول'), findsWidgets);
    await tapPrimary(tester);
    expect(harness.provider.calls.single['deliveryTypeId'], 2);
  });

  testWidgets('18-19. rapid taps submit once; the button shows loading',
      (tester) async {
    final harness = await pumpPage(tester);
    harness.provider.gate = Completer<bool>();
    await completeToReview(tester);
    await tester.tap(byKey('addShipmentPrimary'));
    await tester.tap(byKey('addShipmentPrimary'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(byKey('addShipmentPrimary'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));

    expect(harness.provider.calls, hasLength(1));
    expect(find.text('جارٍ إنشاء الشحنة...'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(byKey('addShipmentPrimary')).onPressed,
        isNull);
    expect(tester.widget<OutlinedButton>(byKey('addShipmentBack')).onPressed,
        isNull);

    harness.provider.gate!.complete(true);
    await tester.pumpAndSettle();
    expect(harness.provider.calls, hasLength(1));
  });

  testWidgets('20. a backend failure keeps every value and shows the reason',
      (tester) async {
    final harness = await pumpPage(tester);
    harness.provider.failWith = const ShipmentServiceException(
      code: 'INVALID_COST',
      messageEn: 'Enter a valid shipment value.',
      messageAr: 'يرجى إدخال قيمة شحنة صحيحة.',
    );
    await completeToReview(tester);
    await tapPrimary(tester);
    expect(byKey('submitError'), findsOneWidget);
    expect(find.text('يرجى إدخال قيمة شحنة صحيحة.'), findsWidgets);
    expect(find.text('الخطوة 5 من 5'), findsOneWidget);
    expect(find.text('سامي الأحمد'), findsOneWidget);

    await tester.ensureVisible(find.text('تعديل').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل').first);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'recipientName'), 'سامي الأحمد');
    expect(fieldText(tester, 'recipientPhone'), '0791234567');

    harness.provider.failWith = null;
    await tapPrimary(tester); // back to the review
    await tapPrimary(tester); // retry
    expect(harness.provider.calls, hasLength(2));
    expect(find.text('تم إنشاء الشحنة'), findsOneWidget);
  });

  testWidgets('21. 130% text on a 360px phone: whole flow, no overflow',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final harness = await pumpPage(tester, size: const Size(360, 640));
    await completeToReview(tester);
    expect(find.text('الخطوة 5 من 5'), findsOneWidget);
    await tapPrimary(tester);
    expect(harness.provider.calls, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('22. tap targets and labels meet the platform guidelines',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester);
    Future<void> checkGuidelines() async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }

    await checkGuidelines();
    await fillRecipient(tester);
    await tapPrimary(tester);
    await checkGuidelines();
    await pickArea(tester, 11);
    await enter(tester, 'deliveryAddress', 'شارع الرينبو، بناية 12');
    await tapPrimary(tester);
    await checkGuidelines();
    await tapPrimary(tester);
    await checkGuidelines();
    await enter(tester, 'codAmount', '15');
    await tapPrimary(tester);
    await checkGuidelines();
    semantics.dispose();
  });
}
