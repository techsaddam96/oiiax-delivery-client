// import 'package:blockatie/constants/colors.dart';
// import 'package:blockatie/utils/size_config.dart';
// import 'package:blockatie/utils/spacing.dart';
// import 'package:blockatie/views/widgets/cutom-appbar.dart';
// import 'package:flutter/material.dart';

// class LocationOrderPage extends StatelessWidget {
//   const LocationOrderPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgColor,
//       appBar: const CustomAppBar(
//         title: 'Location Order',
//         subtitle: 'Custom order for visiting locations.',
//       ),
//       body: Column(
//         children: [
//           // Map Section
//           Expanded(
//             flex: 5,
//             child: Stack(
//               children: [
//                 Image.asset(
//                   'assets/images/map.png',
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ],
//             ),
//           ),

//           // Order Details Section
//           Expanded(
//             flex: 4,
//             child: Container(
//               padding: const EdgeInsets.all(0),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
//               ),
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       children: [
//                         Container(
//                           width: SizeConfig.widthMultiplier * 15,
//                           height: 3,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[500],
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                         Spacing.y(1.5),
//                         const Text(
//                           'New Order!',
//                           style: TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Spacing.y(2),

//                   // Full-width Divider with no horizontal padding
//                   const Divider(thickness: 1, height: 1),

//                   const SizedBox(height: 16),

//                   // Order Distance Row
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Image.asset(
//                               'assets/images/order_distance.png',
//                               width: 22,
//                               height: 22,
//                             ),
//                             const SizedBox(width: 8),
//                             const Text(
//                               "Order Distance",
//                               style: TextStyle(fontSize: 14),
//                             ),
//                             const Spacer(),
//                             Text(
//                               "6.5 km",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.red.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Spacing.y(3),
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Column(
//                               children: [
//                                 Image.asset(
//                                   'assets/images/location.png',
//                                   width: 22,
//                                   height: 22,
//                                   color: Colors.grey,
//                                 ),
//                                 // Dotted line manually drawn
//                                 Container(
//                                   width: 1,
//                                   height: 25,
//                                   margin:
//                                       const EdgeInsets.symmetric(vertical: 2),
//                                   child: CustomPaint(
//                                     painter: DottedLinePainter(),
//                                   ),
//                                 ),
//                                 Image.asset(
//                                   'assets/images/location.png',
//                                   width: 22,
//                                   height: 22,
//                                   color: Colors.red,
//                                   ),
//                               ],
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     "2750 S. Maryland Pkwys Las Vegas",
//                                     style: TextStyle(
//                                         fontSize: 13, color: Colors.black87),
//                                   ),
//                                   Spacing.y(4),
//                                   const Text(
//                                     "2479–2547 Vegas Dr. Bonanza",
//                                     style: TextStyle(
//                                         fontSize: 13, color: Colors.black87),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         Spacing.y(2),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: () {},
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.redAccent,
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 14),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: const Text("Track Order",
//                                     style: TextStyle(color: Colors.white)),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: () {},
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF3B60E4),
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 14),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: const Text("Call Customer",
//                                     style: TextStyle(color: Colors.white)),
//                               ),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                   Spacing.y(3),

//                   // Address with dotted line in between
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// // CustomPainter to draw vertical dotted line
// class DottedLinePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     const double dashHeight = 3;
//     const double dashSpace = 3;
//     double startY = 0;
//     final paint = Paint()
//       ..color = Colors.grey
//       ..strokeWidth = 1;

//     while (startY < size.height) {
//       canvas.drawLine(
//         Offset(0, startY),
//         Offset(0, startY + dashHeight),
//         paint,
//       );
//       startY += dashHeight + dashSpace;
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';

class LocationOrderPage extends StatelessWidget {
  const LocationOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: AppTranslations.getText('location_order'),
        subtitle:
            AppTranslations.getText('custom_order_for_visiting_locations'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            SizedBox(
              height: SizeConfig.heightMultiplier *
                  40, // Set a fixed height for the map
              width: double.infinity,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/map.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),

            // Order Details Section
            Container(
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          width: SizeConfig.widthMultiplier * 15,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[500],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Spacing.y(1.5),
                        Text(
                          AppTranslations.getText('new_order'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Spacing.y(2),

                  // Full-width Divider with no horizontal padding
                  const Divider(thickness: 1, height: 1),

                  const SizedBox(height: 16),

                  // Order Distance Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/order_distance.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppTranslations.getText('order_distance'),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              "6.5 km",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                        Spacing.y(3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Image.asset(
                                  'assets/images/location.png',
                                  width: 22,
                                  height: 22,
                                  color: Colors.grey,
                                ),
                                // Dotted line manually drawn
                                Container(
                                  width: 1,
                                  height: 25,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: CustomPaint(
                                    painter: DottedLinePainter(),
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/location.png',
                                  width: 22,
                                  height: 22,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "2750 S. Maryland Pkwys Las Vegas",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.black87),
                                  ),
                                  Spacing.y(4),
                                  const Text(
                                    "2479–2547 Vegas Dr. Bonanza",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Spacing.y(2),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                    AppTranslations.getText('track_order'),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B60E4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                    AppTranslations.getText('call_customer'),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Spacing.y(3),
                ],
              ),
            ),
            // Add extra space at the bottom to ensure content is not cut off
            SizedBox(height: SizeConfig.heightMultiplier * 2),
          ],
        ),
      ),
    );
  }
}

// CustomPainter to draw vertical dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 3;
    const double dashSpace = 3;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
