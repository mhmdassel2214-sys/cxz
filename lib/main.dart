import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'internet_checker.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

Future<void> setupNotifications() async {
  if (kIsWeb) return;

  try {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    await messaging.setAutoInitEnabled(true);
    await messaging.subscribeToTopic('all_users');

    final token = await messaging.getToken();
    debugPrint('FCM token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final imageUrl =
          notification?.android?.imageUrl ?? message.data['imageUrl'];

      if (notification != null) {
        await NotificationService.showRichNotification(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          imageUrl: imageUrl,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.messageId}');
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Opened from terminated: ${initialMessage.messageId}');
    }
  } catch (e) {
    debugPrint('Notifications setup error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  if (!kIsWeb) {
    await NotificationService.initialize();
  }

  runApp(const AsMoviesApp());
}

class AsMoviesApp extends StatefulWidget {
  const AsMoviesApp({super.key});

  @override
  State<AsMoviesApp> createState() => _AsMoviesAppState();
}

class _AsMoviesAppState extends State<AsMoviesApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      Future.microtask(setupNotifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AsMovies',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD5B13E),
          secondary: Color(0xFFE3BA4E),
          surface: Color(0xFF0B0E17),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF121722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const InternetChecker(
        child: SplashScreen(),
      ),
    );
  }
}
