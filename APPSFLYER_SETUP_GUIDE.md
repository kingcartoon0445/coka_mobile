# Hướng dẫn Setup AppsFlyer cho Coka Mobile App

## 1. Cấu hình Keys

### Bước 1: Cập nhật Dev Key và App ID

Mở file `lib/services/appsflyer_service.dart` và thay thế các giá trị sau:

```dart
// Thay thế bằng Dev Key thực tế từ AppsFlyer dashboard
static const String _devKey = "YOUR_APPSFLYER_DEV_KEY";

// App ID cho iOS (từ App Store Connect)
static const String _appId = "YOUR_IOS_APP_ID";
```

### Bước 2: Lấy Dev Key từ AppsFlyer Dashboard

1. Đăng nhập vào [AppsFlyer Dashboard](https://hq1.appsflyer.com/)
2. Vào App Settings → App Configuration
3. Copy Dev Key và thay thế trong code

### Bước 3: Lấy App ID cho iOS

1. Vào [App Store Connect](https://appstoreconnect.apple.com/)
2. Chọn app của bạn
3. Copy App ID (dạng số) và thay thế trong code

## 2. Cấu hình Platform-specific

### iOS Configuration

Thêm vào `ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app would like to advertise and measure advertising efficiency.</string>
```

### Android Configuration

Thêm vào `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- ... existing configuration ... -->
    
    <!-- AppsFlyer Configuration -->
    <receiver android:name="com.appsflyer.SingleInstallBroadcastReceiver" android:exported="false">
        <intent-filter>
            <action android:name="com.android.vending.INSTALL_REFERRER" />
        </intent-filter>
    </receiver>
</application>
```

## 3. Sử dụng trong ứng dụng

### Track Events đơn giản

```dart
import 'package:coka/providers/appsflyer_provider.dart';

// Track event đơn giản
AppsFlyerProvider.logEvent('button_clicked');

// Track event với parameters
AppsFlyerProvider.logEvent('page_viewed', {
  'page_name': 'customer_detail',
  'customer_id': '123'
});
```

### Track Predefined Events

```dart
// Track đăng ký
AppsFlyerProvider.logRegistration(method: 'email');

// Track đăng nhập
AppsFlyerProvider.logLogin(method: 'google');

// Track mua hàng
AppsFlyerProvider.logPurchase(
  revenue: 99.99,
  currency: 'VND',
  orderId: 'order_123',
);
```

### Track Custom Events cho Coka App

```dart
// Thêm khách hàng mới
AppsFlyerProvider.logCustomerAdded(
  source: 'facebook',
  method: 'manual_entry'
);

// Gửi tin nhắn
AppsFlyerProvider.logMessageSent(
  platform: 'facebook',
  type: 'text'
);

// Tạo campaign
AppsFlyerProvider.logCampaignCreated(type: 'automation');

// Xem báo cáo
AppsFlyerProvider.logReportViewed(reportType: 'revenue');
```

### Set User ID

```dart
// Set user ID khi user đăng nhập
await AppsFlyerProvider.setCustomerUserId('user_123');
```

### Lấy AppsFlyer ID

```dart
// Lấy unique AppsFlyer ID
String? appsflyerId = await AppsFlyerProvider.getAppsFlyerId();
print('AppsFlyer ID: $appsflyerId');
```

## 4. Sử dụng với Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/providers/appsflyer_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsflyerIdAsync = ref.watch(appsFlyerIdProvider);
    
    return appsflyerIdAsync.when(
      data: (id) => Text('AppsFlyer ID: $id'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## 5. Deep Links

AppsFlyer service tự động handle deep links. Khi có deep link, nó sẽ print ra console:

```
🔗 Deep link received: your-app://customer/123
```

Để implement navigation từ deep link, cập nhật method `_handleDeepLink` trong `AppsFlyerService`:

```dart
static void _handleDeepLink(DeepLinkResult result) {
  final String? deepLinkValue = result.deepLink?.deepLinkValue;
  
  if (deepLinkValue != null) {
    // Parse deep link và navigate
    if (deepLinkValue.contains('/customer/')) {
      final customerId = deepLinkValue.split('/customer/')[1];
      // Navigate to customer detail page
      navigatorKey.currentState?.pushNamed('/customer/$customerId');
    }
  }
}
```

## 6. Debugging

Trong development mode, AppsFlyer sẽ tự động hiển thị debug logs:

```
✅ AppsFlyer SDK initialized successfully
📊 AppsFlyer event logged: customer_added with parameters: {source: facebook, method: manual_entry}
🔗 Deep link received: your-app://customer/123
```

## 7. Production Checklist

- [ ] Thay thế `YOUR_APPSFLYER_DEV_KEY` bằng dev key thực tế
- [ ] Thay thế `YOUR_IOS_APP_ID` bằng iOS app ID thực tế
- [ ] Test conversion tracking
- [ ] Test deep links
- [ ] Verify events appear trong AppsFlyer dashboard
- [ ] Set up custom audiences và retargeting campaigns

## 8. Các Events quan trọng cho Coka App

| Event | Mô tả | Parameters |
|-------|-------|------------|
| `af_complete_registration` | User đăng ký thành công | `method` |
| `af_login` | User đăng nhập | `method` |
| `customer_added` | Thêm khách hàng mới | `source`, `method` |
| `message_sent` | Gửi tin nhắn | `platform`, `type` |
| `campaign_created` | Tạo campaign | `type` |
| `automation_created` | Tạo automation | `type` |
| `report_viewed` | Xem báo cáo | `report_type` |
| `workspace_created` | Tạo workspace | - |
| `organization_created` | Tạo organization | - |

## 9. Support

Nếu có vấn đề với AppsFlyer integration:

1. Kiểm tra console logs để xem debug information
2. Verify dev key và app ID correct
3. Check AppsFlyer dashboard để xem events có appear không
4. Tham khảo [AppsFlyer Flutter documentation](https://dev.appsflyer.com/hc/docs/flutter-plugin) 