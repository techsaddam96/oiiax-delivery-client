import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/provider/withdrawal.dart';
import 'package:blockatie/services/requests_service.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  String _selectedMethod = 'cash';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadWalletData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    final profileProvider = context.read<ProfileProvider>();
    final requestsProvider = context.read<RequestsProvider>();

    await Future.wait([
      profileProvider.fetchClientStatistics(),
      requestsProvider.fetchRequests(),
    ]);
  }

  Future<void> _refreshWallet() async {
    final profileProvider = context.read<ProfileProvider>();
    final requestsProvider = context.read<RequestsProvider>();

    await Future.wait([
      profileProvider.fetchClientStatistics(),
      requestsProvider.fetchRequests(force: true),
    ]);
  }

  Future<void> _submitWithdrawal({
    required ProfileProvider profileProvider,
    required WithdrawalProvider withdrawalProvider,
  }) async {
    final amountText = _amountController.text.trim();
    final requestedAmount = double.tryParse(amountText);

    if (requestedAmount == null ||
        !requestedAmount.isFinite ||
        requestedAmount <= 0 ||
        !RegExp(r'^\d{1,9}(?:\.\d{1,2})?$').hasMatch(amountText)) {
      _showSnack(
        _copy(
          'Enter a valid amount greater than zero.',
          'أدخل مبلغاً صحيحاً أكبر من صفر.',
        ),
        isError: true,
      );
      return;
    }

    if (profileProvider.statisticsError != null ||
        profileProvider.isLoadingStatistics) {
      _showSnack(
          _copy('Refresh wallet data first.', 'حدّث بيانات المحفظة أولًا.'),
          isError: true);
      return;
    }
    final availableBalance = _availableBalance(profileProvider.statistics);
    if (availableBalance == null) {
      _showSnack(
          _copy('Wallet verification is required before withdrawal.',
              'يلزم التحقق من المحفظة قبل السحب.'),
          isError: true);
      return;
    }
    if (requestedAmount > availableBalance) {
      _showSnack(
        _copy(
          'The amount is greater than the available balance.',
          'المبلغ أكبر من الرصيد المتاح.',
        ),
        isError: true,
      );
      return;
    }

    _amountFocusNode.unfocus();

    final success = await withdrawalProvider.submitCustomWithdrawalRequest(
      requestedAmount: requestedAmount,
      withdrawalMethod: _selectedMethod,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _amountController.clear();
      _showSnack(
        withdrawalProvider.lastMessage ??
            _copy(
              'Withdrawal request sent successfully.',
              'تم إرسال طلب السحب بنجاح.',
            ),
      );
      await _refreshWallet();
      return;
    }

    _showSnack(
      withdrawalProvider.lastError ??
          _copy(
            'Failed to send withdrawal request.',
            'فشل إرسال طلب السحب.',
          ),
      isError: true,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? const Color(0xffDC2626) : const Color(0xff16A06D),
        ),
      );
  }

  String _copy(String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomContentPadding = 176.0 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: CustomAppBar(
        title: _copy('Wallet', 'المحفظة'),
        subtitle: _copy(
          'Balance, payouts, and withdrawal requests',
          'الرصيد والمدفوعات وطلبات السحب',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshWallet,
              child: Consumer3<ProfileProvider, RequestsProvider,
                  WithdrawalProvider>(
                builder: (
                  context,
                  profileProvider,
                  requestsProvider,
                  withdrawalProvider,
                  _,
                ) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomContentPadding,
                    ),
                    children: [
                      WalletBalanceCard(
                        statistics: profileProvider.statisticsError == null
                            ? profileProvider.statistics
                            : null,
                        isLoading: profileProvider.isLoadingStatistics &&
                            profileProvider.statistics == null,
                        copy: _copy,
                      ),
                      if (profileProvider.statisticsError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            profileProvider.statisticsError!,
                            style: const TextStyle(color: Color(0xffDC2626)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _WithdrawalFormCard(
                        amountController: _amountController,
                        amountFocusNode: _amountFocusNode,
                        selectedMethod: _selectedMethod,
                        isSubmitting: withdrawalProvider.isSubmitting,
                        onMethodChanged: (value) {
                          setState(() => _selectedMethod = value);
                        },
                        onSubmit: () {
                          unawaited(
                            _submitWithdrawal(
                              profileProvider: profileProvider,
                              withdrawalProvider: withdrawalProvider,
                            ),
                          );
                        },
                        copy: _copy,
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: _copy(
                          'Withdrawal Requests',
                          'طلبات السحب',
                        ),
                        subtitle: _copy(
                          'Track every request and its current status',
                          'تابع كل طلب وحالته الحالية',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRequestsSection(
                        profileProvider: profileProvider,
                        requestsProvider: requestsProvider,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection({
    required ProfileProvider profileProvider,
    required RequestsProvider requestsProvider,
  }) {
    if (requestsProvider.isLoading && requestsProvider.requests.isEmpty) {
      return _StateCard(
        icon: Icons.account_balance_wallet_outlined,
        title: _copy('Loading wallet data...', 'جارٍ تحميل بيانات المحفظة...'),
        message: _copy('Please wait a moment.', 'يرجى الانتظار لحظات.'),
        isLoading: true,
      );
    }

    if (requestsProvider.error != null && requestsProvider.requests.isEmpty) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        title: _copy(
          'Unable to load wallet data',
          'تعذر تحميل بيانات المحفظة',
        ),
        message: requestsProvider.error!,
        actionLabel: _copy('Try again', 'حاول مرة أخرى'),
        onAction: () {
          unawaited(requestsProvider.fetchRequests(force: true));
        },
      );
    }

    if (requestsProvider.requests.isEmpty) {
      final fallback = profileProvider.statisticsError == null
          ? _copy(
              'No withdrawal requests yet.',
              'لا توجد طلبات سحب حالياً.',
            )
          : profileProvider.statisticsError!;

      return _StateCard(
        icon: Icons.receipt_long_outlined,
        title: _copy(
          'No withdrawal requests yet',
          'لا توجد طلبات سحب حالياً',
        ),
        message: fallback,
      );
    }

    return Column(
      children: [
        for (final request in requestsProvider.paginatedRequests) ...[
          _RequestCard(request: request, copy: _copy),
          const SizedBox(height: 10),
        ],
        if (requestsProvider.totalPages > 1)
          _PaginationBar(
            currentPage: requestsProvider.currentPage,
            totalPages: requestsProvider.totalPages,
            onPrevious: requestsProvider.currentPage > 1
                ? requestsProvider.goToPrevPage
                : null,
            onNext: requestsProvider.currentPage < requestsProvider.totalPages
                ? requestsProvider.goToNextPage
                : null,
            onPageSelected: requestsProvider.setPage,
            copy: _copy,
          ),
      ],
    );
  }
}

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.statistics,
    required this.isLoading,
    required this.copy,
  });

  final ClientStatisticsData? statistics;
  final bool isLoading;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    final available = statistics?.availableForWithdrawal;
    final currentBalance =
        available == null ? '—' : _moneyFromDouble(available);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy(
                        'Available to withdraw',
                        'المتاح للسحب',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? copy('Loading...', 'جارٍ التحميل...')
                          : currentBalance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: copy('Company owes you', 'المستحق لك من الشركة'),
                  value: _displayMoney(
                    statistics?.companyOwesMerchant,
                    fallback: statistics?.finalTotalValueOrder,
                  ),
                  icon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: copy('You owe the company', 'المستحق عليك للشركة'),
                  value: _displayMoney(
                    statistics?.merchantOwesCompany,
                    fallback: statistics?.totalRequired,
                  ),
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            copy('Reserved for withdrawal: ', 'محجوز للسحب: ') +
                _displayMoney(statistics?.reservedWithdrawals),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            copy('Shipment balance (not due): ', 'رصيد الشحنات غير المستحق: ') +
                _displayMoney(statistics?.balanceTotal),
            style: const TextStyle(color: Colors.white70),
          ),
          if (statistics?.walletReviewRequired == true ||
              (statistics != null && statistics!.walletVersion != 1)) ...[
            const SizedBox(height: 10),
            Text(
              copy('Accounting review is required before withdrawal.',
                  'تحتاج المحفظة مراجعة محاسبية قبل السحب.'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.82), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalFormCard extends StatelessWidget {
  const _WithdrawalFormCard({
    required this.amountController,
    required this.amountFocusNode,
    required this.selectedMethod,
    required this.isSubmitting,
    required this.onMethodChanged,
    required this.onSubmit,
    required this.copy,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String selectedMethod;
  final bool isSubmitting;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onSubmit;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: copy('Request Withdrawal', 'طلب سحب'),
            subtitle: copy(
              'Enter an amount and choose the payout method',
              'أدخل المبلغ واختر طريقة السحب المناسبة',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            focusNode: amountFocusNode,
            enabled: !isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: copy('Amount', 'المبلغ'),
              hintText: '0.00',
              suffixText: 'JOD',
              prefixIcon: const Icon(Icons.payments_outlined),
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MethodChoice(
                  label: copy('Cash', 'نقداً'),
                  icon: Icons.account_balance_outlined,
                  isSelected: selectedMethod == 'cash',
                  onTap: isSubmitting ? null : () => onMethodChanged('cash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodChoice(
                  label: 'CliQ',
                  icon: Icons.phone_android_rounded,
                  isSelected: selectedMethod == 'click',
                  onTap: isSubmitting ? null : () => onMethodChanged('click'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      copy('Submit Request', 'إرسال الطلب'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffEAF3FF) : const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xffE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : const Color(0xff64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.primary : const Color(0xff475569),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.copy,
  });

  final WithdrawalRequest request;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.south_west_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.amount} ${request.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _methodLabel(request.withdrawalMethod, copy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: _statusLabel(request.status, copy),
                color: request.statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.event_outlined,
                label: _formatDate(request.requestedAt, copy),
              ),
              if (request.accountDetails.trim().isNotEmpty)
                _InfoChip(
                  icon: Icons.account_balance_outlined,
                  label: request.accountDetails,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xff64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff475569),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (isLoading)
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppColors.primary,
              ),
            )
          else
            Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
    required this.copy,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
            tooltip: copy('Previous', 'السابق'),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy(
                    'Page $currentPage of $totalPages',
                    'صفحة $currentPage من $totalPages',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _PageNumberStrip(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPageSelected: onPageSelected,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.primary,
            tooltip: copy('Next', 'التالي'),
          ),
        ],
      ),
    );
  }
}

class _PageNumberStrip extends StatelessWidget {
  const _PageNumberStrip({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final page in pages) ...[
            if (page == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '…',
                  style: TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              _PageNumberButton(
                page: page,
                selected: page == currentPage,
                onTap: () => onPageSelected(page),
              ),
            const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }

  List<int?> _visiblePages() {
    if (totalPages <= 5) {
      return List<int?>.generate(totalPages, (index) => index + 1);
    }
    if (currentPage <= 3) {
      return <int?>[1, 2, 3, null, totalPages];
    }
    if (currentPage >= totalPages - 2) {
      return <int?>[1, null, totalPages - 2, totalPages - 1, totalPages];
    }
    return <int?>[1, null, currentPage, null, totalPages];
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xffF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xff475569),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xffE5EAF2)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xff0F172A).withValues(alpha: 0.06),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

String _methodLabel(
  String value,
  String Function(String en, String ar) copy,
) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'cash') {
    return copy('Cash', 'نقداً');
  }
  if (normalized == 'click' || normalized == 'cliq') {
    return 'CliQ';
  }
  if (normalized.isEmpty) {
    return copy('Not available', 'غير متوفر');
  }
  return value;
}

String _statusLabel(
  int status,
  String Function(String en, String ar) copy,
) {
  switch (status) {
    case 0:
      return copy('Pending', 'قيد الانتظار');
    case 1:
      return copy('Approved', 'مقبول');
    case 2:
      return copy('Rejected', 'مرفوض');
    case 3:
      return copy('Completed', 'مكتمل');
    default:
      return copy('Unknown', 'غير معروف');
  }
}

String _formatDate(
  String value,
  String Function(String en, String ar) copy,
) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return copy('Not available', 'غير متوفر');
  }
  if (normalized.length <= 16) {
    return normalized;
  }
  return normalized.substring(0, 16);
}

String _displayMoney(String? raw, {String? fallback}) {
  final text = (raw ?? fallback ?? '').trim();
  if (text.isEmpty) {
    return '0.00 JOD';
  }

  final normalized = text.replaceAll('JOD', '').trim();
  final parsed = double.tryParse(normalized);
  if (parsed == null) {
    return text;
  }
  return _moneyFromDouble(parsed);
}

String _moneyFromDouble(double value) {
  return '${value.toStringAsFixed(2)} JOD';
}

double? _availableBalance(ClientStatisticsData? statistics) =>
    statistics?.availableForWithdrawal;
