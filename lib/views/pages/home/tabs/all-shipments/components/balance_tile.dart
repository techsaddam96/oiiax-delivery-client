// import 'package:blockatie/utils/size_config.dart';
// import 'package:flutter/material.dart';

// class BalanceTile extends StatelessWidget {
//   const BalanceTile({
//     super.key,
//     required this.balance,
//     required this.subtitle,
//     required this.isDue,
//   });
//   final double balance;
//   final String subtitle;
//   final bool isDue;

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//     return Padding(
//       padding: EdgeInsets.symmetric(
//           horizontal: SizeConfig.widthMultiplier * 0,
//           vertical: SizeConfig.heightMultiplier * 1),
//       child: Container(
//         height: SizeConfig.heightMultiplier * 12,
//         // width: SizeConfig.widthMultiplier * 30,
//         decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10), color: Colors.white),
//         // padding:
//         //     EdgeInsets.symmetric(horizontal: SizeConfig.widthMultiplier * 5),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: Row(
//           children: [
//             Container(
//               height: SizeConfig.heightMultiplier * 6.5,
//               width: SizeConfig.widthMultiplier * 13,
//               decoration: BoxDecoration(
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withValues(alpha: .05),
//                         blurRadius: 5.57,
//                         offset: const Offset(0, 11))
//                   ],
//                   borderRadius: BorderRadius.circular(12),
//                   color: (isDue
//                           ? const Color(0xFFFF2147)
//                           : const Color(0xFF26BF94))
//                       .withValues(alpha: .15)),
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Image.asset(isDue
//                     ? "assets/icons/curly_arrow_down.png"
//                     : "assets/icons/curly_arrow_up.png"),
//               ),
//             ),
//             // Spacing.x(3),
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Driver balance is due", style: textTheme.bodySmall),
//                 Text(
//                   "8.25 JOD",
//                   style: textTheme.bodyLarge!.copyWith(
//                     // fontSize: SizeConfig.textMultiplier * 1.2,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 // Spacing.y(.3),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// extension ColorWithValues on Color {
//   Color withValues({double? alpha}) {
//     return withOpacity(alpha ?? 1.0);
//   }
// }

import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final String amount;
  final String description;
  final String iconPath;
  final Color iconColor;

  const BalanceCard({
    super.key,
    required this.amount,
    required this.description,
    required this.iconPath,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRTL = AppLocalizations.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.only(
          left: isRTL ? 0 : 10,
          right: isRTL ? 10 : 0,
          top: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                iconPath,
                width: 20,
                height: 20,
              ),
            ),
            Spacing.x(2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: textTheme.bodySmall!.copyWith(
                      color: Colors.black,
                      fontSize: 8,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                  Text(
                    amount,
                    style: textTheme.bodyMedium!.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
            Spacing.x(3),
          ],
        ),
      ),
    );
  }
}
