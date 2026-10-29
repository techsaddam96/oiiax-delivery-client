import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShipmentCard extends StatelessWidget {
  final ProfileProvider profileProvider;

  const ShipmentCard({super.key, required this.profileProvider});

  @override
  Widget build(BuildContext context) {
    final profile = profileProvider.profileInfo;
    final location = profileProvider.location ?? 'Unknown';
    final imageWidget = profileProvider.getProfileImageWidget();

    // Check if current language is Arabic for RTL support
    final isRTL = AppLocalizations.isRTL;

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C80FC), Color(0xFF5CA8F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: AssetImage("assets/images/balance_card_bg.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              children: [
                /// ✅ Dynamic Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: imageWidget,
                  ),
                ),

                Spacing.x(2),

                /// ✅ Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.nclient ?? '---',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                      Text(
                        profileProvider.streetNumber ?? 'Street No 1',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// ✅ Phone + Location Icons
                Column(
                  crossAxisAlignment:
                      isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isRTL
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/phone.png',
                            width: 15,
                            height: 15,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              profile?.phclient ?? '---',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          // _showLocationBottomSheet(context, location);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/location.png',
                              width: 15,
                              height: 15,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                final stats = provider.statistics;

                if (stats == null) {
                  return Center(
                    child: provider.isLoadingStatistics
                        ? const CircularProgressIndicator()
                        : Text(provider.statisticsError ?? '—'),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ShipmentStat(
                        title: AppTranslations.getText('shipments'),
                        value: stats.shipments.toString(),
                        isRTL: isRTL,
                      ),
                    ),
                    Expanded(
                      child: ShipmentStat(
                        title: AppTranslations.getText('shipments_in_progress'),
                        value: stats.shipmentsInProgress.toString(),
                        isRTL: isRTL,
                      ),
                    ),
                    Expanded(
                      child: ShipmentStat(
                        title: AppTranslations.getText('shipments_delivered'),
                        value: stats.shipmentsDelivered.toString(),
                        isRTL: isRTL,
                      ),
                    ),
                    Expanded(
                      child: ShipmentStat(
                        title: AppTranslations.getText('cancelled_shipments'),
                        value: stats.cancelledShipments.toString(),
                        isRTL: isRTL,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // void _showLocationBottomSheet(BuildContext context, String location) {
  //   // Check if current language is Arabic for RTL support
  //   final isRTL = AppLocalizations.isRTL;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (BuildContext context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(context).viewInsets.bottom,
  //         ),
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.7,
  //           padding: const EdgeInsets.all(20),
  //           child: Directionality(
  //             textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
  //             child: Column(
  //               crossAxisAlignment:
  //                   isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
  //               children: [
  //                 // Header
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       AppTranslations.getText('location_details'),
  //                       style: TextStyle(
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.black,
  //                       ),
  //                       textAlign: isRTL ? TextAlign.right : TextAlign.left,
  //                     ),
  //                     IconButton(
  //                       onPressed: () => Navigator.of(context).pop(),
  //                       icon: Icon(Icons.close),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 15),

  //                 // Location Text
  //                 Container(
  //                   width: double.infinity,
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey[100],
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(color: Colors.grey[300]!),
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: isRTL
  //                         ? CrossAxisAlignment.end
  //                         : CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         mainAxisAlignment: isRTL
  //                             ? MainAxisAlignment.end
  //                             : MainAxisAlignment.start,
  //                         children: [
  //                           if (isRTL) ...[
  //                             Text(
  //                               AppTranslations.getText('current_location'),
  //                               style: TextStyle(
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Colors.grey[700],
  //                               ),
  //                             ),
  //                             const SizedBox(width: 8),
  //                             Icon(Icons.location_on,
  //                                 color: Colors.blue, size: 20),
  //                           ] else ...[
  //                             Icon(Icons.location_on,
  //                                 color: Colors.blue, size: 20),
  //                             const SizedBox(width: 8),
  //                             Text(
  //                               AppTranslations.getText('current_location'),
  //                               style: TextStyle(
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Colors.grey[700],
  //                               ),
  //                             ),
  //                           ],
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         location,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           color: Colors.black87,
  //                           height: 1.4,
  //                         ),
  //                         textAlign: isRTL ? TextAlign.right : TextAlign.left,
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 const SizedBox(height: 20),

  //                 // Map Placeholder
  //                 Expanded(
  //                   child: Container(
  //                     width: double.infinity,
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[200],
  //                       borderRadius: BorderRadius.circular(12),
  //                       border: Border.all(color: Colors.grey[300]!),
  //                     ),
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Icon(
  //                           Icons.map,
  //                           size: 64,
  //                           color: Colors.grey[400],
  //                         ),
  //                         const SizedBox(height: 16),
  //                         Text(
  //                           AppTranslations.getText('map_view'),
  //                           style: TextStyle(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.w600,
  //                             color: Colors.grey[600],
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                         const SizedBox(height: 8),
  //                         Text(
  //                           "${AppTranslations.getText('location_label')} $location",
  //                           textAlign: TextAlign.center,
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Colors.grey[500],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),

  //                 const SizedBox(height: 20),

  //                 // Action Buttons
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: ElevatedButton.icon(
  //                         onPressed: () => _openInMaps(location),
  //                         icon: Icon(Icons.directions, color: Colors.white),
  //                         label: Text(AppTranslations.getText('directions')),
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.blue,
  //                           padding: const EdgeInsets.symmetric(vertical: 12),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Expanded(
  //                       child: ElevatedButton.icon(
  //                         onPressed: () => _copyToClipboard(context, location),
  //                         icon: Icon(Icons.copy, color: Colors.white),
  //                         label: Text(AppTranslations.getText('copy')),
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.green,
  //                           padding: const EdgeInsets.symmetric(vertical: 12),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _openInMaps(String location) async {
  //   final url =
  //       'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
  //   if (await canLaunchUrl(Uri.parse(url))) {
  //     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //   }
  // }

  // void _copyToClipboard(BuildContext context, String location) {
  //   // For now, we'll just show a snackbar since clipboard functionality requires additional packages
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text('${AppTranslations.getText('location_copied')} $location'),
  //       duration: const Duration(seconds: 2),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  // }
}

class ShipmentStat extends StatelessWidget {
  final String title;
  final String value;
  final bool isRTL;

  const ShipmentStat(
      {super.key,
      required this.title,
      required this.value,
      required this.isRTL});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
