import 'package:flutter/material.dart';
import 'package:blockatie/services/firebase_service.dart';

class FirebaseTest {
  // Test Firebase initialization
  static Future<bool> testFirebaseInitialization() async {
    try {
      await FirebaseService.initialize();
      debugPrint('✅ Firebase initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      return false;
    }
  }

  // Test FCM token generation
  static Future<bool> testFCMToken() async {
    try {
      final token = await FirebaseService.getStoredFCMToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token generated');
        return true;
      } else {
        debugPrint('❌ FCM Token not generated');
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCM Token test failed: $e');
      return false;
    }
  }

  // Test topic subscription
  static Future<bool> testTopicSubscription() async {
    try {
      debugPrint('🧪 Testing topic subscription to "test_topic"...');
      final result = await FirebaseService.subscribeToTopic('test_topic');
      if (result) {
        debugPrint('✅ Topic subscription test successful');
        return true;
      } else {
        debugPrint('❌ Topic subscription test failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Topic subscription test failed: $e');
      return false;
    }
  }

  // Test topic unsubscription
  static Future<bool> testTopicUnsubscription() async {
    try {
      debugPrint('🧪 Testing topic unsubscription from "test_topic"...');
      final result = await FirebaseService.unsubscribeFromTopic('test_topic');
      if (result) {
        debugPrint('✅ Topic unsubscription test successful');
        return true;
      } else {
        debugPrint('❌ Topic unsubscription test failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Topic unsubscription test failed: $e');
      return false;
    }
  }

  // Test owner-specific topic subscriptions
  static Future<bool> testUserTopicSubscriptions() async {
    try {
      debugPrint('🧪 Testing owner-specific topic subscriptions...');

      // Test subscription to owner topic
      final ownerTopicResult =
          await FirebaseService.subscribeToTopic('owner_test123');
      if (ownerTopicResult) {
        debugPrint('✅ Owner topic subscription successful');
      } else {
        debugPrint('❌ Owner topic subscription failed');
      }

      // Test subscription to all owners
      final allOwnersTopicResult =
          await FirebaseService.subscribeToTopic('allowners');
      if (allOwnersTopicResult) {
        debugPrint('✅ All owners topic subscription successful');
      } else {
        debugPrint('❌ All owners topic subscription failed');
      }

      final successCount = [ownerTopicResult, allOwnersTopicResult]
          .where((result) => result)
          .length;
      debugPrint(
          '📊 Owner topic subscription summary: $successCount/2 topics subscribed successfully');

      return successCount == 2;
    } catch (e) {
      debugPrint('❌ Owner topic subscription test failed: $e');
      return false;
    }
  }

  // Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};

    debugPrint('🧪 Starting Firebase Tests...');

    results['initialization'] = await testFirebaseInitialization();
    results['fcm_token'] = await testFCMToken();
    results['topic_subscription'] = await testTopicSubscription();
    results['topic_unsubscription'] = await testTopicUnsubscription();
    results['user_topic_subscriptions'] = await testUserTopicSubscriptions();

    debugPrint('🧪 Firebase Tests Completed:');
    results.forEach((test, result) {
      debugPrint('${result ? '✅' : '❌'} $test');
    });

    return results;
  }

  // Show test results in a dialog
  static void showTestResults(BuildContext context, Map<String, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: results.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.error,
                    color: entry.value ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
