import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        //BACKGROUND
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.heightMultiplier * 2,
            horizontal: SizeConfig.widthMultiplier * 5,
          ),
          child: Image.asset("assets/images/balance_card_bg.png"),
        ),
        //DETAILS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: SizeConfig.heightMultiplier * 8,
              width: SizeConfig.widthMultiplier * 18,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset("assets/icons/wallet_2.png"),
              ),
            ),
            Spacing.x(5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, _) {
                    final balance =
                        profileProvider.statistics?.balanceTotal ?? '—';
                    return Text(
                      balance,
                      style: textTheme.headlineMedium!
                          .copyWith(color: Colors.white),
                    );
                  },
                ),

                // Text(
                //   "60.00 JOD",
                //   style:
                //       textTheme.headlineMedium!.copyWith(color: Colors.white),
                // ),
                Text(
                  AppTranslations.getText(
                      'total_balance_of_shipments_accrued1'),
                  style: textTheme.bodySmall!.copyWith(color: Colors.white),
                )
              ],
            )
          ],
        )
      ],
    );
  }
}
