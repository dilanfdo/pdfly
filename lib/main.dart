import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/consent_service.dart';
import 'services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ forces edge-to-edge on apps targeting SDK 35+; opting in
  // explicitly makes older Android versions behave the same way, so every
  // screen's inset handling (SafeArea) is exercised on all devices, not just 15+.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Gathers ad consent (EEA/UK, via Google's UMP) and initializes the Mobile
  // Ads SDK before any screen that might request an ad gets built.
  await ConsentService.instance.gatherConsentAndInitializeAds();
  await ThemeController.instance.load();
  runApp(const PdfToolkitApp());
}

class PdfToolkitApp extends StatelessWidget {
  const PdfToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PDFly',
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
