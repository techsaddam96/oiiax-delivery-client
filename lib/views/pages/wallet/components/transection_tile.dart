import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:flutter/material.dart';

// Model class for withdrawal request from API
class WithdrawalRequest {
  final int id;
  final int clientId;
  final double amount;
  final String currency;
  final dynamic status; // Can be int or String
  final String withdrawalMethod;
  final String accountDetails;
  final String requestedAt;

  WithdrawalRequest({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.withdrawalMethod,
    required this.accountDetails,
    required this.requestedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'JOD',
      status: json['status'] ?? 0,
      withdrawalMethod: json['withdrawal_method'] ?? '',
      accountDetails: json['account_details'] ?? '',
      requestedAt: json['requested_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'withdrawal_method': withdrawalMethod,
      'account_details': accountDetails,
      'requested_at': requestedAt,
    };
  }
}

Widget buildTransactionItem(
  String type,
  String amount,
  String date,
  String method,
  bool isCompleted, {
  String? status,
  Color? statusColor,
}) {
  // Ensure all parameters are valid strings
  final safeType = type.toString();
  final safeAmount = amount.toString();
  final safeDate = date.toString();
  final safeMethod = method.toString();

  // Get localized status text
  String getLocalizedStatus() {
    if (status != null) return AppTranslations.getText(status.toLowerCase());
    if (isCompleted) {
      return AppTranslations.getText('completed');
    } else {
      return AppTranslations.getText('pending');
    }
  }

  // Get localized method text
  String getLocalizedMethod() {
    if (safeMethod.toLowerCase() == 'cash') {
      return AppTranslations.getText('cash');
    } else if (safeMethod.toLowerCase().contains('bank')) {
      return AppTranslations.getText('bank_transfer');
    }
    return safeMethod;
  }

  // final textTheme = Theme.of(Nav.context).textTheme;
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white54,
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
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/images/downarrow.png',
            width: 15,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeType,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor),
              ),
              const SizedBox(height: 4),
              Text(
                safeAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                safeDate,
                style: TextStyle(fontSize: 10, color: AppColors.textColor),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              getLocalizedMethod(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacing.y(0.3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (statusColor ?? Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.pending,
                    color: statusColor ?? Colors.green,
                    size: 12,
                  ),
                  Spacing.x(1),
                  Text(
                    getLocalizedStatus(),
                    style: TextStyle(
                      color: statusColor ?? Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// New function to handle API response structure
Widget buildTransactionItemFromApi({
  required int id,
  required int clientId,
  required double amount,
  required String currency,
  required dynamic status, // Can be int or String
  required String withdrawalMethod,
  required String accountDetails,
  required String requestedAt,
}) {
  // Map status codes to localized text and colors
  Map<String, dynamic> getStatusInfo(int statusCode) {
    switch (statusCode) {
      case 0:
        return {
          'text': AppTranslations.getText('pending'),
          'color': Colors.orange,
          'icon': Icons.pending,
          'isCompleted': false,
        };
      case 1:
        return {
          'text': AppTranslations.getText('approved'),
          'color': Colors.blue,
          'icon': Icons.check_circle,
          'isCompleted': false,
        };
      case 2:
        return {
          'text': AppTranslations.getText('rejected'),
          'color': Colors.red,
          'icon': Icons.cancel,
          'isCompleted': false,
        };
      case 3:
        return {
          'text': AppTranslations.getText('completed'),
          'color': Colors.green,
          'icon': Icons.check_circle_outline,
          'isCompleted': true,
        };
      default:
        return {
          'text': AppTranslations.getText('pending'),
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'isCompleted': false,
        };
    }
  }

  // Get localized withdrawal method
  String getLocalizedWithdrawalMethod() {
    if (withdrawalMethod.toLowerCase() == 'cash') {
      return AppTranslations.getText('cash');
    } else if (withdrawalMethod.toLowerCase().contains('bank')) {
      return AppTranslations.getText('bank_transfer');
    }
    return withdrawalMethod;
  }

  final statusInfo = getLocalizedStatusInfo(status);
  final formattedAmount = '$amount $currency';
  final formattedDate = _formatDate(requestedAt);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with ID and status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#$id',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusInfo['icon'],
                    color: statusInfo['color'],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusInfo['text'],
                    style: TextStyle(
                      color: statusInfo['color'],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Amount and method row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getText('amount'),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppTranslations.getText('withdrawal_method'),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getLocalizedWithdrawalMethod(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date row
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.textColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${AppTranslations.getText('requested_at')}: $formattedDate',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),

        // Account details if available
        if (accountDetails.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.account_balance,
                size: 14,
                color: AppColors.textColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${AppTranslations.getText('account_details')}: $accountDetails',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

// Helper function to format date
String _formatDate(String dateString) {
  try {
    final date = JordanTime.parse(dateString);
    if (date == null) return dateString;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateString;
  }
}

// Convenience function to create a list of transaction tiles from API response
List<Widget> buildTransactionListFromApiResponse(
    Map<String, dynamic> apiResponse) {
  final List<Widget> transactionTiles = [];

  try {
    final List<dynamic> requests = apiResponse['requests'] ?? [];

    for (final request in requests) {
      final withdrawalRequest = WithdrawalRequest.fromJson(request);
      transactionTiles.add(
        buildTransactionItemFromApi(
          id: withdrawalRequest.id,
          clientId: withdrawalRequest.clientId,
          amount: withdrawalRequest.amount,
          currency: withdrawalRequest.currency,
          status: withdrawalRequest.status,
          withdrawalMethod: withdrawalRequest.withdrawalMethod,
          accountDetails: withdrawalRequest.accountDetails,
          requestedAt: withdrawalRequest.requestedAt,
        ),
      );
    }
  } catch (e) {
    print('Error parsing API response: $e');
    // Return empty list if there's an error
  }

  return transactionTiles;
}

// Function to get localized status text for a given status code
String getLocalizedStatusText(dynamic status) {
  if (status is String) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('reject') || statusLower.contains('مرفوض')) {
      return AppTranslations.getText('rejected');
    } else if (statusLower.contains('approve') ||
        statusLower.contains('موافق')) {
      return AppTranslations.getText('approved');
    } else if (statusLower.contains('complete') ||
        statusLower.contains('مكتمل')) {
      return AppTranslations.getText('completed');
    } else if (statusLower.contains('pending') || statusLower.contains('قيد')) {
      return AppTranslations.getText('pending');
    }
  }

  if (status is int) {
    switch (status) {
      case 0:
        return AppTranslations.getText('pending');
      case 1:
        return AppTranslations.getText('approved');
      case 2:
        return AppTranslations.getText('rejected');
      case 3:
        return AppTranslations.getText('completed');
      default:
        return AppTranslations.getText('pending');
    }
  }

  return AppTranslations.getText('pending');
}

// Function to get status color for a given status code
Color getStatusColor(dynamic status) {
  if (status is String) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('reject') || statusLower.contains('مرفوض')) {
      return Colors.red;
    } else if (statusLower.contains('approve') ||
        statusLower.contains('موافق')) {
      return Colors.blue;
    } else if (statusLower.contains('complete') ||
        statusLower.contains('مكتمل')) {
      return Colors.green;
    } else if (statusLower.contains('pending') || statusLower.contains('قيد')) {
      return Colors.orange;
    }
  }

  if (status is int) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  return Colors.grey;
}

// Function to get localized status info from either status code or status string
Map<String, dynamic> getLocalizedStatusInfo(dynamic status) {
  // If status is a string, try to match it
  if (status is String) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('reject') || statusLower.contains('مرفوض')) {
      return {
        'text': AppTranslations.getText('rejected'),
        'color': Colors.red,
        'icon': Icons.cancel,
        'isCompleted': false,
      };
    } else if (statusLower.contains('approve') ||
        statusLower.contains('موافق')) {
      return {
        'text': AppTranslations.getText('approved'),
        'color': Colors.blue,
        'icon': Icons.check_circle,
        'isCompleted': false,
      };
    } else if (statusLower.contains('complete') ||
        statusLower.contains('مكتمل')) {
      return {
        'text': AppTranslations.getText('completed'),
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
        'isCompleted': true,
      };
    } else if (statusLower.contains('pending') || statusLower.contains('قيد')) {
      return {
        'text': AppTranslations.getText('pending'),
        'color': Colors.orange,
        'icon': Icons.pending,
        'isCompleted': false,
      };
    }
  }

  // If status is a number, use the existing logic
  if (status is int) {
    return getLocalizedStatusInfoFromCode(status);
  }

  // Default fallback
  return {
    'text': AppTranslations.getText('pending'),
    'color': Colors.grey,
    'icon': Icons.help_outline,
    'isCompleted': false,
  };
}

// Function to get localized status info from status code
Map<String, dynamic> getLocalizedStatusInfoFromCode(int statusCode) {
  switch (statusCode) {
    case 0:
      return {
        'text': AppTranslations.getText('pending'),
        'color': Colors.orange,
        'icon': Icons.pending,
        'isCompleted': false,
      };
    case 1:
      return {
        'text': AppTranslations.getText('approved'),
        'color': Colors.blue,
        'icon': Icons.check_circle,
        'isCompleted': false,
      };
    case 2:
      return {
        'text': AppTranslations.getText('rejected'),
        'color': Colors.red,
        'icon': Icons.cancel,
        'isCompleted': false,
      };
    case 3:
      return {
        'text': AppTranslations.getText('completed'),
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
        'isCompleted': true,
      };
    default:
      return {
        'text': AppTranslations.getText('pending'),
        'color': Colors.grey,
        'icon': Icons.help_outline,
        'isCompleted': false,
      };
  }
}
