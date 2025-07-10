import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fcm_service.dart';

// FCM Token Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return await FCMService.getToken();
});

// FCM Service Provider - cung cấp static methods
final fcmServiceProvider = Provider((ref) {
  return FCMService;
});

// Notification Permission Status Provider
final notificationPermissionProvider = StateProvider<bool>((ref) {
  return false;
});

// FCM Topics Subscription Provider
class FCMTopicsNotifier extends StateNotifier<Set<String>> {
  FCMTopicsNotifier() : super(<String>{});

  Future<void> subscribeToTopic(String topic) async {
    await FCMService.subscribeToTopic(topic);
    state = {...state, topic};
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FCMService.unsubscribeFromTopic(topic);
    final newState = Set<String>.from(state);
    newState.remove(topic);
    state = newState;
  }

  void setSubscribedTopics(Set<String> topics) {
    state = topics;
  }
}

final fcmTopicsProvider = StateNotifierProvider<FCMTopicsNotifier, Set<String>>((ref) {
  return FCMTopicsNotifier();
});

// Helper methods for common FCM operations
class FCMProviderHelpers {
  static Future<void> subscribeToOrganizationTopic(WidgetRef ref, String organizationId) async {
    final topicsNotifier = ref.read(fcmTopicsProvider.notifier);
    await topicsNotifier.subscribeToTopic('org_$organizationId');
  }

  static Future<void> subscribeToWorkspaceTopic(WidgetRef ref, String workspaceId) async {
    final topicsNotifier = ref.read(fcmTopicsProvider.notifier);
    await topicsNotifier.subscribeToTopic('workspace_$workspaceId');
  }

  static Future<void> unsubscribeFromOrganizationTopic(WidgetRef ref, String organizationId) async {
    final topicsNotifier = ref.read(fcmTopicsProvider.notifier);
    await topicsNotifier.unsubscribeFromTopic('org_$organizationId');
  }

  static Future<void> unsubscribeFromWorkspaceTopic(WidgetRef ref, String workspaceId) async {
    final topicsNotifier = ref.read(fcmTopicsProvider.notifier);
    await topicsNotifier.unsubscribeFromTopic('workspace_$workspaceId');
  }

  static Future<String?> getCurrentToken(WidgetRef ref) async {
    final tokenAsyncValue = ref.read(fcmTokenProvider);
    return tokenAsyncValue.whenOrNull(
      data: (token) => token,
      error: (_, __) => null,
      loading: () => null,
    );
  }
} 