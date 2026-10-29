import 'dart:ui' as ui;

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';

// void showConfirmationDialog(
//     BuildContext context, String? title, String? subtitle,) {
//   final textTheme = Theme.of(context).textTheme;

//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (BuildContext context) {
//       return Stack(
//         children: [
//           // Blurred background
//           BackdropFilter(
//             filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//             child: Container(
//               color: Colors.black.withOpacity(0.3),
//             ),
//           ),
//           // Dialog content
//           Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20.0),
//             ),
//             child: Container(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset(
//                     'assets/images/alert.png',
//                     width: 70, // Adjusted to match image size
//                     height: 70,
//                   ),
//                   const SizedBox(height: 16.0),
//                   Text(
//                     title ?? 'Confirmation of acceptance',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                   Spacing.y(1),
//                   Text(
//                     subtitle ??
//                         'Are you sure you want to deliver this shipment?',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 10.0, color: Colors.grey),
//                   ),
//                   Spacing.y(3),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           Navigator.pop(context); // Close dialog on Cancel
//                         },
//                         child: Container(
//                           height: SizeConfig.heightMultiplier * 5,
//                           width:
//                               SizeConfig.widthMultiplier * 30, // Adjusted width
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: AppColors.primary),
//                           ),
//                           child: Center(
//                             child: Text(
//                               "Cancel",
//                               style: textTheme.bodyMedium!.copyWith(
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Spacing.x(5), // Increased spacing between buttons
//                       InkWell(
//                         onTap:
//                         () {
//                           Navigator.pop(context);
//                           showAcceptanceDilaoge(context, 'Shipment Accepted!',
//                               'Shipment accepted successfully');
//                           // Navigator.pop(context); // Close dialog on Accept
//                         },
//                         child: Container(
//                           height: SizeConfig.heightMultiplier * 5,
//                           width:
//                               SizeConfig.widthMultiplier * 30, // Adjusted width
//                           decoration: BoxDecoration(
//                             color: AppColors.primary,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Center(
//                             child: Text(
//                               "Yes, Accept!",
//                               style: textTheme.bodyMedium!.copyWith(
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }

void showConfirmationDialog(
  BuildContext context,
  String? title,
  String? subtitle,
  VoidCallback onAccept, // 👈 Add this parameter
) {
  final textTheme = Theme.of(context).textTheme;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/alert.png',
                    width: 70,
                    height: 70,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    title ?? 'Confirmation of acceptance',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  Spacing.y(1),
                  Text(
                    subtitle ??
                        'Are you sure you want to deliver this shipment?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                  ),
                  Spacing.y(3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: SizeConfig.heightMultiplier * 5,
                          width: SizeConfig.widthMultiplier * 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Center(
                            child: Text(
                              AppTranslations.getText('cancel'),
                              style: textTheme.bodyMedium!.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Spacing.x(5),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onAccept(); // 👈 Invoke the callback
                        },
                        child: Container(
                          height: SizeConfig.heightMultiplier * 5,
                          width: SizeConfig.widthMultiplier * 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppTranslations.getText('yes_accept'),
                              style: textTheme.bodyMedium!.copyWith(
                                color: Colors.white,
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
          ),
        ],
      );
    },
  );
}
