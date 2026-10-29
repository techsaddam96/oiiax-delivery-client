import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/balance_history.dart';
import 'package:blockatie/provider/balance_history.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BalanceHistoryPage extends StatefulWidget {
  const BalanceHistoryPage({super.key});

  @override
  State<BalanceHistoryPage> createState() => _BalanceHistoryPageState();
}

class _BalanceHistoryPageState extends State<BalanceHistoryPage> {
  final provider =
      Provider.of<BalanceHistoryProvider>(Nav.context, listen: false);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {});
    getBalanceHistory();
  }

  void getBalanceHistory() async {
    await provider.fetchBalanceHistory(refresh: true);
  }

  String formatTimeAgo(String timeString) {
    final createdAt = JordanTime.parse(timeString);
    if (createdAt == null) return "";

    final now = JordanTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24)
      return "${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} d ago";
  }

  String formatDate(String dateString) {
    final date = JordanTime.parse(dateString);
    if (date == null) return "";

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Balance History',
        showBtn: false,
        subtitle: 'Your transaction history and balance details',
      ),
      body: Consumer<BalanceHistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = provider.filteredTransactions;

          if (transactions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshTransactions(),
            child: Column(
              children: [
                // Statistics Cards
                _buildStatisticsCards(provider),

                // Filter Section
                _buildFilterSection(provider),

                // Transactions List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount:
                        transactions.length + (provider.hasMoreData ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == transactions.length) {
                        // Load more indicator
                        return _buildLoadMoreButton(provider);
                      }

                      final transaction = transactions[index];
                      return _buildTransactionItem(context, transaction);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.refreshTransactions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BalanceHistoryProvider provider) {
    final stats = provider.getTransactionStats();
    final currentMonthStats = provider.currentMonthStats;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Month Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Income',
                        '${currentMonthStats['totalCredit']?.toStringAsFixed(2)} JOD',
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Expenses',
                        '${currentMonthStats['totalDebit']?.toStringAsFixed(2)} JOD',
                        Colors.red,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Overall Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Income',
                        '${stats['totalCredit']?.toStringAsFixed(2)} JOD',
                        Colors.green,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Total Expenses',
                        '${stats['totalDebit']?.toStringAsFixed(2)} JOD',
                        Colors.red,
                        Icons.payment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(BalanceHistoryProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'All',
              provider.selectedFilter == 'all',
              () => provider.setFilter('all'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              'Income',
              provider.selectedFilter == 'credit',
              () => provider.setFilter('credit'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              'Expenses',
              provider.selectedFilter == 'debit',
              () => provider.setFilter('debit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, BalanceTransaction transaction) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: transaction.transactionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              transaction.transactionIcon,
              width: 20,
              height: 20,
              color: transaction.transactionColor,
            ),
          ),
          const SizedBox(width: 12.0),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  transaction.method,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 10.0,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: transaction.transactionColor,
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: TextStyle(
                    color: transaction.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(BalanceHistoryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed:
              provider.isLoading ? null : () => provider.loadMoreTransactions(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Load More'),
        ),
      ),
    );
  }
}

// Example of how to navigate to the Balance History page
class BalanceHistoryNavigationExample {
  static void navigateToBalanceHistory() {
    Nav.to(const BalanceHistoryPage());
  }

  // Example usage in a button or menu item
  static Widget buildNavigationButton() {
    return ElevatedButton(
      onPressed: navigateToBalanceHistory,
      child: const Text('View Balance History'),
    );
  }
}
