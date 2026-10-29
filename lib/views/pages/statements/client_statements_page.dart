import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/statements/client_statements_provider.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/views/pages/statements/client_statement_details_page.dart';
import 'package:blockatie/views/pages/statements/widgets/statement_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientStatementsPage extends StatefulWidget {
  const ClientStatementsPage({super.key});
  @override
  State<ClientStatementsPage> createState() => _ClientStatementsPageState();
}

class _ClientStatementsPageState extends State<ClientStatementsPage> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ClientStatementsProvider>().loadInitial();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      context.read<ClientStatementsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _t(String en, String ar) => AppLocalizations.isArabic ? ar : en;
  String _message(String? key) => switch (key) {
        'authentication' => _t(
            'Your session has expired. Please sign in again.',
            'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.'),
        'authorization' => _t('You cannot access these statements.',
            'لا يمكنك الوصول إلى هذه الكشوف.'),
        'network' => _t('Unable to connect. Please try again.',
            'تعذر الاتصال. حاول مرة أخرى.'),
        _ => _t('Unable to load statements.', 'تعذر تحميل الكشوف.')
      };
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        body: SafeArea(child:
            Consumer<ClientStatementsProvider>(builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                      child: _Header(
                          title: _t('My Statements', 'كشوفاتي'),
                          subtitle: _t('Your issued account statements',
                              'كشوفات حسابك الصادرة'),
                          onBack: Nav.back)),
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                      sliver: SliverMainAxisGroup(slivers: [
                        if (provider.summary != null)
                          SliverToBoxAdapter(
                              child: FinancialSummaryCard(
                                  summary: provider.summary!)),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        SliverToBoxAdapter(
                            child: _StatusFilters(
                                selected: provider.selectedStatus,
                                onSelect: provider.changeStatus)),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        if (provider.state == ClientStatementsState.loading)
                          const SliverToBoxAdapter(child: _LoadingState()),
                        if (provider.state == ClientStatementsState.error)
                          SliverToBoxAdapter(
                              child: _ErrorState(
                                  message: _message(provider.errorKey),
                                  onRetry: provider.loadInitial)),
                        if (provider.state == ClientStatementsState.empty)
                          const SliverToBoxAdapter(child: _EmptyState()),
                        if (provider.state == ClientStatementsState.loaded)
                          SliverList.separated(
                              itemCount: provider.statements.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final item = provider.statements[index];
                                return StatementTile(
                                    statement: item,
                                    onTap: () => Nav.to(
                                        ClientStatementDetailsPage(
                                            statementId: item.statementId)));
                              }),
                        if (provider.isLoadingMore)
                          const SliverToBoxAdapter(
                              child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Center(
                                      child: CircularProgressIndicator()))),
                      ])),
                ]),
          );
        })),
      );
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.title, required this.subtitle, required this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(children: [
        IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        const SizedBox(width: 5),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff10213C))),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff64748B)))
        ]))
      ]));
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String?> onSelect;
  @override
  Widget build(BuildContext context) {
    final ar = AppLocalizations.isArabic;
    final items = [
      (null, ar ? 'الكل' : 'All'),
      ('approved', ar ? 'معتمد' : 'Approved'),
      ('pdf_generated', ar ? 'جاهز' : 'Ready'),
      ('sent', ar ? 'تم الإرسال' : 'Sent'),
      ('partial', ar ? 'مسدد جزئياً' : 'Partial'),
      ('paid', ar ? 'مسدد' : 'Paid')
    ];
    return SizedBox(
        height: 38,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final active = item.$1 == selected;
              return ChoiceChip(
                  label: Text(item.$2),
                  selected: active,
                  onSelected: (_) => onSelect(item.$1),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xff475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  side: BorderSide(
                      color: active
                          ? Colors.transparent
                          : const Color(0xffDCE5F1)));
            }));
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Column(
      children: List.generate(
          3,
          (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 145,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18)))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 65),
      child: Column(children: [
        const Icon(Icons.receipt_long_outlined,
            size: 54, color: Color(0xff94A3B8)),
        const SizedBox(height: 14),
        Text(
            AppLocalizations.isArabic
                ? 'لا توجد كشوفات حساب حتى الآن'
                : 'No account statements yet',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
            AppLocalizations.isArabic
                ? 'ستظهر كشوفات حسابك هنا بعد إصدارها.'
                : 'Your account statements will appear here after they are issued.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff64748B), fontSize: 12))
      ]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xff94A3B8)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.isArabic ? 'إعادة المحاولة' : 'Retry'))
      ]));
}
