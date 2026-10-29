import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/bottmsheets/amonut_input_sheet.dart';
import 'package:blockatie/views/pages/wallet/withdrawl/components/withdrawal_options_widget.dart';
import 'package:blockatie/views/widgets/custom_elevated_btn.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';

class WithdrawalOptionsPage extends StatelessWidget {
  const WithdrawalOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: AppTranslations.getText('withdrawal'),
        subtitle: AppTranslations.getText('secure_fast_and_easy_withdrawal'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getText('select_withdrawal_option'),
              style:
                  textTheme.headlineSmall!.copyWith(color: AppColors.primary),
            ),
            Spacing.y(0.3),
            Text(
              AppTranslations.getText(
                  'choose_your_preferred_withdrawal_method'),
              style: textTheme.bodySmall!.copyWith(color: AppColors.textColor),
            ),
            Spacing.y(1),
            const WithdrawalOptionsWidget(),
            Spacing.y(6),
            Center(
              child: CustomElevatedBtn(
                label: AppTranslations.getText('continue'),
                borderRadius: 12,
                width: SizeConfig.widthMultiplier * 75,
                bgColor: AppColors.primary,
                textColor: Colors.white,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AmountInputSheet(),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
