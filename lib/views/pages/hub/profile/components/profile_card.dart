import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          // Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/images/balance_card_bg.png",
              width: double.infinity,
              fit: BoxFit.cover,
              height: 180,
            ),
          ),

// Foreground Content
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row with Padding
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Consumer<ProfileProvider>(
                    builder: (context, provider, _) {
                      final profile = provider.profileInfo;
                      final imageUrl = profile?.loshop.isNotEmpty == true
                          ? 'https://dashboard.blockatie.com${profile!.loshop}'
                          : null;
                      final name = profile?.nclient ?? '';

                      return Row(
                        children: [
                          // 👇 Exact same non-rounded design, just with dynamic image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: imageUrl != null
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage(
                                          "assets/images/person.jpeg")
                                      as ImageProvider,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Spacing.x(2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/active-status.png',
                                        width: 10,
                                        height: 10,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppTranslations.getText('active'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacing.y(1),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Bottom Row with Orders and Balance
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Consumer<ProfileProvider>(
                    builder: (context, provider, _) {
                      final statistics = provider.statistics;

                      return Row(
                        children: [
                          // Orders
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Image.asset(
                                    'assets/images/no_oforders.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTranslations.getText(
                                            'number_of_orders'),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        statistics?.shipments.toString() ?? "0",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),

                          // Balance
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppTranslations.getText(
                                            'total_balance'),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        statistics?.balanceTotal ?? "0.00 JOD",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
