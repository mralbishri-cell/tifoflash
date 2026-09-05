import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/push_notification_service.dart';
import 'core/theme/tifo_theme.dart';
import 'features/stadium/presentation/main_navigation_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with actual project options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully');
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('[Firebase] Init warning/fallback: $e');
  }

  // Global Error Boundary — catch all unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[TifoFlash CRASH] Flutter Error: ${details.exceptionAsString()}');
    debugPrint('[TifoFlash CRASH] Stack: ${details.stack}');
  };

  // Catch async errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[TifoFlash CRASH] Platform Error: $error');
    debugPrint('[TifoFlash CRASH] Stack: $stack');
    return true; // Prevents app termination
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF090D16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ غير متوقع ⚠️',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode ? details.exceptionAsString() : 'يرجى إعادة تشغيل التطبيق',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: TifoFlashApp(),
    ),
  );
}

class TifoFlashApp extends StatelessWidget {
  const TifoFlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TifoFlash Stadium Companion',
      debugShowCheckedModeBanner: false,
      theme: TifoTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
