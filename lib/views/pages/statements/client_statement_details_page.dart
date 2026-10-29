import 'package:blockatie/models/statements/client_statement_details.dart';
import 'package:blockatie/provider/statements/client_statement_details_provider.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/statements/widgets/statement_ui.dart';
import 'package:blockatie/views/pages/statements/widgets/handover_code_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientStatementDetailsPage extends StatefulWidget {
  const ClientStatementDetailsPage({super.key, required this.statementId});
  final int statementId;

  @override
  State<ClientStatementDetailsPage> createState() =>
      _ClientStatementDetailsPageState();
}

class _ClientStatementDetailsPageState
    extends State<ClientStatementDetailsPage> {
  late final ClientStatementDetailsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ClientStatementDetailsProvider();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _provider.load(widget.statementId));
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _provider,
        child: _StatementDetailsView(statementId: widget.statementId),
      );
}

class _StatementDetailsView extends StatefulWidget {
  const _StatementDetailsView({required this.statementId});
  final int statementId;

  @override
  State<_StatementDetailsView> createState() => _StatementDetailsViewState();
}

class _StatementDetailsViewState extends State<_StatementDetailsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 180) {
        context.read<ClientStatementDetailsProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _t(String en, String ar) => AppLocalizations.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: SafeArea(
        child: Consumer<ClientStatementDetailsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final details = provider.details;
            if (details == null) {
              return Center(
                child: FilledButton(
                  onPressed: () => provider.load(widget.statementId),
                  child: Text(_t('Retry', 'إعادة المحاولة')),
                ),
              );
            }
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _Header(details: details)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                          child: _DetailsSummary(details: details)),
                      if (details.statement.canRevealHandoverCode)
                        SliverToBoxAdapter(child: HandoverCodeCard(
                          key: ValueKey(details.statement.statementId),
                          statementId: details.statement.statementId,
                          ar: AppLocalizations.isArabic,
                        )),
                      if (details.statement.hasPdf)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FilledButton.icon(
                              onPressed: provider.isDownloadingPdf
                                  ? null
                                  : () async {
                                      final error =
                                          await provider.downloadPdf();
                                      if (error != null && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(_t(
                                                  'Unable to open statement PDF.',
                                                  'تعذر فتح ملف الكشف.'))),
                                        );
                                      }
                                    },
                              icon: provider.isDownloadingPdf
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.picture_as_pdf_outlined),
                              label: Text(
                                  _t('View statement PDF', 'عرض الكشف PDF')),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: Text(
                          _t('Included shipments', 'الشحنات ضمن الكشف'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff10213C)),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      SliverList.separated(
                        itemCount: provider.lines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) =>
                            StatementLineTile(line: provider.lines[index]),
                      ),
                      if (provider.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(18),
                              child:
                                  Center(child: CircularProgressIndicator())),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.details});
  final ClientStatementDetails details;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Row(children: [
          const IconButton(
              onPressed: Nav.back,
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          const SizedBox(width: 5),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    AppLocalizations.isArabic
                        ? 'تفاصيل الكشف'
                        : 'Statement Details',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff10213C))),
                Text(details.statement.statementNumber,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xff64748B))),
              ])),
          StatementStatusBadge(status: details.statement.status),
        ]),
      );
}

class _DetailsSummary extends StatelessWidget {
  const _DetailsSummary({required this.details});
  final ClientStatementDetails details;

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.isArabic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE6ECF5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(isArabic ? 'الملخص المالي' : 'Financial summary',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        _row(isArabic ? 'إجمالي قيمة الشحنات' : 'Shipment value total',
            formatStatementMoney(details.summary.codTotal)),
        _row(isArabic ? 'أجور التوصيل' : 'Delivery fees',
            formatStatementMoney(details.summary.deliveryFeesTotal)),
        _row(isArabic ? 'الصافي' : 'Net',
            formatStatementMoney(details.summary.netTotal),
            bold: true),
        _row(isArabic ? 'المتبقي' : 'Remaining',
            formatStatementMoney(details.statement.remainingAmount),
            bold: true),
        _row(isArabic ? 'عدد الشحنات' : 'Shipments count',
            '${details.summary.shipmentsCount}'),
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: Color(0xff64748B), fontSize: 12))),
          Text(value,
              style: TextStyle(
                  color: const Color(0xff10213C),
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 12)),
        ]),
      );
}
