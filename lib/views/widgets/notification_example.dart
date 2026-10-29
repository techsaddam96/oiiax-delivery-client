import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockatie/provider/notification_provider.dart';
import 'package:blockatie/utils/notification_permission_helper.dart';
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/app_utils.dart';

class NotificationExample extends StatelessWidget {
  const NotificationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseNotificationProvider>(
      builder: (context, notificationProvider, _) {
        return Column(
          children: [
            // Notification Permission Status
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          notificationProvider.fcmToken != null
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: notificationProvider.fcmToken != null
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notificationProvider.fcmToken != null
                                ? 'Notifications enabled'
                                : 'Notifications disabled',
                            style: TextStyle(
                              color: notificationProvider.fcmToken != null
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificationProvider.fcmToken != null
                          ? 'FCM Token: available'
                          : 'FCM Token: not available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notification Actions
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await NotificationPermissionHelper
                                  .showPermissionDialogIfNeeded(context);
                            },
                            icon: const Icon(Icons.notifications),
                            label: const Text('Request Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              notificationProvider
                                  .subscribeToTopic('test_topic');
                              AppUtils.showSuccessDialog(
                                  'Subscribed to test_topic');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Subscribe to Topic'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              notificationProvider
                                  .unsubscribeFromTopic('test_topic');
                              AppUtils.showSuccessDialog(
                                  'Unsubscribed from test_topic');
                            },
                            icon: const Icon(Icons.remove),
                            label: const Text('Unsubscribe from Topic'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              notificationProvider.clearNotifications();
                              AppUtils.showSuccessDialog(
                                  'Notifications cleared');
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Notification List
            if (notificationProvider.notifications.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Recent Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${notificationProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...notificationProvider.notifications
                          .take(5)
                          .map((notification) {
                        return ListTile(
                          leading: Icon(
                            notification['isRead'] == true
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread,
                            color: notification['isRead'] == true
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          title: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: notification['isRead'] == true
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            notification['body'] ?? 'No content',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            notification['timestamp'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            final index = notificationProvider.notifications
                                .indexOf(notification);
                            notificationProvider.markAsRead(index);
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
