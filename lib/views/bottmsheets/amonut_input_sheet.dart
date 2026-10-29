import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/requests_provider.dart';
import 'package:blockatie/provider/withdrawal.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/views/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/localization/app_localizations.dart';

class AmountInputSheet extends StatelessWidget {
  const AmountInputSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WithdrawalProvider>(
      builder: (_, provider, __) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.getText('enter_amount'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.y(5),
            Center(
              child: Consumer<WithdrawalProvider>(
                builder: (context, provider, child) {
                  return GestureDetector(
                    onTap: () {
                      if (provider.showAgreement) {
                        context
                            .read<WithdrawalProvider>()
                            .hideAgreementSection();
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 350),
                      padding: EdgeInsetsDirectional.all(8),
                      decoration: BoxDecoration(
                          color: provider.showAgreement
                              ? AppColors.primary.withAlpha(30)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        provider.amount,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: provider.showAgreement
                              ? AppColors.primary
                              : Colors.black54,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: SizeConfig.heightMultiplier * 25),

            // Content Area - Keypad or Agreement
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Consumer<WithdrawalProvider>(
                  builder: (context, provider, child) {
                    return provider.showAgreement
                        ? _AgreementSection(provider: provider)
                        : const _CustomKeypad();
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Agreement Section Widget
class _AgreementSection extends StatelessWidget {
  final WithdrawalProvider provider;

  const _AgreementSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),

        // Error message if any
        if (provider.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              provider.error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Agreement Checkbox
        Row(
          children: [
            Checkbox(
              value: provider.agreedToTerms,
              onChanged: (value) {
                provider.toggleAgreement();
                provider.clearError();
              },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                AppTranslations.getText('terms_conditions'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Withdrawal Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: provider.agreedToTerms && !provider.isLoading
                ? () async {
                    // Show confirmation dialog first
                    bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                              AppTranslations.getText('confirm_withdrawal')),
                          content: Text(
                            '${AppTranslations.getText('confirm_withdrawal_content')} ${provider.amount}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(AppTranslations.getText('cancel')),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(AppTranslations.getText('confirm')),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      // Submit withdrawal request
                      final result = await provider.submitWithdrawalRequest();

                      if (result['data']['status'] == 'success') {
                        // Success
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close bottom sheet

                          // Show success alert dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Success Icon
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 50,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Title
                                      Text(
                                        AppTranslations.getText(
                                            'withdrawal_request_submitted'),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),

                                      // Message
                                      Text(
                                        _getLocalizedStatusName(
                                                result['data']['message_en'],
                                                result['data']['message_ar']) ??
                                            result['data']['message'] ??
                                            AppTranslations.getText(
                                                'withdrawal_success'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // OK Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Nav.offAll(
                                                withNav: true,
                                                navIndex: 0,
                                                CustomBottomNavBar());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            AppTranslations.getText('ok'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          // Refresh the requests list in the wallet page
                          // We need to find the wallet page and refresh it
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final requestsProvider =
                                Provider.of<RequestsProvider>(context,
                                    listen: false);
                            requestsProvider.fetchRequests();
                          });
                        }
                      } else {
                        // Error
                        if (context.mounted) {
                          // Show error alert dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Error Icon
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Title
                                      Text(
                                        AppTranslations.getText(
                                            'withdrawal_failed'),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),

                                      // Message
                                      Text(
                                        _getLocalizedStatusName(
                                                result['data']['message_en'],
                                                result['data']['message_ar']) ??
                                            result['data']['message'] ??
                                            AppTranslations.getText(
                                                'withdrawal_failed'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // Buttons Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                      color:
                                                          Colors.grey.shade300),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Text(
                                                  AppTranslations.getText(
                                                      'cancel'),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  // Optionally retry the request
                                                  // provider.submitWithdrawalRequest();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  AppTranslations.getText('ok'),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppTranslations.getText('submit_withdrawal'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  String? _getLocalizedStatusName(String? statusName, String? arName) {
    if (AppLocalizations.isRTL && arName != null && arName.isNotEmpty) {
      return arName;
    }
    return statusName;
  }
}

// Custom Keypad Widget
class _CustomKeypad extends StatelessWidget {
  const _CustomKeypad();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton(context, '1', 'abc'),
              _buildKeypadButton(context, '2', 'def'),
              _buildKeypadButton(context, '3', 'ghi'),
            ],
          ),
        ),

        // Row 2: 4, 5, 6
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton(context, '4', 'ghi'),
              _buildKeypadButton(context, '5', 'jkl'),
              _buildKeypadButton(context, '6', 'mno'),
            ],
          ),
        ),

        // Row 3: 7, 8, 9
        Expanded(
          child: Row(
            children: [
              _buildKeypadButton(context, '7', 'pqrs'),
              _buildKeypadButton(context, '8', 'tuv'),
              _buildKeypadButton(context, '9', 'wxyz'),
            ],
          ),
        ),

        // Row 4: Tick, 0, Backspace
        Expanded(
          child: Row(
            children: [
              _buildTickButton(context), // Added tick button
              _buildKeypadButton(context, '0', ''),
              _buildBackspaceButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(
      BuildContext context, String number, String letters) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 65,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<WithdrawalProvider>().addDigit(number);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  if (letters.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      letters,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTickButton(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 65,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<WithdrawalProvider>().showAgreementSection();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Icon(
                Icons.check,
                size: 24,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 65,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<WithdrawalProvider>().removeLastDigit();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: const Icon(
                Icons.backspace_outlined,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
