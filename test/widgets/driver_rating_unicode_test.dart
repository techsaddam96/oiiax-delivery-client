import 'dart:async';

import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/widgets/driver_rating/driver_rating_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _success = DriverRatingSubmissionResult(
  success: true,
  message: 'تم إرسال تقييم السائق بنجاح.',
  code: 'DRIVER_REVIEW_CREATED',
  shipmentId: 41,
  driverId: 9,
  rating: 5,
);

Future<void> _openRating(
  WidgetTester tester, {
  Future<DriverRatingSubmissionResult> Function(int, String)? submit,
  void Function(DriverRatingBottomSheetResult?)? onResult,
}) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Builder(builder: (context) {
      return TextButton(
        onPressed: () async {
          final result =
              await showModalBottomSheet<DriverRatingBottomSheetResult>(
            context: context,
            isScrollControlled: true,
            builder: (_) => DriverRatingBottomSheet(
              driverName: 'سائق تجريبي',
              driverAvatar: null,
              onSubmit: submit ?? (_, __) async => _success,
            ),
          );
          onResult?.call(result);
        },
        child: const Text('Open rating'),
      );
    })),
  ));
  await tester.tap(find.text('Open rating'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.changeLanguage(AppLocalizations.arabic);
  });

  final comments = <String, String>{
    'Arabic': 'التوصيل ممتاز والسائق ملتزم',
    'English': 'Excellent delivery and helpful driver',
    'mixed': 'التوصيل ممتاز Excellent delivery 123',
    'numbers': '1234567890 ٠١٢٣٤٥٦٧٨٩',
    'punctuation': 'ممتاز! شكراً، هل وصل؟ (نعم) #5 / + - .',
    'multiline Arabic': 'التوصيل ممتاز\nوالسائق ملتزم',
    'Unicode diacritics and emoji': 'شُكْرًا جَزِيلًا 👨‍👩‍👧‍👦 👍🏽',
  };
  for (final entry in comments.entries) {
    testWidgets('${entry.key} survives editing and reaches submit unchanged',
        (tester) async {
      String? sent;
      await _openRating(tester, submit: (_, comment) async {
        sent = comment;
        return _success;
      });
      await tester.enterText(find.byType(TextField), entry.value);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, entry.value);
      expect(field.maxLength, 500);
      expect(field.maxLines, greaterThan(1));
      expect(find.text('${entry.value.characters.length}/500'), findsOneWidget);
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      await tester.tap(find.text('إرسال التقييم'));
      await tester.pumpAndSettle();
      expect(sent, entry.value);
    });
  }

  testWidgets('length limit counts Arabic graphemes without splitting marks',
      (tester) async {
    await _openRating(tester);
    final comment = List.filled(501, 'عَ').join();
    await tester.enterText(find.byType(TextField), comment);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        List.filled(500, 'عَ').join());
    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets('empty optional comment can submit and Arabic result survives',
      (tester) async {
    String? sent;
    DriverRatingBottomSheetResult? result;
    await _openRating(tester,
        submit: (_, comment) async {
          sent = comment;
          return _success;
        },
        onResult: (value) => result = value);
    await tester.tap(find.byType(IconButton).last);
    await tester.pump();
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pumpAndSettle();
    expect(sent, '');
    expect(result?.message, _success.message);
  });

  testWidgets('Arabic app uses RTL without losing mixed text', (tester) async {
    await _openRating(tester);
    expect(Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.rtl);
    await tester.enterText(find.byType(TextField), 'وصل Order 123 بنجاح');
    await tester.pump();
    expect(Directionality.of(tester.element(find.byType(EditableText))),
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English app permits Arabic with existing LTR direction',
      (tester) async {
    await AppLocalizations.changeLanguage(AppLocalizations.english);
    await _openRating(tester);
    await tester.enterText(find.byType(TextField), 'شكراً للسائق');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'شكراً للسائق');
    expect(Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.ltr);
  });

  for (final code in ['SHIPMENT_FORBIDDEN', 'DRIVER_ALREADY_RATED']) {
    testWidgets('$code keeps comment visible and does not report success',
        (tester) async {
      await _openRating(tester,
          submit: (_, __) async => DriverRatingSubmissionResult(
                success: false,
                message: 'تعذر إرسال التقييم التجريبي',
                code: code,
              ));
      await tester.enterText(find.byType(TextField), 'التوصيل ممتاز');
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      await tester.tap(find.text('إرسال التقييم'));
      await tester.pumpAndSettle();
      expect(find.text('تعذر إرسال التقييم التجريبي'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'التوصيل ممتاز');
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull);
    });
  }

  testWidgets('double submit is blocked while saving', (tester) async {
    final result = Completer<DriverRatingSubmissionResult>();
    var calls = 0;
    await _openRating(tester, submit: (_, __) {
      calls++;
      return result.future;
    });
    await tester.tap(find.byType(IconButton).last);
    await tester.pump();
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    result.complete(_success);
    await tester.pumpAndSettle();
  });
}
