import 'dart:ui' as ui;

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/withdrawal.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/wallet/withdrawl/withdrawal_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WithdrawCard extends StatelessWidget {
  const WithdrawCard(
      {super.key, this.balance, this.driverName, this.phoneNumber});

  final int? balance;
  final String? driverName;
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Consumer<WithdrawalProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          child: Stack(
            children: [
              /// Custom painted background
              CustomPaint(
                size: Size(SizeConfig.widthMultiplier * 100,
                    SizeConfig.heightMultiplier * 20),
                painter: RPSCustomPainter(),
              ),

              /// Wallet icon and balance
              Positioned(
                top: 20,
                left: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/images/walletIcon.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<ProfileProvider>(
                            builder: (context, profileProvider, child) {
                          final dBalance = profileProvider
                              .statistics?.availableForWithdrawal;
                          return Text(
                            provider.isBalanceHidden
                                ? '****'
                                : dBalance == null
                                    ? '—'
                                    : '${dBalance.toStringAsFixed(2)} JOD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                        Text(
                          AppTranslations.getText(
                              'total_balance_of_shipments_accrued'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// Hide Balance button
              Positioned(
                top: 17,
                right: SizeConfig.widthMultiplier * 3,
                child: GestureDetector(
                  onTap: () {
                    provider.toggleBalanceVisibility();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.isBalanceHidden
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          size: 10,
                          color: Colors.white,
                        ),
                        Spacing.x(2),
                        Text(
                          provider.isBalanceHidden
                              ? AppTranslations.getText('show_balance')
                              : AppTranslations.getText('hide_balance'),
                          style:
                              const TextStyle(fontSize: 9, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              /// User name and ID
              Positioned(
                bottom: 8,
                left: 15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      driverName ?? 'Zara Ahmed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacing.x(7),
                    Text(
                      phoneNumber ?? '0779735666',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              /// Withdraw button
              Positioned(
                bottom: 10,
                right: MediaQuery.of(context).size.width * 0.02,
                child: SizedBox(
                  // width: 110,
                  height: 37,
                  child: ElevatedButton(
                    onPressed: () {
                      Nav.to(const WithdrawalOptionsPage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppTranslations.getText('withdraw'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                        Spacing.x(2),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.9549419, size.height * 0.0003319033);
    path_0.cubicTo(
        size.width * 0.9790233,
        size.height * 0.0003319033,
        size.width * 0.9985465,
        size.height * 0.04422556,
        size.width * 0.9985465,
        size.height * 0.09837124);
    path_0.lineTo(size.width * 0.9985465, size.height * 0.5364072);
    path_0.cubicTo(
        size.width * 0.9985465,
        size.height * 0.6013817,
        size.width * 0.9751192,
        size.height * 0.6540523,
        size.width * 0.9462209,
        size.height * 0.6540523);
    path_0.lineTo(size.width * 0.6504215, size.height * 0.6540523);
    path_0.cubicTo(
        size.width * 0.6215233,
        size.height * 0.6540523,
        size.width * 0.5980959,
        size.height * 0.7067255,
        size.width * 0.5980959,
        size.height * 0.7716993);
    path_0.lineTo(size.width * 0.5980959, size.height * 0.8810784);
    path_0.cubicTo(
        size.width * 0.5980959,
        size.height * 0.9460523,
        size.width * 0.5746686,
        size.height * 0.9987255,
        size.width * 0.5457703,
        size.height * 0.9987255);
    path_0.lineTo(size.width * 0.04505814, size.height * 0.9987255);
    path_0.cubicTo(
        size.width * 0.02097634,
        size.height * 0.9987255,
        size.width * 0.001454087,
        size.height * 0.9548301,
        size.width * 0.001453488,
        size.height * 0.9006863);
    path_0.lineTo(size.width * 0.001453488, size.height * 0.09837124);
    path_0.cubicTo(
        size.width * 0.001453503,
        size.height * 0.04422556,
        size.width * 0.02097596,
        size.height * 0.0003319033,
        size.width * 0.04505814,
        size.height * 0.0003319033);
    path_0.lineTo(size.width * 0.9549419, size.height * 0.0003319033);
    path_0.close();

    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.shader = ui.Gradient.linear(
        Offset(size.width * 0.5000000, size.height * 0.03319033),
        Offset(size.width * 0.5000000, size.height * 0.9987255), [
      AppColors.primary.withOpacity(1),
      AppColors.primary.withOpacity(1)
    ], [
      0,
      1
    ]);
    canvas.drawPath(path_0, paint0Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
