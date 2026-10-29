import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/statements/client_financial_summary.dart';
import 'package:blockatie/models/statements/client_statement.dart';
import 'package:blockatie/models/statements/client_statement_line.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool get _isArabic => AppLocalizations.isArabic;
String _copy(String en, String ar) => _isArabic ? ar : en;

String formatStatementMoney(String value) {
  final amount = num.tryParse(value) ?? 0;
  final formatted =
      NumberFormat('#,##0.00', _isArabic ? 'ar' : 'en').format(amount);
  return _isArabic ? '$formatted د.أ' : 'JOD $formatted';
}

String formatStatementDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('dd/MM/yyyy', _isArabic ? 'ar' : 'en').format(parsed);
}

class StatementStatusBadge extends StatelessWidget {
  const StatementStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final map = <String, ({String en, String ar, Color color})>{
      'approved': (en: 'Approved', ar: 'معتمد', color: const Color(0xff2563EB)),
      'pdf_generated': (
        en: 'Ready',
        ar: 'جاهز',
        color: const Color(0xff7C3AED)
      ),
      'sent': (en: 'Sent', ar: 'تم الإرسال', color: const Color(0xff059669)),
      'partial': (
        en: 'Partially paid',
        ar: 'مسدد جزئياً',
        color: const Color(0xffD97706)
      ),
      'paid': (en: 'Paid', ar: 'مسدد', color: const Color(0xff16A06D)),
    };
    final item =
        map[status] ?? (en: status, ar: status, color: const Color(0xff64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(_isArabic ? item.ar : item.en,
          style: TextStyle(
              color: item.color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({super.key, required this.summary});
  final ClientFinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.gradient1, AppColors.primary],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_copy('Financial summary', 'الملخص المالي'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _SummaryMetric(
                  label: _copy('Net due', 'صافي المستحق'),
                  value: formatStatementMoney(summary.totalStatementsNet))),
          const SizedBox(width: 10),
          Expanded(
              child: _SummaryMetric(
                  label: _copy('Remaining', 'المتبقي'),
                  value: formatStatementMoney(summary.totalRemaining))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _SummaryMetric(
                  label: _copy('Statements', 'عدد الكشوف'),
                  value: '${summary.statementsCount}')),
          const SizedBox(width: 10),
          Expanded(
              child: _SummaryMetric(
                  label: _copy('Open statements', 'الكشوف المفتوحة'),
                  value: '${summary.openStatementsCount}')),
        ]),
      ]),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: .17))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class StatementTile extends StatelessWidget {
  const StatementTile(
      {super.key, required this.statement, required this.onTap});
  final ClientStatement statement;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffE6ECF5))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(13)),
                        child: Icon(Icons.receipt_long_rounded,
                            color: AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_copy('Statement', 'كشف'),
                              style: const TextStyle(
                                  color: Color(0xff64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          Text(
                              statement.statementNumber.isEmpty
                                  ? '—'
                                  : statement.statementNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xff10213C),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ])),
                    StatementStatusBadge(status: statement.status),
                  ]),
                  const SizedBox(height: 13),
                  Text(
                      '${formatStatementDate(statement.periodFrom)}  —  ${formatStatementDate(statement.periodTo)}',
                      style: const TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _Amount(
                            label: _copy('Net due', 'صافي المستحق'),
                            value: formatStatementMoney(statement.netAmount))),
                    Expanded(
                        child: _Amount(
                            label: _copy('Remaining', 'المتبقي'),
                            value: formatStatementMoney(
                                statement.remainingAmount))),
                    Icon(
                        statement.hasPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.chevron_left_rounded,
                        color: statement.hasPdf
                            ? const Color(0xffE53935)
                            : AppColors.primary),
                  ]),
                ]),
          ),
        ),
      );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xff94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xff10213C),
                fontSize: 12,
                fontWeight: FontWeight.w800))
      ]);
}

class StatementLineTile extends StatelessWidget {
  const StatementLineTile({super.key, required this.line});
  final ClientStatementLine line;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE6ECF5))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(
                    line.shipmentReference.isEmpty
                        ? '—'
                        : line.shipmentReference,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff10213C)))),
            Text(formatStatementDate(line.shipmentDate),
                style: const TextStyle(fontSize: 10, color: Color(0xff64748B)))
          ]),
          if (line.shipmentStatus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(line.shipmentStatus,
                style: const TextStyle(fontSize: 11, color: Color(0xff64748B)))
          ],
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
                child: _Amount(
                    label: _copy('Shipment value', 'قيمة الشحنة'),
                    value: formatStatementMoney(line.shipmentAmount))),
            Expanded(
                child: _Amount(
                    label: _copy('Delivery fee', 'أجور التوصيل'),
                    value: formatStatementMoney(line.deliveryFee))),
            Expanded(child: _lineNet(line.netAmount))
          ]),
        ]),
      );
}

/// A negative line net is a delivery fee the merchant owes (e.g. a cancel after
/// departure or a return), shown as such rather than as a minus amount.
Widget _lineNet(String netAmount) {
  final net = num.tryParse(netAmount) ?? 0;
  if (net < 0) {
    return _Amount(
        label: _copy('You owe', 'مستحق عليك'),
        value: formatStatementMoney((-net).toString()));
  }
  return _Amount(
      label: _copy('Net', 'الصافي'), value: formatStatementMoney(netAmount));
}
