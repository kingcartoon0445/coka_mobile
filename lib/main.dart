// 🌐 Flutter & Packages
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

// 🧱 Core
import 'api/api_client.dart';
// 🧠 Bloc
import 'bloc/messages_connection/messages_connection_cubit.dart';
import 'core/theme/app_theme.dart';
// 🔥 Firebase & Services
import 'firebase_options.dart';
// 🌍 Localization
import 'l10n/vi_messages.dart';
// 🔀 Routing
import 'router.dart';
import 'services/appsflyer_service.dart';
import 'services/fcm_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 🔐 Init services
  await ApiClient().init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await AppsFlyerService.initialize();

  // 📦 Read local storage
  final token = await ApiClient.storage.read(key: 'access_token');
  final orgId = await ApiClient.storage.read(key: 'default_organization_id') ?? 'default';

  // 🚦 Routing setup
  final initialLocation = token != null ? '/organization/$orgId' : '/';
  final router = createAppRouter(initialLocation);

  // 🕒 TimeAgo (VN)
  timeago.setLocaleMessages('vi', CustomViMessages());

  // 🚀 Run app
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('vi', 'VN'),
      child: ProviderScope(
        child: MyApp(router: router, orgId: orgId),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final String orgId;

  const MyApp({super.key, required this.router, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MessagesConnectionCubit()..initialize(orgId),
        ),
      ],
      child: MaterialApp.router(
        title: 'Coka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        builder: (context, child) {
          FCMService.updateContext(context);
          FCMService.updateRouter(router);
          return child!;
        },
      ),
    );
  }
}
