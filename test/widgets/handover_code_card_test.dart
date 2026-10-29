import 'dart:async';
import 'package:blockatie/services/client_statement_service.dart';
import 'package:blockatie/services/user_session_state.dart';
import 'package:blockatie/views/pages/statements/widgets/handover_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReveal extends ClientStatementService {
  int calls = 0;
  Completer<String> response = Completer<String>();
  @override
  Future<String> revealHandoverCode(int statementId) {
    calls++;
    return response.future;
  }
}

void main() {
  Future<void> mount(WidgetTester tester, FakeReveal service, {bool ar = false}) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: HandoverCodeCard(statementId: 59, ar: ar, service: service))));

  testWidgets('hidden by default, reveal on demand, hide and auto-hide', (tester) async {
    final service = FakeReveal();
    await mount(tester, service);
    expect(service.calls, 0);
    await tester.tap(find.text('Show Handover Code'));
    await tester.pump();
    await tester.tap(find.text('Show Handover Code'));
    expect(service.calls, 1);
    service.response.complete('654321');
    await tester.pump();
    expect(find.text('654321'), findsOneWidget);
    await tester.tap(find.text('Hide code'));
    await tester.pump();
    expect(find.text('654321'), findsNothing);
    await tester.tap(find.text('Show Handover Code'));
    await tester.pump();
    expect(find.text('654321'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('654321'), findsNothing);
  });
  testWidgets('late response after account switch is discarded', (tester) async {
    final service = FakeReveal();
    await mount(tester, service);
    await tester.tap(find.text('Show Handover Code'));
    UserSessionState.reset(SessionResetReason.accountChanged);
    service.response.complete('654321');
    await tester.pump();
    expect(find.text('654321'), findsNothing);
    expect(find.text('Show Handover Code'), findsOneWidget);
  });
  testWidgets('background and logout clear a revealed code', (tester) async {
    final service = FakeReveal()..response.complete('654321');
    await mount(tester, service);
    await tester.tap(find.text('Show Handover Code'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('654321'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.text('Show Handover Code'));
    await tester.pump();
    UserSessionState.reset(SessionResetReason.logout);
    await tester.pump();
    expect(find.text('654321'), findsNothing);
  });
  testWidgets('leaving or covering route forgets the code', (tester) async {
    final service = FakeReveal()..response.complete('654321');
    await mount(tester, service);
    await tester.tap(find.text('Show Handover Code'));
    await tester.pump();
    final context = tester.element(find.byType(HandoverCodeCard));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Other route'))));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Other route'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('654321'), findsNothing);
  });
  testWidgets('disposed request cannot display code; Arabic label supported', (tester) async {
    final service = FakeReveal();
    await mount(tester, service, ar: true);
    await tester.tap(find.text('عرض رمز التسليم'));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    service.response.complete('654321');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('654321'), findsNothing);
  });
  testWidgets('failure displays generic error without code', (tester) async {
    final service = FakeReveal();
    await mount(tester, service);
    await tester.tap(find.text('Show Handover Code'));
    service.response.completeError(const StatementAuthorizationException());
    await tester.pump();
    expect(find.textContaining('Unable to reveal'), findsOneWidget);
    expect(find.text('654321'), findsNothing);
  });
}
