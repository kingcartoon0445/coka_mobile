# Firebase Cloud Messaging (FCM) Integration Guide

## 📋 Tổng quan
Dự án đã được tích hợp đầy đủ Firebase Cloud Messaging với các tính năng:

- ✅ Push notification từ server
- ✅ Xử lý notification khi app foreground/background/terminated
- ✅ Navigation tự động khi tap notification
- ✅ Topic subscription (organization/workspace)
- ✅ FCM token management
- ✅ UI quản lý cài đặt notification

## 🔧 Các thành phần đã được thêm

### 1. Dependencies
```yaml
# pubspec.yaml
firebase_messaging: ^15.0.4
```

### 2. Core Services
- `lib/services/fcm_service.dart` - Service chính xử lý FCM
- `lib/providers/fcm_provider.dart` - Riverpod providers cho FCM state management

### 3. UI Components
- `lib/shared/widgets/notification_settings_widget.dart` - Widget cài đặt notification

### 4. Configuration Files
- Android permissions đã được thêm vào `AndroidManifest.xml`
- Background message handler trong `main.dart`
- FCM initialization trong app startup

## 🚀 Cách sử dụng

### 1. Khởi tạo FCM (Đã tự động)
FCM được khởi tạo tự động khi app start up trong `main.dart`:

```dart
// Tự động request permission và get token
await FCMService.initialize(context: context);
```

### 2. Sử dụng Notification Settings Widget
```dart
import '../shared/widgets/notification_settings_widget.dart';

// Trong UI
NotificationSettingsWidget(
  organizationId: 'org_123',
  workspaceId: 'workspace_456',
)
```

### 3. Subscribe/Unsubscribe Topics
```dart
// Sử dụng FCMProviderHelpers
await FCMProviderHelpers.subscribeToOrganizationTopic(ref, organizationId);
await FCMProviderHelpers.subscribeToWorkspaceTopic(ref, workspaceId);
```

### 4. Lấy FCM Token
```dart
// Trong widget với Consumer
Consumer(
  builder: (context, ref, child) {
    final fcmToken = ref.watch(fcmTokenProvider);
    return fcmToken.when(
      data: (token) => Text('Token: $token'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)
```

## 📱 Cấu trúc Notification Payload

### Server gửi notification với format:
```json
{
  "notification": {
    "title": "Tiêu đề thông báo",
    "body": "Nội dung thông báo"
  },
  "data": {
    "route": "customer_detail", // customer_detail, workspace, organization, messages
    "organizationId": "org_123",
    "workspaceId": "workspace_456", 
    "customerId": "customer_789",
    "notificationId": "notify_101"
  }
}
```

### Các route types hỗ trợ:
- `customer_detail` → `/organization/{orgId}/workspace/{workspaceId}/customer/{customerId}`
- `workspace` → `/organization/{orgId}/workspace/{workspaceId}`
- `organization` → `/organization/{orgId}`
- `messages` → `/organization/{orgId}/messages`

## 🔍 Testing FCM

### 1. Test từ Firebase Console
1. Vào [Firebase Console](https://console.firebase.google.com)
2. Chọn project `coka-crm`
3. Vào Messaging → Send your first message
4. Nhập title, body và target (token hoặc topic)

### 2. Test từ terminal (với FCM token)
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "route": "organization",
      "organizationId": "default"
    }
  }'
```

### 3. Test Topics
```bash
# Send to topic
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/org_123",
    "notification": {
      "title": "Organization Update",
      "body": "New update for organization"
    }
  }'
```

## 🛠 Debug và Troubleshooting

### 1. Kiểm tra FCM Token
```dart
final token = await FCMService.getToken();
print('Current FCM Token: $token');
```

### 2. Kiểm tra Notification Permission
```dart
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Permission status: ${settings.authorizationStatus}');
```

### 3. Console Logs
App sẽ log các sự kiện FCM với emoji prefixes:
- 🔔 FCM initialization
- 📨 Received messages
- 🔄 Token refresh
- ✅ Success operations
- ❌ Errors

### 4. Common Issues

**Notification không hiển thị:**
- Kiểm tra permission: `Settings > Notifications > Coka`
- Kiểm tra payload format
- Kiểm tra FCM token validity

**Navigation không hoạt động:**
- Kiểm tra data payload có đủ thông tin route không
- Kiểm tra GoRouter routes

**Background messages không nhận được:**
- Kiểm tra background handler được register đúng chưa
- iOS: kiểm tra Background App Refresh

## 📊 Monitoring

### 1. FCM Analytics
Sử dụng Firebase Console để monitor:
- Message delivery rates
- Open rates
- Device registration

### 2. App Logs
Check console logs với patterns:
```bash
# Filter FCM logs
flutter logs | grep "🔔\|📨\|🔄\|✅\|❌"
```

## 🔄 Updates và Maintenance

### 1. Dependency Updates
```bash
flutter pub upgrade firebase_messaging
```

### 2. Token Refresh Handling
FCM tokens được tự động refresh và sync với server thông qua:
- `NotificationRepository.updateFCMToken()`
- Auto-retry mechanism

### 3. Topic Management
Topics được manage tự động khi user:
- Join/leave organization
- Join/leave workspace

## 🎯 Next Steps

1. **Server Integration**: Đảm bảo backend API sử dụng FCM tokens để gửi notifications
2. **Advanced Features**: 
   - Notification categories
   - Rich media notifications
   - Notification actions
3. **Analytics**: Track notification engagement metrics
4. **Personalization**: User-specific notification preferences

## 📝 API Documentation

### FCMService Methods
```dart
// Initialize FCM
static Future<void> initialize({BuildContext? context})

// Get current token
static Future<String?> getToken()

// Subscribe/unsubscribe topics
static Future<void> subscribeToTopic(String topic)
static Future<void> unsubscribeFromTopic(String topic)

// Update context for navigation
static void updateContext(BuildContext context)
```

### FCMProviderHelpers Methods
```dart
// Organization topics
static Future<void> subscribeToOrganizationTopic(WidgetRef ref, String orgId)
static Future<void> unsubscribeFromOrganizationTopic(WidgetRef ref, String orgId)

// Workspace topics  
static Future<void> subscribeToWorkspaceTopic(WidgetRef ref, String workspaceId)
static Future<void> unsubscribeFromWorkspaceTopic(WidgetRef ref, String workspaceId)

// Get current token
static Future<String?> getCurrentToken(WidgetRef ref)
```

---

✅ **FCM Integration hoàn tất!** App đã sẵn sàng nhận và xử lý push notifications từ Firebase Cloud Messaging. 