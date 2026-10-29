import 'package:flutter/material.dart';

class BalanceHistoryResponse {
  final String status;
  final String message;
  final List<BalanceTransaction> transactions;
  final int totalCount;

  BalanceHistoryResponse({
    required this.status,
    required this.message,
    required this.transactions,
    required this.totalCount,
  });

  factory BalanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return BalanceHistoryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      totalCount: json['total_count'] ?? 0,
      transactions: (json['transactions'] as List?)
              ?.map((e) => BalanceTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BalanceTransaction {
  final int id;
  final String type; // 'credit', 'debit', 'withdrawal', 'payment'
  final String amount;
  final String description;
  final String method; // 'cash', 'bank', 'card', etc.
  final String status; // 'completed', 'pending', 'failed'
  final String createdAt;
  final String? referenceId;
  final String? notes;

  BalanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.method,
    required this.status,
    required this.createdAt,
    this.referenceId,
    this.notes,
  });

  factory BalanceTransaction.fromJson(Map<String, dynamic> json) {
    return BalanceTransaction(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      amount: json['amount'] ?? '0.00',
      description: json['description'] ?? '',
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      referenceId: json['reference_id'],
      notes: json['notes'],
    );
  }

  // Helper method to get transaction icon
  String get transactionIcon {
    switch (type.toLowerCase()) {
      case 'credit':
      case 'payment':
        return 'assets/images/curly_arrow_up.png';
      case 'debit':
      case 'withdrawal':
        return 'assets/images/curly_arrow_down.png';
      default:
        return 'assets/images/clock.png';
    }
  }

  // Helper method to get transaction color
  Color get transactionColor {
    switch (type.toLowerCase()) {
      case 'credit':
      case 'payment':
        return Colors.green;
      case 'debit':
      case 'withdrawal':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get formatted amount
  String get formattedAmount {
    if (type.toLowerCase() == 'credit' || type.toLowerCase() == 'payment') {
      return '+$amount JOD';
    } else {
      return '-$amount JOD';
    }
  }
}
